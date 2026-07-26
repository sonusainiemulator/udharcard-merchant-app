<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class SyncController extends Controller
{
    /**
     * Pull updates from the server since the last sync time.
     */
    public function pull(Request $request)
    {
        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;
        $lastSyncTime = $request->query('last_sync_time');

        $now = Carbon::now()->format('Y-m-d H:i:s');

        $customersQuery = Customer::where('merchant_id', $merchantId);
        $transactionsQuery = Transaction::where('merchant_id', $merchantId);

        if ($lastSyncTime) {
            try {
                $lastSync = Carbon::parse($lastSyncTime);
                $customersQuery->where('updated_at', '>', $lastSync);
                $transactionsQuery->where('updated_at', '>', $lastSync);
            } catch (\Exception $e) {
                // Keep default query if parsing fails
            }
        }

        $customers = $customersQuery->get()->map(function ($cust) {
            return [
                'id' => $cust->id,
                'merchant_id' => $cust->merchant_id,
                'customer_user_id' => $cust->customer_user_id,
                'name' => $cust->name,
                'phone' => $cust->phone,
                'email' => $cust->email,
                'credit_limit' => (float)$cust->credit_limit,
                'outstanding_balance' => (float)$cust->outstanding_balance,
                'opening_balance' => (float)$cust->opening_balance,
                'created_at' => $cust->created_at->format('Y-m-d H:i:s'),
                'updated_at' => $cust->updated_at->format('Y-m-d H:i:s'),
            ];
        });

        $transactions = $transactionsQuery->get()->map(function ($tx) {
            return [
                'id' => $tx->id,
                'uuid' => $tx->uuid,
                'customer_id' => $tx->customer_id,
                'merchant_id' => $tx->merchant_id,
                'amount' => (float)$tx->amount,
                'type' => $tx->type,
                'payment_method' => $tx->payment_method,
                'remarks' => $tx->remarks,
                'due_date' => $tx->due_date ? $tx->due_date->format('Y-m-d') : null,
                'gateway_tx_id' => $tx->gateway_tx_id,
                'status' => $tx->status,
                'created_by' => $tx->created_by,
                'verification_status' => $tx->verification_status,
                'created_at' => $tx->created_at->format('Y-m-d H:i:s'),
                'updated_at' => $tx->updated_at->format('Y-m-d H:i:s'),
            ];
        });

        return response()->json([
            'status' => 'success',
            'data' => [
                'last_sync_time' => $now,
                'customers' => $customers,
                'ledgers' => $transactions,
            ]
        ], 200);
    }

    /**
     * Push offline changes to the server.
     */
    public function push(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'customers' => 'nullable|array',
            'customers.*.local_uuid' => 'required|string',
            'customers.*.name' => 'required|string|max:255',
            'customers.*.phone' => 'required|string|max:15',
            'customers.*.email' => 'nullable|email|max:255',
            'customers.*.credit_limit' => 'nullable|numeric|min:0',
            'customers.*.opening_balance' => 'nullable|numeric',
            
            'ledgers' => 'nullable|array',
            'ledgers.*.uuid' => 'required|uuid',
            'ledgers.*.customer_id' => 'nullable|integer',
            'ledgers.*.customer_local_uuid' => 'nullable|string',
            'ledgers.*.type' => 'required|in:given,received',
            'ledgers.*.amount' => 'required|numeric|min:0.01',
            'ledgers.*.payment_method' => 'nullable|in:cash,upi,bank_transfer,qr_code',
            'ledgers.*.remarks' => 'nullable|string|max:500',
            'ledgers.*.due_date' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first()
            ], 422);
        }

        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;
        $syncResults = [
            'customers' => [],
            'ledgers' => []
        ];

        try {
            DB::transaction(function () use ($request, $merchantId, &$syncResults) {
                $customerUuidMap = []; // Maps local_uuid -> server customer_id

                // 1. Process pushed customers
                $pushedCustomers = $request->input('customers', []);
                foreach ($pushedCustomers as $custData) {
                    $localUuid = $custData['local_uuid'];

                    // Check if customer with this phone number already exists
                    $existing = Customer::where('merchant_id', $merchantId)
                        ->where('phone', $custData['phone'])
                        ->first();

                    if ($existing) {
                        $customerUuidMap[$localUuid] = $existing->id;
                        $syncResults['customers'][] = [
                            'local_uuid' => $localUuid,
                            'server_id' => $existing->id,
                            'status' => 'synced_existing',
                            'customer' => [
                                'id' => $existing->id,
                                'name' => $existing->name,
                                'outstanding_balance' => (float)$existing->outstanding_balance,
                            ]
                        ];
                        continue;
                    }

                    // Look up if a global customer account (user) exists for this phone number
                    // (Stub: In real app, we check against `users` table where role = customer)
                    $customerUserId = DB::table('users')
                        ->where('phone', $custData['phone'])
                        ->value('id');

                    // Create new customer
                    $newCust = Customer::create([
                        'merchant_id' => $merchantId,
                        'customer_user_id' => $customerUserId,
                        'name' => $custData['name'],
                        'phone' => $custData['phone'],
                        'email' => $custData['email'] ?? null,
                        'credit_limit' => $custData['credit_limit'] ?? 5000.00,
                        'opening_balance' => $custData['opening_balance'] ?? 0.00,
                        'outstanding_balance' => $custData['opening_balance'] ?? 0.00,
                    ]);

                    $customerUuidMap[$localUuid] = $newCust->id;
                    $syncResults['customers'][] = [
                        'local_uuid' => $localUuid,
                        'server_id' => $newCust->id,
                        'status' => 'synced_new',
                        'customer' => [
                            'id' => $newCust->id,
                            'name' => $newCust->name,
                            'outstanding_balance' => (float)$newCust->outstanding_balance,
                        ]
                    ];
                }

                // 2. Process pushed transactions (ledgers)
                $pushedLedgers = $request->input('ledgers', []);
                foreach ($pushedLedgers as $ledgerData) {
                    $txnUuid = $ledgerData['uuid'];

                    // Check for duplicate transaction (idempotency check)
                    $existingTxn = Transaction::where('uuid', $txnUuid)->first();
                    if ($existingTxn) {
                        $syncResults['ledgers'][] = [
                            'uuid' => $txnUuid,
                            'server_id' => $existingTxn->id,
                            'status' => 'duplicate',
                            'ledger' => [
                                'id' => $existingTxn->id,
                                'customer_id' => $existingTxn->customer_id,
                                'type' => $existingTxn->type,
                                'amount' => (float)$existingTxn->amount,
                            ]
                        ];
                        continue;
                    }

                    // Resolve Customer ID
                    $customerId = null;
                    if (!empty($ledgerData['customer_id'])) {
                        $customerId = $ledgerData['customer_id'];
                    } elseif (!empty($ledgerData['customer_local_uuid'])) {
                        $customerId = $customerUuidMap[$ledgerData['customer_local_uuid']] ?? null;
                    }

                    if (!$customerId) {
                        // Customer reference missing, report error for this item
                        $syncResults['ledgers'][] = [
                            'uuid' => $txnUuid,
                            'status' => 'error',
                            'message' => 'Customer could not be resolved.'
                        ];
                        continue;
                    }

                    $customer = Customer::lockForUpdate()->find($customerId);
                    if (!$customer) {
                        $syncResults['ledgers'][] = [
                            'uuid' => $txnUuid,
                            'status' => 'error',
                            'message' => 'Customer not found.'
                        ];
                        continue;
                    }

                    $amount = (float)$ledgerData['amount'];
                    $type = $ledgerData['type'];

                    // Update customer balance
                    if ($type == 'given') {
                        $customer->increment('outstanding_balance', $amount);
                    } else {
                        $customer->decrement('outstanding_balance', $amount);
                    }

                    // Create Transaction
                    $newTxn = Transaction::create([
                        'uuid' => $txnUuid,
                        'merchant_id' => $merchantId,
                        'customer_id' => $customerId,
                        'amount' => $amount,
                        'type' => $type,
                        'payment_method' => $ledgerData['payment_method'] ?? 'cash',
                        'remarks' => $ledgerData['remarks'] ?? null,
                        'due_date' => $ledgerData['due_date'] ?? null,
                        'status' => 'completed',
                        'created_by' => 'merchant',
                        'verification_status' => 'unverified',
                    ]);

                    $syncResults['ledgers'][] = [
                        'uuid' => $txnUuid,
                        'server_id' => $newTxn->id,
                        'status' => 'synced',
                        'ledger' => [
                            'id' => $newTxn->id,
                            'customer_id' => $customerId,
                            'type' => $type,
                            'amount' => $amount,
                            'running_balance' => (float)$customer->fresh()->outstanding_balance,
                        ]
                    ];
                }
            });

            return response()->json([
                'status' => 'success',
                'message' => 'Offline data synchronized successfully',
                'data' => $syncResults
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Synchronization failed: ' . $e->getMessage()
            ], 500);
        }
    }
}
