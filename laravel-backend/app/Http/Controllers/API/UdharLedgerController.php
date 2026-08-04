<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Transaction;
use App\Models\UdharCustomer;
use App\Models\UdharLedger;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

class UdharLedgerController extends Controller
{
    /**
     * Get transaction timeline and balance summaries for a specific customer.
     */
    public function show(Request $request, $customerId)
    {
        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;

        $customer = Customer::where('merchant_id', $merchantId)
            ->where('id', $customerId)
            ->first();

        if (!$customer) {
            return response()->json([
                'status' => 'error',
                'message' => 'Customer not found.'
            ], 404);
        }

        $transactions = Transaction::where('customer_id', $customerId)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($tx) {
                return [
                    'id' => $tx->id,
                    'amount' => (float)$tx->amount,
                    'type' => $tx->type, // given, received
                    'remarks' => $tx->remarks,
                    'created_at' => $tx->created_at->format('Y-m-d H:i:s'),
                    'due_date' => $tx->due_date ? $tx->due_date->format('Y-m-d') : null,
                ];
            });

        return response()->json([
            'status' => 'success',
            'data' => [
                'customer_name' => $customer->name,
                'outstanding_balance' => (float)$customer->outstanding_balance,
                'credit_limit' => (float)$customer->credit_limit,
                'transactions' => $transactions
            ]
        ]);
    }

    /**
     * Record a new Udhar (Credit) or Payment (Debit) transaction.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'customer_id' => 'nullable',
            'email_or_phone' => 'nullable|string',
            'amount' => 'required|numeric|min:0.01',
            'type' => 'required|in:given,received,credit,debit',
            'remarks' => 'nullable|string|max:500',
            'notes' => 'nullable|string|max:500',
            'due_date' => 'nullable|date',
            'payment_method' => 'nullable|in:cash,upi,bank_transfer,qr_code',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first()
            ], 422);
        }

        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;
        $identifier = trim((string) ($request->input('email_or_phone') ?? ''));
        $customerId = $request->input('customer_id');

        if (empty($customerId) && $identifier === '') {
            return response()->json([
                'status' => 'error',
                'message' => 'Customer identifier is required.'
            ], 422);
        }

        $customer = null;
        if (!empty($customerId)) {
            $customer = Customer::where('merchant_id', $merchantId)
                ->where('id', $customerId)
                ->first();
        }

        if (!$customer && $identifier !== '') {
            // Find customer by ID, email or phone
            $customer = Customer::where('merchant_id', $merchantId)
                ->where(function($query) use ($identifier) {
                    $query->where('id', $identifier)
                        ->orWhere('phone', $identifier)
                        ->orWhere('email', $identifier);
                })->first();
        }

        if (!$customer) {
            return response()->json([
                'status' => 'error',
                'message' => 'Customer account not found.'
            ], 404);
        }

        if ($this->supportsCustomerUserIdColumn() && empty($customer->customer_user_id)) {
            $linkedUserId = $this->resolveCustomerUserIdFromPhone($customer->phone);
            if (!empty($linkedUserId)) {
                $customer->customer_user_id = $linkedUserId;
                $customer->save();
            }
        }

        $amount = (float)$request->amount;
        $normalizedType = in_array($request->type, ['credit', 'given'], true)
            ? 'given'
            : 'received';

        // Enforce credit limit on credit entry
        if ($normalizedType == 'given') {
            $predictedBalance = $customer->outstanding_balance + $amount;
            if ($predictedBalance > $customer->credit_limit) {
                return response()->json([
                    'status' => 'error',
                    'message' => "Transaction declined. This exceeds the customer's credit limit of ₹" . number_format($customer->credit_limit, 2)
                ], 400);
            }
        }

        // DB Transaction to ensure atomic execution
        $transaction = DB::transaction(function() use ($customer, $merchantId, $amount, $normalizedType, $request) {
            // Update customer's outstanding balance
            if ($normalizedType == 'given') {
                $customer->increment('outstanding_balance', $amount);
            } else {
                $customer->decrement('outstanding_balance', $amount);
            }

            // Create ledger entry log
            $tx = Transaction::create([
                'merchant_id' => $merchantId,
                'customer_id' => $customer->id,
                'amount' => $amount,
                'type' => $normalizedType,
                'payment_method' => $request->input('payment_method', 'cash'),
                'remarks' => $request->input('remarks') ?? $request->input('notes'),
                'due_date' => $request->due_date,
                'status' => 'completed',
            ]);

            $customer->refresh();
            $this->syncToUdharMirror($customer, $tx);

            return $tx;
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Ledger transaction recorded successfully.',
            'data' => [
                'transaction_id' => $transaction->id,
                'outstanding_balance' => (float)$customer->fresh()->outstanding_balance
            ]
        ], 200);
    }

    private function resolveCustomerUserIdFromPhone(?string $phone): ?int
    {
        $rawPhone = trim((string) $phone);
        if ($rawPhone === '') {
            return null;
        }

        $digits = preg_replace('/[^0-9]/', '', $rawPhone);
        if (strlen($digits) > 10) {
            $digits = substr($digits, -10);
        }

        $query = User::query()->where('type', 'user');
        $query->where(function ($builder) use ($rawPhone, $digits) {
            $builder->where('phone', $rawPhone)
                ->orWhere('username', $rawPhone);

            if (!empty($digits)) {
                $builder->orWhere('phone', 'like', '%' . $digits)
                    ->orWhere('username', 'like', '%' . $digits);
            }
        });

        $matched = $query->first();
        return $matched ? (int) $matched->id : null;
    }

    private function supportsCustomerUserIdColumn(): bool
    {
        try {
            return Schema::hasColumn('customers', 'customer_user_id');
        } catch (\Throwable $e) {
            return false;
        }
    }

    private function syncToUdharMirror(Customer $customer, Transaction $transaction): void
    {
        if (!Schema::hasTable('udhar_customers') || !Schema::hasTable('udhar_ledgers')) {
            return;
        }

        $udharCustomer = UdharCustomer::where('merchant_id', $customer->merchant_id)
            ->where('phone', $customer->phone)
            ->first();

        $udharAttrs = [
            'name' => $customer->name,
            'email' => $customer->email,
            'credit_limit' => (float) $customer->credit_limit,
            'opening_balance' => (float) $customer->opening_balance,
            'outstanding_balance' => (float) $customer->outstanding_balance,
            'status' => 1,
        ];

        if ($this->supportsCustomerUserIdColumn() && !empty($customer->customer_user_id)) {
            $udharAttrs['customer_user_id'] = (int) $customer->customer_user_id;
        }

        if ($udharCustomer) {
            $udharCustomer->fill($udharAttrs);
            $udharCustomer->save();
        } else {
            $udharCustomer = UdharCustomer::create(array_merge($udharAttrs, [
                'merchant_id' => $customer->merchant_id,
                'phone' => $customer->phone,
            ]));
        }

        if (!$udharCustomer) {
            return;
        }

        UdharLedger::create([
            'customer_id' => $udharCustomer->id,
            'merchant_id' => $customer->merchant_id,
            'type' => $transaction->type === 'given' ? 'credit' : 'debit',
            'amount' => (float) $transaction->amount,
            'running_balance' => (float) $customer->outstanding_balance,
            'payment_method' => $this->mapPaymentMethodForUdharLedger($transaction->payment_method),
            'transaction_id' => $transaction->gateway_tx_id,
            'notes' => $transaction->remarks,
            'due_date' => $transaction->due_date,
            'created_by' => 'merchant',
            'verification_status' => $transaction->verification_status ?? 'unverified',
        ]);
    }

    private function mapPaymentMethodForUdharLedger(?string $method): string
    {
        $value = strtolower(trim((string) $method));
        if ($value === 'qr_code') {
            return 'upi';
        }
        if (in_array($value, ['cash', 'upi', 'bank_transfer'], true)) {
            return $value;
        }
        return 'cash';
    }

    /**
     * Build report summary, transaction list and outstanding customers.
     */
    public function reports(Request $request)
    {
        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;
        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');

        $transactionsQuery = Transaction::with('customer')
            ->where('merchant_id', $merchantId)
            ->orderBy('created_at', 'desc');

        if ($startDate) {
            $transactionsQuery->whereDate('created_at', '>=', $startDate);
        }
        if ($endDate) {
            $transactionsQuery->whereDate('created_at', '<=', $endDate);
        }

        $transactions = $transactionsQuery->get();

        $reportRows = $transactions->map(function ($tx) {
            return [
                'id' => $tx->id,
                'customer_id' => $tx->customer_id,
                'customer_name' => optional($tx->customer)->name,
                'type' => $tx->type,
                'amount' => (float) $tx->amount,
                'payment_method' => $tx->payment_method,
                'remarks' => $tx->remarks,
                'due_date' => optional($tx->due_date)->format('Y-m-d'),
                'created_at' => optional($tx->created_at)->format('Y-m-d H:i:s'),
            ];
        })->values();

        $outstandingCustomers = Customer::where('merchant_id', $merchantId)
            ->where('outstanding_balance', '>', 0)
            ->orderByDesc('outstanding_balance')
            ->get([
                'id',
                'name',
                'phone',
                'email',
                'outstanding_balance',
                'credit_limit',
            ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Udhar reports generated successfully.',
            'data' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
                'total_credit_given' => (float) $transactions->where('type', 'given')->sum('amount'),
                'total_debit_received' => (float) $transactions->where('type', 'received')->sum('amount'),
                'outstanding_customers' => $outstandingCustomers,
                'transactions' => $reportRows,
            ],
        ]);
    }
}
