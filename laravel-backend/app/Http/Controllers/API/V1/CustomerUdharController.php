<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

class CustomerUdharController extends Controller
{
    /**
     * Get all merchant ledgers linked to the authenticated customer account.
     */
    public function merchantsList()
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json($this->errorResponse('Unauthorized'), 401);
            }

            $this->autoLinkCustomersToUser($user->id, $user->phone ?? $user->username ?? '');
            $supportsLink = $this->supportsCustomerUserIdColumn();

            $customers = Customer::with('merchant')
                ->where(function ($query) use ($user, $supportsLink) {
                    if ($supportsLink) {
                        $query->where('customer_user_id', $user->id);
                    }

                    $query->orWhere(function ($phoneQuery) use ($user) {
                            $rawPhone = trim((string) ($user->phone ?? $user->username ?? ''));
                            $digits = $this->lastTenDigits($rawPhone);
                            if ($rawPhone !== '') {
                                $phoneQuery->where('phone', $rawPhone);
                            }
                            if ($digits !== '') {
                                $phoneQuery->orWhere('phone', 'like', '%' . $digits);
                            }
                        });
                })
                ->orderByDesc('updated_at')
                ->get();

            $data = $customers->map(function (Customer $customer) {
                $merchantName = trim((string) (($customer->merchant->firstname ?? '') . ' ' . ($customer->merchant->lastname ?? '')));
                if ($merchantName === '') {
                    $merchantName = $customer->merchant->username ?? 'Merchant';
                }

                return [
                    'id' => $customer->id,
                    'merchant_id' => $customer->merchant_id,
                    'shop_name' => $customer->merchant->shop_name ?? $merchantName,
                    'merchant_username' => $customer->merchant->username ?? null,
                    'outstanding_balance' => (float) $customer->outstanding_balance,
                    'credit_limit' => (float) $customer->credit_limit,
                    'due_date' => null,
                    'updated_at' => optional($customer->updated_at)->toDateTimeString(),
                ];
            })->values();

            return response()->json([
                'status' => 'success',
                'message' => 'Customer ledgers retrieved successfully',
                'data' => $data,
            ], 200);
        } catch (\Exception $e) {
            return response()->json($this->errorResponse($e->getMessage()), 500);
        }
    }

    /**
     * Get transaction timeline details for a specific merchant.
     */
    public function ledgerList($merchantId)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json($this->errorResponse('Unauthorized'), 401);
            }

            $this->autoLinkCustomersToUser($user->id, $user->phone ?? $user->username ?? '');
            $supportsLink = $this->supportsCustomerUserIdColumn();

            $customer = Customer::with('merchant')
                ->where('merchant_id', $merchantId)
                ->where(function ($query) use ($user, $supportsLink) {
                    if ($supportsLink) {
                        $query->where('customer_user_id', $user->id);
                    }

                    $query->orWhere(function ($phoneQuery) use ($user) {
                            $rawPhone = trim((string) ($user->phone ?? $user->username ?? ''));
                            $digits = $this->lastTenDigits($rawPhone);
                            if ($rawPhone !== '') {
                                $phoneQuery->where('phone', $rawPhone);
                            }
                            if ($digits !== '') {
                                $phoneQuery->orWhere('phone', 'like', '%' . $digits);
                            }
                        });
                })
                ->first();

            if (!$customer) {
                return response()->json($this->errorResponse('No ledger account found with this merchant.'), 404);
            }

            if ($supportsLink && (int) ($customer->customer_user_id ?? 0) !== (int) $user->id) {
                $customer->customer_user_id = $user->id;
                $customer->save();
            }

            $ledgers = Transaction::where('customer_id', $customer->id)
                ->orderBy('created_at', 'desc')
                ->paginate(20)
                ->through(function (Transaction $tx) {
                    $type = $tx->type === 'given' ? 'credit' : 'debit';

                    return [
                        'id' => $tx->id,
                        'sync_id' => $tx->uuid,
                        'type' => $type,
                        'raw_type' => $tx->type,
                        'amount' => (float) $tx->amount,
                        'running_balance' => null,
                        'payment_method' => $tx->payment_method,
                        'transaction_id' => $tx->gateway_tx_id,
                        'notes' => $tx->remarks,
                        'due_date' => optional($tx->due_date)->format('Y-m-d'),
                        'created_by' => $tx->created_by ?? 'merchant',
                        'verification_status' => $tx->verification_status ?? 'unverified',
                        'created_at' => optional($tx->created_at)->toDateTimeString(),
                    ];
                });

            $merchantName = trim((string) (($customer->merchant->firstname ?? '') . ' ' . ($customer->merchant->lastname ?? '')));
            if ($merchantName === '') {
                $merchantName = $customer->merchant->username ?? 'Merchant';
            }

            return response()->json([
                'status' => 'success',
                'data' => [
                    'merchant' => [
                        'id' => $customer->merchant_id,
                        'shop_name' => $customer->merchant->shop_name ?? $merchantName,
                        'phone' => $customer->merchant->phone ?? null,
                        'email' => $customer->merchant->email ?? null,
                    ],
                    'outstanding_balance' => (float) $customer->outstanding_balance,
                    'credit_limit' => (float) $customer->credit_limit,
                    'due_date' => null,
                    'ledgers' => $ledgers,
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json($this->errorResponse($e->getMessage()), 500);
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
            return response()->json($this->errorResponse($validator->errors()->first()), 422);
        }

        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json($this->errorResponse('Unauthorized'), 401);
            }

            $ledger = Transaction::with('customer')->findOrFail($ledgerId);
            $customer = $ledger->customer;

            if (!$customer) {
                return response()->json($this->errorResponse('Unauthorized transaction access.'), 403);
            }

            if ($this->supportsCustomerUserIdColumn()) {
                if ((int) ($customer->customer_user_id ?? 0) !== (int) $user->id) {
                    return response()->json($this->errorResponse('Unauthorized transaction access.'), 403);
                }
            } else {
                $rawPhone = trim((string) ($user->phone ?? $user->username ?? ''));
                $digits = $this->lastTenDigits($rawPhone);
                $custDigits = $this->lastTenDigits((string) ($customer->phone ?? ''));
                if ($rawPhone === '' || ($rawPhone !== (string) ($customer->phone ?? '') && $digits !== $custDigits)) {
                    return response()->json($this->errorResponse('Unauthorized transaction access.'), 403);
                }
            }

            $ledger->verification_status = $request->input('status');
            if ($request->input('status') === 'disputed' && trim((string) $request->input('notes')) !== '') {
                $existingRemarks = trim((string) ($ledger->remarks ?? ''));
                $suffix = '[Customer Dispute: ' . trim((string) $request->input('notes')) . ']';
                $ledger->remarks = $existingRemarks === '' ? $suffix : ($existingRemarks . ' ' . $suffix);
            }
            $ledger->save();

            return response()->json([
                'status' => 'success',
                'message' => 'Transaction status updated successfully',
                'data' => $ledger,
            ], 200);
        } catch (\Exception $e) {
            return response()->json($this->errorResponse($e->getMessage()), 500);
        }
    }

    private function autoLinkCustomersToUser(int $userId, string $userPhone): void
    {
        if (!$this->supportsCustomerUserIdColumn()) {
            return;
        }

        $rawPhone = trim($userPhone);
        if ($rawPhone === '') {
            return;
        }

        $digits = $this->lastTenDigits($rawPhone);

        Customer::whereNull('customer_user_id')
            ->where(function ($query) use ($rawPhone, $digits) {
                $query->where('phone', $rawPhone);
                if ($digits !== '') {
                    $query->orWhere('phone', 'like', '%' . $digits);
                }
            })
            ->update(['customer_user_id' => $userId]);
    }

    private function supportsCustomerUserIdColumn(): bool
    {
        try {
            return Schema::hasColumn('customers', 'customer_user_id');
        } catch (\Throwable $e) {
            return false;
        }
    }

    private function lastTenDigits(string $value): string
    {
        $digits = preg_replace('/[^0-9]/', '', $value);
        if (strlen($digits) > 10) {
            return substr($digits, -10);
        }
        return $digits;
    }

    private function errorResponse(string $message): array
    {
        return [
            'status' => 'error',
            'message' => $message,
        ];
    }
}
