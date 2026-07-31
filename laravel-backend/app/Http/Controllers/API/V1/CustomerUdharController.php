<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\UdharCustomer;
use App\Models\UdharLedger;
use App\Traits\ApiValidation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class CustomerUdharController extends Controller
{
    use ApiValidation;

    /**
     * Get all active merchant ledgers linked to this customer account.
     */
    public function merchantsList()
    {
        try {
            $user = Auth::user();
            $userId = $user ? $user->id : Auth::id();
            $userPhone = $user ? ($user->phone ?? $user->username ?? '') : '';
            $cleanPhone = preg_replace('/[^0-9]/', '', $userPhone);
            if (strlen($cleanPhone) > 10) {
                $cleanPhone = substr($cleanPhone, -10);
            }

            // AUTO-LINK: Link any UdharCustomer with matching phone where customer_user_id is NULL
            if (!empty($cleanPhone)) {
                UdharCustomer::whereNull('customer_user_id')
                    ->where(function($q) use ($userPhone, $cleanPhone) {
                        $q->where('phone', $userPhone)
                          ->orWhere('phone', 'like', '%' . $cleanPhone);
                    })
                    ->update(['customer_user_id' => $userId]);
            }

            // Fetch all udhar ledger nodes where customer_user_id or phone matches
            $ledgers = UdharCustomer::with('merchant')
                ->where(function($q) use ($userId, $userPhone, $cleanPhone) {
                    $q->where('customer_user_id', $userId);
                    if (!empty($cleanPhone)) {
                        $q->orWhere('phone', $userPhone)
                          ->orWhere('phone', 'like', '%' . $cleanPhone);
                    }
                })
                ->where('status', 1)
                ->get()
                ->map(function ($cust) {
                    return [
                        'id' => $cust->id,
                        'merchant_id' => $cust->merchant_id,
                        'shop_name' => $cust->merchant->shop_name ?? ($cust->merchant->firstname . ' ' . $cust->merchant->lastname),
                        'merchant_username' => $cust->merchant->username,
                        'outstanding_balance' => (float)$cust->outstanding_balance,
                        'credit_limit' => (float)$cust->credit_limit,
                        'due_date' => $cust->due_date ? $cust->due_date->format('Y-m-d') : null,
                        'updated_at' => $cust->updated_at->toDateTimeString(),
                    ];
                });

            return response()->json([
                'status' => 'success',
                'message' => 'Customer ledgers retrieved successfully',
                'data' => $ledgers
            ], 200);

        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()), 500);
        }
    }

    /**
     * Get transaction timeline details for a specific merchant.
     */
    public function ledgerList($merchantId)
    {
        try {
            $user = Auth::user();
            $userId = $user ? $user->id : Auth::id();
            $userPhone = $user ? ($user->phone ?? $user->username ?? '') : '';
            $cleanPhone = preg_replace('/[^0-9]/', '', $userPhone);
            if (strlen($cleanPhone) > 10) {
                $cleanPhone = substr($cleanPhone, -10);
            }

            // Find the specific customer record mapping the user to this merchant
            $customer = UdharCustomer::where('merchant_id', $merchantId)
                ->where(function($q) use ($userId, $userPhone, $cleanPhone) {
                    $q->where('customer_user_id', $userId);
                    if (!empty($cleanPhone)) {
                        $q->orWhere('phone', $userPhone)
                          ->orWhere('phone', 'like', '%' . $cleanPhone);
                    }
                })
                ->first();

            if (!$customer) {
                return response()->json($this->withErrors('No ledger account found with this merchant.'), 404);
            }

            if ($customer->customer_user_id != $userId) {
                $customer->customer_user_id = $userId;
                $customer->save();
            }

            $ledgers = UdharLedger::where('customer_id', $customer->id)
                ->orderBy('created_at', 'desc')
                ->paginate(20)
                ->through(function ($tx) {
                    return [
                        'id' => $tx->id,
                        'sync_id' => $tx->sync_id,
                        'type' => $tx->type, // credit (given/debt), debit (received/paid)
                        'amount' => (float)$tx->amount,
                        'running_balance' => (float)$tx->running_balance,
                        'payment_method' => $tx->payment_method,
                        'transaction_id' => $tx->transaction_id,
                        'notes' => $tx->notes,
                        'due_date' => $tx->due_date ? $tx->due_date->format('Y-m-d') : null,
                        'created_by' => $tx->created_by,
                        'verification_status' => $tx->verification_status,
                        'created_at' => $tx->created_at->toDateTimeString(),
                    ];
                });

            return response()->json([
                'status' => 'success',
                'data' => [
                    'merchant' => [
                        'id' => $customer->merchant_id,
                        'shop_name' => $customer->merchant->shop_name ?? ($customer->merchant->firstname . ' ' . $customer->merchant->lastname),
                        'phone' => $customer->merchant->phone,
                        'email' => $customer->merchant->email,
                    ],
                    'outstanding_balance' => (float)$customer->outstanding_balance,
                    'credit_limit' => (float)$customer->credit_limit,
                    'due_date' => $customer->due_date ? $customer->due_date->format('Y-m-d') : null,
                    'ledgers' => $ledgers
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()), 500);
        }
    }

    /**
     * Approve or dispute a ledger entry.
     */
    public function verifyLedgerEntry(Request $request, $ledgerId)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:verified,disputed',
            'notes' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json($this->withErrors(collect($validator->errors())->collapse()->first()), 422);
        }

        try {
            $userId = Auth::id();

            // Find transaction and make sure it belongs to a customer mapped to the authenticated user
            $ledger = UdharLedger::findOrFail($ledgerId);
            $customer = $ledger->customer;

            if ($customer->customer_user_id !== $userId) {
                return response()->json($this->withErrors('Unauthorized transaction access.'), 403);
            }

            $ledger->verification_status = $request->status;
            if ($request->status === 'disputed' && !empty($request->notes)) {
                $ledger->notes = $ledger->notes . " [Customer Dispute: " . $request->notes . "]";
            }
            $ledger->save();

            // Trigger stubs for real-time socket events or Push alerts back to the merchant if disputed
            if ($request->status === 'disputed') {
                // Future: event(new UdharDisputed($ledger));
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Transaction status updated successfully',
                'data' => $ledger
            ], 200);

        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()), 500);
        }
    }
}
