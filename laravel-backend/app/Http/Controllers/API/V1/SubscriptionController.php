<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\MerchantSubscription;
use App\Models\SubscriptionPayment;
use App\Models\SubscriptionPlan;
use App\Models\SubscriptionRequest;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SubscriptionController extends Controller
{
    /**
     * List active subscription plans (public, no auth).
     */
    public function plans()
    {
        try {
            $plans = SubscriptionPlan::where('is_active', true)
                ->orderBy('sort_order', 'asc')
                ->get()
                ->map(function ($p) {
                    return [
                        'id' => $p->id,
                        'code' => $p->code,
                        'name' => $p->name,
                        'tag' => $p->tag,
                        'tag_color' => $p->tag_color,
                        'badge' => $p->badge,
                        'description' => $p->description,
                        'subtitle' => $p->subtitle,
                        'monthly_price' => (float) $p->monthly_price,
                        'yearly_price' => (float) $p->yearly_price,
                        'currency' => $p->currency ?? 'INR',
                        'trial_days' => (int) ($p->trial_days ?? 0),
                        'customer_limit' => $p->customer_limit,
                        'features' => $p->features ?? [],
                        'feature_flags' => $p->feature_flags ?? [
                            'has_voice_entry' => false,
                            'has_soundbox' => false,
                            'has_desktop_access' => true,
                            'pdf_bill_access' => true,
                        ],
                        'sample_prompts' => $p->sample_prompts ?? [],
                        'cta_text' => $p->cta_text ?? 'Subscribe Now',
                        'is_active' => (bool) $p->is_active,
                    ];
                });

            return response()->json([
                'status' => 'success',
                'message' => 'Plans retrieved successfully',
                'data' => ['plans' => $plans],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'failed',
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Return the merchant's current active subscription (+ fallback plan meta & resolved feature flags).
     */
    public function current(Request $request)
    {
        try {
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

            $basicPlan = SubscriptionPlan::where('code', 'basic')->first();
            $defaultFeatureFlags = [
                'has_voice_entry' => false,
                'has_soundbox' => false,
                'has_desktop_access' => true,
                'pdf_bill_access' => true,
                'customer_limit' => null,
            ];

            // Check if existing trial has expired
            if ($subscription) {
                if ($subscription->status === 'trial' && $subscription->trial_ends_at && now()->gt($subscription->trial_ends_at)) {
                    $subscription->status = 'expired';
                    $subscription->save();

                    $user = User::find($merchantId);
                    if ($user) {
                        $user->current_plan_code = 'basic';
                        $user->subscription_status = 'expired';
                        $user->save();
                    }
                }
            }

            $isActivePaid = $subscription && $subscription->status === 'active' && (!$subscription->renews_at || now()->lte($subscription->renews_at));
            $isActiveTrial = $subscription && $subscription->status === 'trial' && $subscription->trial_ends_at && now()->lte($subscription->trial_ends_at);

            if ($isActivePaid || $isActiveTrial) {
                $plan = $subscription->plan;
                $featureFlags = $plan ? ($plan->feature_flags ?? $defaultFeatureFlags) : $defaultFeatureFlags;
                $remainingDays = $subscription->remainingTrialDays();

                return response()->json([
                    'status' => 'success',
                    'data' => [
                        'subscription' => $subscription,
                        'plan' => $plan,
                        'plan_code' => $plan?->code ?? 'basic',
                        'plan_name' => $plan?->name ?? 'Basic Plan',
                        'is_active' => true,
                        'is_trial' => $isActiveTrial,
                        'trial_days_remaining' => $remainingDays,
                        'feature_flags' => $featureFlags,
                        'can_use_voice' => !empty($featureFlags['has_voice_entry']),
                        'can_use_soundbox' => !empty($featureFlags['has_soundbox']),
                        'renews_at' => $subscription->renews_at?->toIso8601String(),
                        'trial_ends_at' => $subscription->trial_ends_at?->toIso8601String(),
                    ],
                ], 200);
            }

            // Fallback to Free Basic Plan (Zero Disruption Guarantee)
            return response()->json([
                'status' => 'success',
                'data' => [
                    'subscription' => $subscription,
                    'plan' => $basicPlan,
                    'plan_code' => 'basic',
                    'plan_name' => 'Basic Plan',
                    'is_active' => true,
                    'is_trial' => false,
                    'trial_days_remaining' => 0,
                    'feature_flags' => $defaultFeatureFlags,
                    'can_use_voice' => false,
                    'can_use_soundbox' => false,
                    'renews_at' => null,
                    'trial_ends_at' => null,
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json(['status' => 'failed', 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * Start a Free Trial for a plan (e.g. Premium 7-Day Trial).
     */
    public function startTrial(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'plan_code' => 'required|string',
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
                'message' => 'Selected plan was not found or is inactive.',
            ], 404);
        }

        if ($plan->trial_days <= 0) {
            return response()->json([
                'status' => 'error',
                'message' => 'This plan does not offer a free trial period.',
            ], 400);
        }

        // Check if merchant has already claimed a trial
        $existingTrial = MerchantSubscription::where('merchant_id', $merchantId)
            ->where(function ($query) {
                $query->where('status', 'trial')
                    ->orWhereNotNull('trial_ends_at');
            })
            ->first();

        if ($existingTrial) {
            return response()->json([
                'status' => 'error',
                'message' => 'A free trial has already been claimed for this merchant account.',
            ], 400);
        }

        // Check if merchant already has an active paid subscription
        $activeSubscription = MerchantSubscription::where('merchant_id', $merchantId)
            ->whereIn('status', ['active', 'trial'])
            ->where(function ($query) {
                $query->whereNull('renews_at')
                    ->orWhere('renews_at', '>', now());
            })
            ->first();

        if ($activeSubscription) {
            return response()->json([
                'status' => 'error',
                'message' => 'You already have an active paid subscription.',
            ], 400);
        }

        $trialEndsAt = now()->addDays($plan->trial_days);

        $subscription = DB::transaction(function () use ($merchantId, $plan, $trialEndsAt) {
            MerchantSubscription::where('merchant_id', $merchantId)
                ->whereIn('status', ['pending'])
                ->update(['status' => 'cancelled', 'cancelled_at' => now()]);

            $newSubscription = MerchantSubscription::create([
                'merchant_id' => $merchantId,
                'subscription_plan_id' => $plan->id,
                'billing_cycle' => 'monthly',
                'status' => 'trial',
                'started_at' => now(),
                'trial_ends_at' => $trialEndsAt,
                'renews_at' => $trialEndsAt,
                'auto_renew' => false,
                'meta' => [
                    'plan_code' => $plan->code,
                    'trial_days' => $plan->trial_days,
                    'started_at' => now()->toIso8601String(),
                    'activated_via' => 'app_free_trial',
                ],
            ]);

            $user = User::find($merchantId);
            if ($user) {
                $user->current_plan_code = $plan->code;
                $user->subscription_status = 'trial';
                $user->subscription_renews_at = $trialEndsAt;
                $user->save();
            }

            return $newSubscription;
        });

        $subscription->load('plan');

        return response()->json([
            'status' => 'success',
            'message' => "Congratulations! Your {$plan->trial_days}-day Free Trial of {$plan->name} is now active.",
            'data' => [
                'subscription' => $subscription,
                'plan' => $plan,
                'plan_code' => $plan->code,
                'is_trial' => true,
                'trial_days_remaining' => $plan->trial_days,
                'feature_flags' => $plan->feature_flags,
                'can_use_voice' => !empty($plan->feature_flags['has_voice_entry']),
                'can_use_soundbox' => !empty($plan->feature_flags['has_soundbox']),
                'trial_ends_at' => $trialEndsAt->toIso8601String(),
            ],
        ], 200);
    }

    /**
     * History of the merchant's subscriptions + offline requests.
     */
    public function history(Request $request)
    {
        try {
            $merchantId = $this->resolveMerchantId($request);
            $subs = MerchantSubscription::with('plan')
                ->where('merchant_id', $merchantId)
                ->orderByDesc('id')
                ->get();
            $requests = SubscriptionRequest::with('plan')
                ->where('merchant_id', $merchantId)
                ->orderByDesc('id')
                ->get();

            return response()->json([
                'status' => 'success',
                'data' => [
                    'subscriptions' => $subs,
                    'requests' => $requests,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json(['status' => 'failed', 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * Merchant submits an OFFLINE upgrade request (no payment). Pending until admin approves.
     */
    public function offlineRequest(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'plan_code' => 'required|string|exists:subscription_plans,code',
            'billing_cycle' => 'required|in:monthly,yearly',
            'note' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'failed',
                'message' => collect($validator->errors()->all())->first(),
            ], 422);
        }

        try {
            $merchantId = $this->resolveMerchantId($request);
            $plan = SubscriptionPlan::where('code', $request->plan_code)->firstOrFail();
            $cycle = $request->billing_cycle;
            $price = $cycle === 'yearly' ? $plan->yearly_price : $plan->monthly_price;

            $pending = SubscriptionRequest::where('merchant_id', $merchantId)
                ->where('status', 'pending')
                ->orderByDesc('id')
                ->first();
            if ($pending) {
                return response()->json([
                    'status' => 'failed',
                    'message' => 'You already have a pending upgrade request. Please wait for it to be resolved.',
                ], 400);
            }

            DB::beginTransaction();
            $req = SubscriptionRequest::create([
                'merchant_id' => $merchantId,
                'subscription_plan_id' => $plan->id,
                'requested_plan_code' => $plan->code,
                'billing_cycle' => $cycle,
                'status' => 'pending',
                'note' => $request->note,
            ]);
            DB::commit();

            return response()->json([
                'status' => 'success',
                'message' => 'Upgrade request received. It will be activated once approved by admin (offline payment).',
                'data' => [
                    'request' => [
                        'id' => $req->id,
                        'plan' => $plan->code,
                        'plan_name' => $plan->name,
                        'billing_cycle' => $cycle,
                        'amount' => (float) $price,
                        'status' => 'pending',
                    ],
                ],
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['status' => 'failed', 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * Merchant's own pending request + active subscription summary.
     */
    public function myUpgradeStatus(Request $request)
    {
        try {
            $merchantId = $this->resolveMerchantId($request);
            $active = MerchantSubscription::with('plan')
                ->where('merchant_id', $merchantId)
                ->whereIn('status', ['active', 'trial'])
                ->orderByDesc('id')
                ->first();
            $latestRequest = SubscriptionRequest::with('plan')
                ->where('merchant_id', $merchantId)
                ->orderByDesc('id')
                ->first();

            return response()->json([
                'status' => 'success',
                'data' => [
                    'active_subscription' => $active,
                    'latest_request' => $latestRequest,
                    'has_pending_request' => $latestRequest && $latestRequest->status === 'pending',
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json(['status' => 'failed', 'message' => $e->getMessage()], 500);
        }
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
                'currency' => $plan->currency ?? 'INR',
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
                'currency' => $plan->currency ?? 'INR',
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
                ->whereIn('status', ['active', 'trial'])
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
            ->whereIn('status', ['active', 'trial'])
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

    private function resolveMerchantId(Request $request): ?int
    {
        if (auth()->check()) {
            return (int) auth()->id();
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
            })->first();

            if ($merchant) {
                return (int) $merchant->id;
            }
        }

        return null;
    }
}
