<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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
            'email_or_phone' => 'required|string',
            'amount' => 'required|numeric|min:0.01',
            'type' => 'required|in:given,received',
            'remarks' => 'nullable|string|max:500',
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
        $identifier = $request->email_or_phone;

        // Find customer by ID, email or phone
        $customer = Customer::where('merchant_id', $merchantId)
            ->where(function($query) use ($identifier) {
                $query->where('id', $identifier)
                      ->orWhere('phone', $identifier)
                      ->orWhere('email', $identifier);
            })->first();

        if (!$customer) {
            return response()->json([
                'status' => 'error',
                'message' => 'Customer account not found.'
            ], 404);
        }

        $amount = (float)$request->amount;
        $type = $request->type; // given (credit) or received (debit)

        // Enforce credit limit on credit entry
        if ($type == 'given') {
            $predictedBalance = $customer->outstanding_balance + $amount;
            if ($predictedBalance > $customer->credit_limit) {
                return response()->json([
                    'status' => 'error',
                    'message' => "Transaction declined. This exceeds the customer's credit limit of ₹" . number_format($customer->credit_limit, 2)
                ], 400);
            }
        }

        // DB Transaction to ensure atomic execution
        $transaction = DB::transaction(function() use ($customer, $merchantId, $amount, $type, $request) {
            // Update customer's outstanding balance
            if ($type == 'given') {
                $customer->increment('outstanding_balance', $amount);
            } else {
                $customer->decrement('outstanding_balance', $amount);
            }

            // Create ledger entry log
            return Transaction::create([
                'merchant_id' => $merchantId,
                'customer_id' => $customer->id,
                'amount' => $amount,
                'type' => $type,
                'payment_method' => $request->input('payment_method', 'cash'),
                'remarks' => $request->remarks,
                'due_date' => $request->due_date,
                'status' => 'completed',
            ]);
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
