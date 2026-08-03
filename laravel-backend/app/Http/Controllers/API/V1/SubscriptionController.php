<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\MerchantSubscription;
use App\Models\SubscriptionPayment;
use App\Models\SubscriptionPlan;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SubscriptionController extends Controller
{
    /**
     * Public endpoint to fetch active plans.
     */
    public function plans()
    {
        $plans = SubscriptionPlan::where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => [
                'plans' => $plans,
            ],
        ], 200);
    }

    /**
     * Fetch current merchant subscription.
     */
    public function current(Request $request)
    {
        $merchantId = $this->resolveMerchantId($request);
        if (!$merchantId) {
            return response()->json([
                'status' => 'error',
                'message' => 'Merchant identity is required.',
            ], 422);
        }

        $subscription = MerchantSubscription::with('plan')
            ->where('merchant_id', $merchantId)
            ->orderByDesc('id')
            ->first();

        return response()->json([
            'status' => 'success',
            'data' => [
                'subscription' => $subscription,
            ],
        ], 200);
    }

    /**
     * Create pending checkout state before Razorpay checkout.
     */
    public function createCheckout(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'plan_code' => 'required|string',
            'billing_cycle' => 'required|in:monthly,yearly',
            'merchant_id' => 'nullable|integer',
            'merchant_phone' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $merchantId = $this->resolveMerchantId($request);
        if (!$merchantId) {
            return response()->json([
                'status' => 'error',
                'message' => 'Merchant identity is required.',
            ], 422);
        }

        $plan = SubscriptionPlan::where('code', $request->plan_code)
            ->where('is_active', true)
            ->first();

        if (!$plan) {
            return response()->json([
                'status' => 'error',
                'message' => 'Selected plan is not available.',
            ], 404);
        }

        $amount = $request->billing_cycle === 'yearly'
            ? $plan->yearly_price
            : $plan->monthly_price;

        $orderId = 'sub_order_' . $merchantId . '_' . now()->timestamp . '_' . random_int(1000, 9999);

        $subscription = null;

        DB::transaction(function () use ($merchantId, $plan, $request, $amount, $orderId, &$subscription) {
            MerchantSubscription::where('merchant_id', $merchantId)
                ->whereIn('status', ['pending'])
                ->update(['status' => 'cancelled', 'cancelled_at' => now()]);

            $subscription = MerchantSubscription::create([
                'merchant_id' => $merchantId,
                'subscription_plan_id' => $plan->id,
                'billing_cycle' => $request->billing_cycle,
                'status' => 'pending',
                'meta' => [
                    'plan_code' => $plan->code,
                    'checkout_order_id' => $orderId,
                ],
            ]);

            SubscriptionPayment::create([
                'merchant_subscription_id' => $subscription->id,
                'merchant_id' => $merchantId,
                'subscription_plan_id' => $plan->id,
                'billing_cycle' => $request->billing_cycle,
                'amount' => $amount,
                'currency' => $plan->currency,
                'gateway' => 'razorpay',
                'external_order_id' => $orderId,
                'status' => 'initiated',
                'raw_payload' => [
                    'plan_code' => $plan->code,
                    'billing_cycle' => $request->billing_cycle,
                ],
            ]);
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Checkout created successfully.',
            'data' => [
                'subscription_id' => $subscription->id,
                'order_id' => $orderId,
                'merchant_id' => $merchantId,
                'plan_code' => $plan->code,
                'billing_cycle' => $request->billing_cycle,
                'amount' => $amount,
                'currency' => $plan->currency,
            ],
        ], 200);
    }

    /**
     * Verify checkout result and activate subscription.
     */
    public function verifyCheckout(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'merchant_id' => 'nullable|integer',
            'merchant_phone' => 'nullable|string',
            'order_id' => 'required|string',
            'payment_id' => 'required|string',
            'signature' => 'nullable|string',
            'status' => 'required|in:captured,failed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $merchantId = $this->resolveMerchantId($request);
        if (!$merchantId) {
            return response()->json([
                'status' => 'error',
                'message' => 'Merchant identity is required.',
            ], 422);
        }

        $payment = SubscriptionPayment::where('merchant_id', $merchantId)
            ->where('external_order_id', $request->order_id)
            ->first();

        if (!$payment) {
            return response()->json([
                'status' => 'error',
                'message' => 'Checkout order not found.',
            ], 404);
        }

        if (!empty($payment->external_payment_id) && $payment->external_payment_id === $request->payment_id) {
            return response()->json([
                'status' => 'success',
                'message' => 'Payment already verified.',
                'data' => [
                    'subscription_id' => $payment->merchant_subscription_id,
                ],
            ], 200);
        }

        DB::transaction(function () use ($request, $merchantId, $payment) {
            $subscription = MerchantSubscription::lockForUpdate()->find($payment->merchant_subscription_id);

            $payment->external_payment_id = $request->payment_id;
            $payment->gateway_signature = $request->signature;
            $payment->status = $request->status === 'captured' ? 'captured' : 'failed';
            $payment->paid_at = $request->status === 'captured' ? now() : null;
            $payment->raw_payload = array_merge($payment->raw_payload ?? [], [
                'verify_payload' => $request->all(),
            ]);
            $payment->save();

            if ($request->status !== 'captured') {
                $subscription->status = 'pending';
                $subscription->save();
                return;
            }

            MerchantSubscription::where('merchant_id', $merchantId)
                ->where('id', '!=', $subscription->id)
                ->where('status', 'active')
                ->update(['status' => 'cancelled', 'cancelled_at' => now()]);

            $startedAt = now();
            $renewsAt = $subscription->billing_cycle === 'yearly'
                ? now()->copy()->addYear()
                : now()->copy()->addMonth();

            $subscription->status = 'active';
            $subscription->started_at = $startedAt;
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

        return response()->json([
            'status' => 'success',
            'message' => $request->status === 'captured' ? 'Subscription activated.' : 'Payment marked as failed.',
        ], 200);
    }

    /**
     * Disable auto renew flag for current subscription.
     */
    public function cancelAutoRenew(Request $request)
    {
        $merchantId = $this->resolveMerchantId($request);
        if (!$merchantId) {
            return response()->json([
                'status' => 'error',
                'message' => 'Merchant identity is required.',
            ], 422);
        }

        $subscription = MerchantSubscription::where('merchant_id', $merchantId)
            ->where('status', 'active')
            ->orderByDesc('id')
            ->first();

        if (!$subscription) {
            return response()->json([
                'status' => 'error',
                'message' => 'Active subscription not found.',
            ], 404);
        }

        $subscription->auto_renew = false;
        $subscription->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Auto-renew cancelled successfully.',
        ], 200);
    }

    /**
     * Merchant payment history endpoint.
     */
    public function paymentHistory(Request $request)
    {
        $merchantId = $this->resolveMerchantId($request);
        if (!$merchantId) {
            return response()->json([
                'status' => 'error',
                'message' => 'Merchant identity is required.',
            ], 422);
        }

        $payments = SubscriptionPayment::where('merchant_id', $merchantId)
            ->orderByDesc('id')
            ->paginate(20);

        return response()->json([
            'status' => 'success',
            'data' => [
                'payments' => $payments,
            ],
        ], 200);
    }

    private function resolveMerchantId(Request $request): ?int
    {
        if ($request->user()) {
            return (int) $request->user()->id;
        }

        if ($request->filled('merchant_id')) {
            return (int) $request->merchant_id;
        }

        $merchantIdHeader = $request->header('X-Merchant-Id');
        if (!empty($merchantIdHeader) && ctype_digit((string) $merchantIdHeader)) {
            return (int) $merchantIdHeader;
        }

        $merchantPhone = $request->input('merchant_phone')
            ?? $request->header('X-Merchant-Phone');

        if (!empty($merchantPhone)) {
            $cleanPhone = preg_replace('/[^0-9]/', '', (string) $merchantPhone);
            if (strlen($cleanPhone) > 10) {
                $cleanPhone = substr($cleanPhone, -10);
            }

            $merchant = User::where(function ($query) use ($merchantPhone, $cleanPhone) {
                $query->where('phone', (string) $merchantPhone)
                    ->orWhere('username', (string) $merchantPhone)
                    ->orWhere('phone', 'like', '%' . $cleanPhone)
                    ->orWhere('username', 'like', '%' . $cleanPhone);
            })->where('type', 'merchant')->first();

            if ($merchant) {
                return (int) $merchant->id;
            }
        }

        return null;
    }
}
