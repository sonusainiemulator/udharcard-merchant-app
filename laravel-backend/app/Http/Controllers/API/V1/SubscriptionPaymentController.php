<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\MerchantSubscription;
use App\Models\SubscriptionPayment;
use App\Models\SubscriptionPlan;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SubscriptionPaymentController extends Controller
{
    /**
     * Razorpay webhook endpoint for subscription payment capture.
     */
    public function razorpayWebhook(Request $request)
    {
        $rawBody = $request->getContent();
        $signature = (string) $request->header('X-Razorpay-Signature', '');

        if (!$this->verifyWebhookSignature($rawBody, $signature)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid signature.',
            ], 401);
        }

        $event = $request->input('event');
        $payload = $request->input('payload.payment.entity');

        if (!$payload || empty($payload['notes'])) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid webhook payload.',
            ], 400);
        }

        $notes = $payload['notes'];
        $merchantId = isset($notes['merchant_id']) ? (int) $notes['merchant_id'] : null;
        $orderId = $payload['order_id'] ?? null;
        $paymentId = $payload['id'] ?? null;

        if (!$merchantId || !$orderId || !$paymentId) {
            return response()->json([
                'status' => 'error',
                'message' => 'Webhook metadata is incomplete.',
            ], 422);
        }

        if ($event !== 'payment.captured') {
            return response()->json([
                'status' => 'success',
                'message' => 'Event ignored.',
            ], 200);
        }

        $alreadyCaptured = SubscriptionPayment::where('external_payment_id', $paymentId)
            ->where('status', 'captured')
            ->exists();

        if ($alreadyCaptured) {
            return response()->json([
                'status' => 'success',
                'message' => 'Already processed.',
            ], 200);
        }

        $payment = SubscriptionPayment::where('merchant_id', $merchantId)
            ->where('external_order_id', $orderId)
            ->first();

        if (!$payment) {
            return response()->json([
                'status' => 'error',
                'message' => 'Subscription payment order not found.',
            ], 404);
        }

        try {
            DB::transaction(function () use ($payment, $merchantId, $paymentId, $signature, $request) {
                $subscription = MerchantSubscription::lockForUpdate()->find($payment->merchant_subscription_id);

                $payment->external_payment_id = $paymentId;
                $payment->gateway_signature = $signature;
                $payment->status = 'captured';
                $payment->paid_at = now();
                $payment->raw_payload = $request->all();
                $payment->save();

                MerchantSubscription::where('merchant_id', $merchantId)
                    ->where('id', '!=', $subscription->id)
                    ->where('status', 'active')
                    ->update(['status' => 'cancelled', 'cancelled_at' => now()]);

                $renewsAt = $subscription->billing_cycle === 'yearly'
                    ? now()->copy()->addYear()
                    : now()->copy()->addMonth();

                $subscription->status = 'active';
                $subscription->started_at = now();
                $subscription->renews_at = $renewsAt;
                $subscription->last_payment_at = now();
                $subscription->save();

                $user = User::find($merchantId);
                if ($user) {
                    $plan = SubscriptionPlan::find($subscription->subscription_plan_id);
                    $user->current_plan_code = $plan?->code;
                    $user->subscription_status = 'active';
                    $user->subscription_renews_at = $renewsAt;
                    $user->save();
                }
            });
        } catch (\Throwable $exception) {
            Log::error('Subscription webhook processing failed: ' . $exception->getMessage(), [
                'payload' => $request->all(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Webhook processing failed.',
            ], 500);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Subscription activated from webhook.',
        ], 200);
    }

    private function verifyWebhookSignature(string $body, string $signature): bool
    {
        $secret = (string) env('RAZORPAY_WEBHOOK_SECRET', '');

        if ($secret === '' || $signature === '') {
            return false;
        }

        $expected = hash_hmac('sha256', $body, $secret);

        return hash_equals($expected, $signature);
    }
}
