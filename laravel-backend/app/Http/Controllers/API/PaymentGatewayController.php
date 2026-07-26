<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PaymentGatewayController extends Controller
{
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
