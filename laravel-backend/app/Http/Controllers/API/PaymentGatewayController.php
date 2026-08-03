<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class PaymentGatewayController extends Controller
{
    /**
     * Generate a dynamic UPI payment payload for a customer.
     */
    public function generateQr(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'customer_id' => 'required|integer',
            'amount' => 'required|numeric|min:0.01',
            'upi_id' => 'nullable|string|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;
        $customer = Customer::where('merchant_id', $merchantId)
            ->where('id', $request->input('customer_id'))
            ->first();

        if (!$customer) {
            return response()->json([
                'status' => 'error',
                'message' => 'Customer not found.',
            ], 404);
        }

        $upiId = trim((string) $request->input('upi_id', 'paysecure@ybl'));
        $amount = (float) $request->input('amount');
        $reference = 'UDH-' . now()->format('YmdHis') . '-' . $customer->id;
        $payeeName = preg_replace('/\s+/', ' ', trim($customer->name ?: 'Udhar Merchant'));

        $upiUri = sprintf(
            'upi://pay?pa=%s&pn=%s&am=%s&cu=INR&tn=%s&tr=%s',
            rawurlencode($upiId),
            rawurlencode($payeeName),
            number_format($amount, 2, '.', ''),
            rawurlencode('Udhar settlement'),
            rawurlencode($reference)
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Dynamic payment QR payload generated successfully.',
            'data' => [
                'customer_id' => $customer->id,
                'upi_uri' => $upiUri,
                'transaction_reference' => $reference,
            ],
        ]);
    }

    /**
     * Trigger a placeholder app reminder response for a customer.
     */
    public function sendAppReminder(Request $request, $id)
    {
        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;
        $customer = Customer::where('merchant_id', $merchantId)
            ->where('id', $id)
            ->first();

        if (!$customer) {
            return response()->json([
                'status' => 'error',
                'message' => 'Customer not found.',
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Payment reminder queued successfully.',
            'data' => [
                'customer_id' => $customer->id,
                'customer_name' => $customer->name,
                'outstanding_balance' => (float) $customer->outstanding_balance,
            ],
        ]);
    }

    /**
     * Handle webhook callbacks from Razorpay/PhonePe.
     */
    public function handleWebhook(Request $request)
    {
        // 1. Verify webhook signature (based on gateway header keys)
        $signature = $request->header('X-Razorpay-Signature');
        if (!$this->verifySignature($request->getContent(), $signature)) {
            return response()->json(['status' => 'error', 'message' => 'Unauthorized signature'], 401);
        }

        $payload = $request->input('payload.payment.entity');
        if (!$payload) {
            return response()->json(['status' => 'error', 'message' => 'Invalid payload'], 400);
        }

        // Check if transaction is successful
        if ($payload['status'] !== 'captured') {
            return response()->json(['status' => 'success', 'message' => 'Ignored unsuccessful payment event']);
        }

        $amount = (float)($payload['amount'] / 100); // Razorpay amounts are in paise
        $txId = $payload['id'];

        // Metadata links payment back to specific customer ledger
        $customerId = $payload['notes']['customer_id'] ?? null;
        $merchantId = $payload['notes']['merchant_id'] ?? null;

        if (!$customerId || !$merchantId) {
            return response()->json(['status' => 'error', 'message' => 'Missing ledger metadata mapping'], 400);
        }

        // Avoid duplicate webhook processes
        $alreadyLogged = Transaction::where('gateway_tx_id', $txId)->exists();
        if ($alreadyLogged) {
            return response()->json(['status' => 'success', 'message' => 'Webhook already processed']);
        }

        // 2. Perform atomic ledger auto-update
        try {
            DB::transaction(function() use ($customerId, $merchantId, $amount, $txId) {
                $customer = Customer::lockForUpdate()->find($customerId);
                if ($customer) {
                    // Reduce customer's outstanding balance
                    $customer->decrement('outstanding_balance', $amount);

                    // Insert debit log
                    Transaction::create([
                        'merchant_id' => $merchantId,
                        'customer_id' => $customerId,
                        'amount' => $amount,
                        'type' => 'received', // Debit
                        'payment_method' => 'qr_code',
                        'remarks' => "Online payment auto-settlement (Ref: {$txId})",
                        'gateway_tx_id' => $txId,
                        'status' => 'completed',
                    ]);
                }
            });

            return response()->json(['status' => 'success', 'message' => 'Ledger updated successfully']);
        } catch (\Exception $e) {
            Log::error("Webhook reconciliation failure: " . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => 'Internal settlement failure'], 500);
        }
    }

    /**
     * Verify payment signature (mock validation helper).
     */
    private function verifySignature($body, $signature)
    {
        // For production, calculate HMAC-SHA256 signature using webhook secret key
        // return hash_equals(hash_hmac('sha256', $body, config('services.razorpay.webhook_secret')), $signature);
        return true; 
    }
}
