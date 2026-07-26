<?php

namespace Modules\Merchant\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UdharCustomer;
use App\Models\UdharLedger;
use App\Traits\ApiValidation;
use App\Traits\Notify;
use App\Events\UdharCustomerSynced;
use App\Events\UdharLedgerUpdated;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Http;
use Modules\Merchant\Services\MerchantContactService;

class UdharController extends Controller
{
    use ApiValidation, Notify;

    /**
     * Dashboard statistics for the merchant.
     */
    public function dashboard()
    {
        try {
            $merchantId = Auth::id();

            // Total Outstanding Udhar Given
            $totalUdharGiven = UdharCustomer::where('merchant_id', $merchantId)
                ->where('status', 1)
                ->sum('outstanding_balance');

            // Total Received (Sum of all Debit ledger entries)
            $totalAmountReceived = UdharLedger::where('merchant_id', $merchantId)
                ->where('type', 'debit')
                ->sum('amount');

            // Pending Collections (Outstanding balance > 0)
            $pendingCollection = UdharCustomer::where('merchant_id', $merchantId)
                ->where('outstanding_balance', '>', 0)
                ->sum('outstanding_balance');

            // Active Customers count
            $activeCustomers = UdharCustomer::where('merchant_id', $merchantId)
                ->where('status', 1)
                ->count();

            // Today's Transactions count
            $todayTransactionsCount = UdharLedger::where('merchant_id', $merchantId)
                ->whereDate('created_at', Carbon::today())
                ->count();

            // Today's Transactions list
            $todayTransactions = UdharLedger::with('customer')
                ->where('merchant_id', $merchantId)
                ->whereDate('created_at', Carbon::today())
                ->latest()
                ->limit(10)
                ->get();

            // Monthly stats for chart (Credit vs Debit for the last 6 months)
            $chartData = [];
            for ($i = 5; $i >= 0; $i--) {
                $month = Carbon::today()->subMonths($i);
                $monthName = $month->format('M Y');
                $startOfMonth = $month->copy()->startOfMonth();
                $endOfMonth = $month->copy()->endOfMonth();

                $credit = UdharLedger::where('merchant_id', $merchantId)
                    ->where('type', 'credit')
                    ->whereBetween('created_at', [$startOfMonth, $endOfMonth])
                    ->sum('amount');

                $debit = UdharLedger::where('merchant_id', $merchantId)
                    ->where('type', 'debit')
                    ->whereBetween('created_at', [$startOfMonth, $endOfMonth])
                    ->sum('amount');

                $chartData[] = [
                    'month' => $monthName,
                    'credit' => (float)$credit,
                    'debit' => (float)$debit,
                ];
            }

            $data = [
                'total_udhar_given' => (float)$totalUdharGiven,
                'total_amount_received' => (float)$totalAmountReceived,
                'pending_collection' => (float)$pendingCollection,
                'active_customers' => $activeCustomers,
                'today_transactions_count' => $todayTransactionsCount,
                'today_transactions' => $todayTransactions,
                'chart_data' => $chartData,
            ];

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * List all customers under the merchant.
     */
    public function customersList(Request $request)
    {
        try {
            $merchantId = Auth::id();
            $search = $request->search;

            $customers = UdharCustomer::where('merchant_id', $merchantId)
                ->when($search, function ($query) use ($search) {
                    $query->where(function($q) use ($search) {
                        $q->where('name', 'LIKE', "%{$search}%")
                          ->orWhere('phone', 'LIKE', "%{$search}%")
                          ->orWhere('email', 'LIKE', "%{$search}%");
                    });
                })
                ->orderBy('name', 'asc')
                ->paginate(15);

            return response()->json($this->withSuccess($customers));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Unified contact list for registered users and udhar customers.
     */
    public function contactsList(Request $request, MerchantContactService $contactService)
    {
        $validator = Validator::make($request->all(), [
            'search' => 'nullable|string|max:255',
            'balance_status' => 'nullable|in:all,positive_credit,negative_debit,zero_balance',
            'contact_type' => 'nullable|in:all,customer,user',
            'sort' => 'nullable|in:name,contact_identifier,contact_type,total_credit,total_debit,net_balance,last_activity_at',
            'direction' => 'nullable|in:asc,desc',
            'per_page' => 'nullable|integer|min:10|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json($this->withErrors(collect($validator->errors())->collapse()->first()), 422);
        }

        try {
            $contacts = $contactService->paginateContacts(Auth::id(), $validator->validated());

            return response()->json([
                'status' => 'success',
                'message' => 'Contact balances retrieved successfully',
                'data' => $contacts,
            ]);
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Add a new customer.
     */
    public function addCustomer(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:191',
            'phone' => 'required|string|max:20',
            'email' => 'nullable|email|max:191',
            'credit_limit' => 'nullable|numeric|min:0',
            'opening_balance' => 'nullable|numeric|min:0',
            'due_date' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json($this->withErrors(collect($validator->errors())->collapse()->first()));
        }

        DB::beginTransaction();
        try {
            $merchantId = Auth::id();

            // Find global customer user by phone
            $customerUser = \App\Models\User::where('phone', $request->phone)
                ->where('type', 'user')
                ->first();
            $customerUserId = $customerUser ? $customerUser->id : null;

            $customer = UdharCustomer::create([
                'merchant_id' => $merchantId,
                'customer_user_id' => $customerUserId,
                'name' => $request->name,
                'phone' => $request->phone,
                'email' => $request->email,
                'credit_limit' => $request->credit_limit ?? 0,
                'opening_balance' => $request->opening_balance ?? 0,
                'outstanding_balance' => $request->opening_balance ?? 0,
                'status' => 1,
                'due_date' => $request->due_date,
            ]);

            // If there's an opening balance, record it as a credit transaction in the ledger
            if ($customer->opening_balance > 0) {
                UdharLedger::create([
                    'customer_id' => $customer->id,
                    'merchant_id' => $merchantId,
                    'type' => 'credit',
                    'amount' => $customer->opening_balance,
                    'running_balance' => $customer->opening_balance,
                    'payment_method' => 'cash',
                    'notes' => 'Opening credit balance',
                    'due_date' => $request->due_date,
                ]);
            }

            DB::commit();
            return response()->json([
                'status' => 'success',
                'message' => 'Customer created successfully',
                'data' => $customer
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Update customer details.
     */
    public function updateCustomer(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:191',
            'phone' => 'required|string|max:20',
            'email' => 'nullable|email|max:191',
            'credit_limit' => 'nullable|numeric|min:0',
            'due_date' => 'nullable|date',
            'status' => 'required|in:0,1',
        ]);

        if ($validator->fails()) {
            return response()->json($this->withErrors(collect($validator->errors())->collapse()->first()));
        }

        try {
            $customer = UdharCustomer::where('merchant_id', Auth::id())->findOrFail($id);

            $customer->update([
                'name' => $request->name,
                'phone' => $request->phone,
                'email' => $request->email,
                'credit_limit' => $request->credit_limit ?? 0,
                'due_date' => $request->due_date,
                'status' => $request->status,
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Customer updated successfully',
                'data' => $customer
            ]);
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Upgrade customer credit limit from mobile app.
     */
    public function upgradeCustomerCreditLimit(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'credit_limit' => 'required|numeric|min:0',
            'notes' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json($this->withErrors(collect($validator->errors())->collapse()->first()));
        }

        try {
            $customer = UdharCustomer::where('merchant_id', Auth::id())->findOrFail($id);

            $oldLimit = (float) $customer->credit_limit;
            $newLimit = (float) $request->credit_limit;

            if ($newLimit <= $oldLimit) {
                return response()->json($this->withErrors('New credit limit must be greater than current credit limit.'));
            }

            if ($newLimit < (float) $customer->outstanding_balance) {
                return response()->json($this->withErrors('New credit limit cannot be less than outstanding balance.'));
            }

            $customer->credit_limit = $newLimit;
            $customer->save();

            return response()->json([
                'status' => 'success',
                'message' => 'Customer credit limit upgraded successfully',
                'data' => [
                    'customer_id' => $customer->id,
                    'old_credit_limit' => $oldLimit,
                    'new_credit_limit' => $newLimit,
                    'outstanding_balance' => (float) $customer->outstanding_balance,
                    'notes' => $request->notes,
                    'customer' => $customer,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Delete customer and their transaction history.
     */
    public function deleteCustomer($id)
    {
        try {
            $customer = UdharCustomer::where('merchant_id', Auth::id())->findOrFail($id);
            $customer->delete(); // This cascade deletes ledger entries due to DB constraint
            return response()->json([
                'status' => 'success',
                'message' => 'Customer deleted successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Get ledger transaction history for a specific customer.
     */
    public function ledgerList($customer_id)
    {
        try {
            $customer = UdharCustomer::where('merchant_id', Auth::id())->findOrFail($customer_id);
            $ledgers = UdharLedger::where('customer_id', $customer_id)
                ->latest()
                ->paginate(20);

            $data = [
                'customer' => $customer,
                'ledgers' => $ledgers
            ];

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Add a ledger entry (Credit or Debit).
     */
    public function addLedgerEntry(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'customer_id' => 'required|exists:udhar_customers,id',
            'type' => 'required|in:credit,debit',
            'amount' => 'required|numeric|min:0.01',
            'payment_method' => 'required|in:cash,upi,bank_transfer,gateway',
            'transaction_id' => 'nullable|string',
            'notes' => 'nullable|string',
            'due_date' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json($this->withErrors(collect($validator->errors())->collapse()->first()));
        }

        DB::beginTransaction();
        try {
            $merchantId = Auth::id();
            $customer = UdharCustomer::where('merchant_id', $merchantId)->findOrFail($request->customer_id);

            $amount = $request->amount;
            $newOutstanding = $customer->outstanding_balance;

            if ($request->type === 'credit') {
                // Verify credit limit if dynamic limit is set (>0)
                if ($customer->credit_limit > 0 && ($newOutstanding + $amount) > $customer->credit_limit) {
                    return response()->json($this->withErrors('Credit limit exceeded. Transaction denied.'));
                }
                $newOutstanding += $amount;
            } else {
                // Debit (payment received) decreases the outstanding balance
                $newOutstanding -= $amount;
            }

            // Create ledger entry
            $ledger = UdharLedger::create([
                'customer_id' => $customer->id,
                'merchant_id' => $merchantId,
                'type' => $request->type,
                'amount' => $amount,
                'running_balance' => $newOutstanding,
                'payment_method' => $request->payment_method,
                'transaction_id' => $request->transaction_id,
                'notes' => $request->notes,
                'due_date' => $request->due_date ?? $customer->due_date,
                'created_by' => 'merchant',
                'verification_status' => 'unverified',
            ]);

            // Update customer balance & due date
            $customer->outstanding_balance = $newOutstanding;
            if ($request->due_date) {
                $customer->due_date = $request->due_date;
            }
            $customer->save();

            DB::commit();
            return response()->json([
                'status' => 'success',
                'message' => 'Ledger transaction recorded successfully',
                'data' => $ledger
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Generate UPI payment URI & Base64 QR code for a customer.
     */
    public function generateQR(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'customer_id' => 'required|exists:udhar_customers,id',
            'amount' => 'nullable|numeric|min:0.01',
        ]);

        if ($validator->fails()) {
            return response()->json($this->withErrors(collect($validator->errors())->collapse()->first()));
        }

        try {
            $merchant = Auth::user();
            $customer = UdharCustomer::where('merchant_id', $merchant->id)->findOrFail($request->customer_id);

            // Fetch merchant UPI details (e.g. withdraw credentials or placeholder)
            $merchantUPI = $merchant->email . '@upi'; // Default fallback
            $merchantSettings = DB::table('merchant_settings')->where('merchant_id', $merchant->id)->first();
            if ($merchantSettings && !empty($merchantSettings->withdraw_information)) {
                $withdrawInfo = json_decode($merchantSettings->withdraw_information, true);
                if (isset($withdrawInfo['upi_id'])) {
                    $merchantUPI = $withdrawInfo['upi_id'];
                }
            }

            $amount = $request->amount ?? $customer->outstanding_balance;
            $txnId = 'UDHAR' . Carbon::now()->timestamp . 'C' . $customer->id;
            $merchantName = rawurlencode($merchant->firstname . ' ' . $merchant->lastname);
            $note = rawurlencode("Payment to UdharCard Merchant " . $merchant->username);

            // Construct UPI Scheme URI
            // format: upi://pay?pa=upi_address&pn=name&am=amount&tr=txnId&tn=note
            $upiUri = "upi://pay?pa={$merchantUPI}&pn={$merchantName}";
            if ($amount > 0) {
                $upiUri .= "&am=" . number_format($amount, 2, '.', '');
            }
            $upiUri .= "&tr={$txnId}&tn={$note}";

            // Generate Base64 encoded QR Code PNG
            // To ensure compatibility and avoid missing php extension problems,
            // we can safely generate inline svg or return the raw UPI uri.
            // Let's generate a clean base64 SVG QR code image.
            // Generate Base64 encoded QR Code SVG
            $qrResponse = Http::timeout(10)->get('https://quickchart.io/qr?text=' . urlencode($upiUri) . '&size=300&format=svg');
            $qrSvg = "data:image/svg+xml;base64," . base64_encode($qrResponse->body());

            $data = [
                'upi_uri' => $upiUri,
                'qr_code_svg' => $qrSvg,
                'transaction_reference' => $txnId,
                'amount' => (float)$amount,
                'customer_name' => $customer->name,
                'merchant_upi' => $merchantUPI,
            ];

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Send/Generate payment reminder text & WhatsApp launch links.
     */
    public function sendReminder($ledger_id)
    {
        try {
            $ledger = UdharLedger::with('customer')->where('merchant_id', Auth::id())->findOrFail($ledger_id);
            $customer = $ledger->customer;
            $merchant = Auth::user();

            if ($customer->outstanding_balance <= 0) {
                return response()->json($this->withErrors('This customer has no outstanding balance. No reminder needed.'));
            }

            $appName = basicControl()->site_title ?? 'UdharCard';
            $dueDateStr = $customer->due_date ? $customer->due_date->format('d-M-Y') : 'Soon';

            // Construct Reminder Message
            $message = "Dear {$customer->name}, this is a friendly reminder from {$merchant->firstname} (via {$appName}) that your outstanding balance of Rs. " . number_format($customer->outstanding_balance, 2) . " is due by {$dueDateStr}. Please pay using this link or scan and pay cash. Thank you!";

            // WhatsApp Direct Send URL API
            // Format: https://api.whatsapp.com/send?phone=country_phone&text=url_encoded_text
            $cleanPhone = preg_replace('/[^0-9]/', '', $customer->phone);
            // Prefix +91 if length is 10 (India context)
            if (strlen($cleanPhone) === 10) {
                $cleanPhone = '91' . $cleanPhone;
            }

            $whatsappUrl = "https://api.whatsapp.com/send?phone=" . $cleanPhone . "&text=" . urlencode($message);
            
            $data = [
                'message' => $message,
                'whatsapp_url' => $whatsappUrl,
                'phone' => $customer->phone,
                'outstanding_balance' => (float)$customer->outstanding_balance,
            ];

            // If Twilio SMS settings are enabled, we can also dispatch the message in the backend
            $basic = basicControl();
            if ($basic->sms_notification == 1 && !empty(config('sms_method'))) {
                try {
                    // Send using system notification helper
                    sendSms($customer->phone, $message);
                    $data['sms_status'] = 'Dispatched via system gateway';
                } catch (\Exception $smsEx) {
                    $data['sms_status'] = 'System gateway error: ' . $smsEx->getMessage();
                }
            } else {
                $data['sms_status'] = 'System gateway off (Manual Share/WhatsApp recommended)';
            }

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Send in-app push notification reminder to the customer.
     */
    public function sendAppReminder($customer_id)
    {
        try {
            $customer = UdharCustomer::where('merchant_id', Auth::id())->findOrFail($customer_id);
            $merchant = Auth::user();

            if ($customer->outstanding_balance <= 0) {
                return response()->json($this->withErrors('This customer has no outstanding balance. No reminder needed.'));
            }

            if (!$customer->customer_user_id) {
                return response()->json($this->withErrors('This customer is not linked to a User App account. Please remind them via WhatsApp.'));
            }

            $customerUser = \App\Models\User::find($customer->customer_user_id);
            if (!$customerUser) {
                return response()->json($this->withErrors('Linked user account not found.'));
            }

            $amountStr = number_format($customer->outstanding_balance, 2);
            $merchantName = $merchant->username ?? 'A Merchant';

            $this->userFirebasePushNotification(
                $customerUser,
                'udhar_payment_reminder',
                [
                    'merchant' => $merchantName,
                    'amount' => $amountStr
                ]
            );

            $this->userPushNotification(
                $customerUser,
                'udhar_payment_reminder',
                [
                    'merchant' => $merchantName,
                    'amount' => $amountStr
                ]
            );

            return response()->json($this->withSuccess('In-app payment reminder sent successfully.'));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Reports generation statistics (Daily, Monthly, Outstanding balances).
     */
    public function reports(Request $request)
    {
        try {
            $merchantId = Auth::id();
            $startDate = $request->start_date ? Carbon::parse($request->start_date)->startOfDay() : Carbon::now()->subMonth()->startOfDay();
            $endDate = $request->end_date ? Carbon::parse($request->end_date)->endOfDay() : Carbon::now()->endOfDay();

            // Total credit/debit transaction log in time frame
            $ledgers = UdharLedger::with('customer')
                ->where('merchant_id', $merchantId)
                ->whereBetween('created_at', [$startDate, $endDate])
                ->latest()
                ->get();

            // Summary
            $totalCreditGiven = $ledgers->where('type', 'credit')->sum('amount');
            $totalDebitReceived = $ledgers->where('type', 'debit')->sum('amount');

            // Top outstanding balance list
            $outstandingCustomers = UdharCustomer::where('merchant_id', $merchantId)
                ->where('outstanding_balance', '>', 0)
                ->orderBy('outstanding_balance', 'desc')
                ->limit(10)
                ->get();

            $data = [
                'start_date' => $startDate->toDateTimeString(),
                'end_date' => $endDate->toDateTimeString(),
                'total_credit_given' => (float)$totalCreditGiven,
                'total_debit_received' => (float)$totalDebitReceived,
                'outstanding_customers' => $outstandingCustomers,
                'transactions' => $ledgers,
            ];

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Delete a ledger transaction entry (recalculates running balance).
     */
    public function deleteLedgerEntry($id)
    {
        DB::beginTransaction();
        try {
            $ledger = UdharLedger::where('merchant_id', Auth::id())->findOrFail($id);
            $customerId = $ledger->customer_id;

            $ledger->delete();

            // Recalculate
            UdharLedger::recalculateLedger($customerId);

            DB::commit();
            return response()->json([
                'status' => 'success',
                'message' => 'Ledger transaction entry deleted successfully and balances updated.'
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Pull updates since the last sync time.
     */
    public function pullSync(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'last_sync_time' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json($this->withErrors(collect($validator->errors())->collapse()->first()), 422);
        }

        try {
            $merchantId = Auth::id();
            $lastSyncTime = $request->last_sync_time ? Carbon::parse($request->last_sync_time) : null;

            // Fetch active customers updated since last sync
            $customersQuery = UdharCustomer::where('merchant_id', $merchantId);
            if ($lastSyncTime) {
                $customersQuery->where('updated_at', '>=', $lastSyncTime);
            }
            $customers = $customersQuery->get();

            // Fetch active ledgers updated since last sync
            $ledgersQuery = UdharLedger::where('merchant_id', $merchantId);
            if ($lastSyncTime) {
                $ledgersQuery->where('updated_at', '>=', $lastSyncTime);
            }
            $ledgers = $ledgersQuery->get();

            // Provide lists of current valid IDs to allow deletion detection on the mobile client
            $allActiveCustomerIds = UdharCustomer::where('merchant_id', $merchantId)->pluck('id');
            $allActiveLedgerIds = UdharLedger::where('merchant_id', $merchantId)->pluck('id');

            return response()->json([
                'status' => 'success',
                'data' => [
                    'last_sync_time' => Carbon::now()->toDateTimeString(),
                    'customers' => $customers,
                    'ledgers' => $ledgers,
                    'active_customer_ids' => $allActiveCustomerIds,
                    'active_ledger_ids' => $allActiveLedgerIds,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    /**
     * Push offline created/modified data to the server.
     */
    public function pushSync(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'customers' => 'nullable|array',
            'customers.*.local_id' => 'required|string',
            'customers.*.name' => 'required|string|max:191',
            'customers.*.phone' => 'required|string|max:20',
            'customers.*.email' => 'nullable|email|max:191',
            'customers.*.credit_limit' => 'nullable|numeric|min:0',
            'customers.*.opening_balance' => 'nullable|numeric|min:0',
            'customers.*.due_date' => 'nullable|date',
            
            'ledgers' => 'nullable|array',
            'ledgers.*.local_id' => 'required|string',
            'ledgers.*.customer_id' => 'nullable|integer',
            'ledgers.*.customer_local_id' => 'nullable|string',
            'ledgers.*.type' => 'required|in:credit,debit',
            'ledgers.*.amount' => 'required|numeric|min:0.01',
            'ledgers.*.payment_method' => 'required|in:cash,upi,bank_transfer,gateway',
            'ledgers.*.transaction_id' => 'nullable|string',
            'ledgers.*.notes' => 'nullable|string',
            'ledgers.*.due_date' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json($this->withErrors(collect($validator->errors())->collapse()->first()), 422);
        }

        DB::beginTransaction();
        try {
            $merchantId = Auth::id();
            $customerMap = []; // Maps local_id -> server_id
            $syncedCustomers = [];
            $syncedLedgers = [];

            // 1. Process Offline Customers
            if ($request->has('customers')) {
                foreach ($request->customers as $custData) {
                    $localId = $custData['local_id'];
                    
                    // Find global customer user by phone
                    $customerUser = \App\Models\User::where('phone', $custData['phone'])
                        ->where('type', 'user')
                        ->first();
                    $customerUserId = $customerUser ? $customerUser->id : null;

                    // Create customer on server
                    $customer = UdharCustomer::create([
                        'merchant_id' => $merchantId,
                        'customer_user_id' => $customerUserId,
                        'name' => $custData['name'],
                        'phone' => $custData['phone'],
                        'email' => $custData['email'] ?? null,
                        'credit_limit' => $custData['credit_limit'] ?? 0,
                        'opening_balance' => $custData['opening_balance'] ?? 0,
                        'outstanding_balance' => $custData['opening_balance'] ?? 0,
                        'status' => 1,
                        'due_date' => $custData['due_date'] ?? null,
                    ]);

                    $customerMap[$localId] = $customer->id;

                    // If opening balance > 0, generate initial credit ledger entry
                    if ($customer->opening_balance > 0) {
                        UdharLedger::create([
                            'customer_id' => $customer->id,
                            'merchant_id' => $merchantId,
                            'type' => 'credit',
                            'amount' => $customer->opening_balance,
                            'running_balance' => $customer->opening_balance,
                            'payment_method' => 'cash',
                            'notes' => 'Opening credit balance',
                            'due_date' => $customer->due_date,
                        ]);
                    }

                    $syncedCustomers[] = [
                        'local_id' => $localId,
                        'server_id' => $customer->id,
                        'customer' => $customer
                    ];
                }
            }

            // 2. Process Offline Ledger Entries
            if ($request->has('ledgers')) {
                foreach ($request->ledgers as $ledgerData) {
                    $localId = $ledgerData['local_id'];
                    $customerId = $ledgerData['customer_id'] ?? null;
                    $customerLocalId = $ledgerData['customer_local_id'] ?? null;

                    // Resolve the actual database ID for the customer
                    if (empty($customerId) && !empty($customerLocalId)) {
                        $customerId = $customerMap[$customerLocalId] ?? null;
                    }

                    if (empty($customerId)) {
                        throw new \Exception("Unable to resolve customer ID for ledger item local_id: {$localId}");
                    }

                    $customer = UdharCustomer::where('merchant_id', $merchantId)->findOrFail($customerId);

                    $amount = $ledgerData['amount'];
                    $newOutstanding = $customer->outstanding_balance;

                    if ($ledgerData['type'] === 'credit') {
                        // Check limit if credit limit is active (>0)
                        if ($customer->credit_limit > 0 && ($newOutstanding + $amount) > $customer->credit_limit) {
                            throw new \Exception("Credit limit exceeded for customer {$customer->name}. Sync denied for transaction local_id {$localId}.");
                        }
                        $newOutstanding += $amount;
                    } else {
                        $newOutstanding -= $amount;
                    }

                    // Create ledger entry
                    $ledger = UdharLedger::create([
                        'customer_id' => $customer->id,
                        'merchant_id' => $merchantId,
                        'type' => $ledgerData['type'],
                        'amount' => $amount,
                        'running_balance' => $newOutstanding,
                        'payment_method' => $ledgerData['payment_method'],
                        'transaction_id' => $ledgerData['transaction_id'] ?? null,
                        'notes' => $ledgerData['notes'] ?? null,
                        'due_date' => $ledgerData['due_date'] ?? $customer->due_date,
                        'created_by' => 'merchant',
                        'verification_status' => 'unverified',
                    ]);

                    // Update customer balance & due date
                    $customer->outstanding_balance = $newOutstanding;
                    if (isset($ledgerData['due_date'])) {
                        $customer->due_date = $ledgerData['due_date'];
                    }
                    $customer->save();

                    $syncedLedgers[] = [
                        'local_id' => $localId,
                        'server_id' => $ledger->id,
                        'ledger' => $ledger
                    ];
                }
            }

            // Dispatch events after successful commit
            foreach ($syncedCustomers as $syncedCustomer) {
                event(new UdharCustomerSynced($syncedCustomer['customer']));
            }
            
            foreach ($syncedLedgers as $syncedLedger) {
                event(new UdharLedgerUpdated($syncedLedger['ledger']));
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Offline data synchronized successfully',
                'data' => [
                    'customers' => $syncedCustomers,
                    'ledgers' => $syncedLedgers
                ]
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json($this->withErrors($e->getMessage()), 400);
        }
    }
}
