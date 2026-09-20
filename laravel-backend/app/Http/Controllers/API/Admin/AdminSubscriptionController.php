<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\MerchantSubscription;
use App\Models\SubscriptionPayment;
use App\Models\SubscriptionPlan;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class AdminSubscriptionController extends Controller
{
    /**
     * List all plans (active and inactive) with subscriber statistics.
     */
    public function plans()
    {
        $plans = SubscriptionPlan::orderBy('sort_order', 'asc')
            ->withCount([
                'subscriptions as active_subscribers_count' => function ($query) {
                    $query->where('status', 'active');
                },
                'subscriptions as trial_subscribers_count' => function ($query) {
                    $query->where('status', 'trial');
                },
            ])
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => [
                'plans' => $plans,
            ],
        ], 200);
    }

    /**
     * Create a new subscription plan.
     */
    public function storePlan(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'code' => 'required|string|unique:subscription_plans,code|max:50',
            'name' => 'required|string|max:100',
            'tag' => 'nullable|string|max:50',
            'tag_color' => 'nullable|string|max:30',
            'badge' => 'nullable|string|max:50',
            'description' => 'nullable|string',
            'subtitle' => 'nullable|string',
            'monthly_price' => 'required|numeric|min:0',
            'yearly_price' => 'required|numeric|min:0',
            'currency' => 'nullable|string|max:10',
            'trial_days' => 'nullable|integer|min:0',
            'features' => 'nullable|array',
            'feature_flags' => 'nullable|array',
            'sample_prompts' => 'nullable|array',
            'cta_text' => 'nullable|string|max:50',
            'sort_order' => 'nullable|integer',
            'is_active' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
                'errors' => $validator->errors(),
            ], 422);
        }

        $plan = SubscriptionPlan::create([
            'code' => strtolower(trim($request->code)),
            'name' => $request->name,
            'tag' => $request->tag,
            'tag_color' => $request->tag_color ?? '#1E293B',
            'badge' => $request->badge,
            'description' => $request->description,
            'subtitle' => $request->subtitle,
            'monthly_price' => $request->monthly_price,
            'yearly_price' => $request->yearly_price,
            'currency' => $request->currency ?? 'INR',
            'trial_days' => $request->trial_days ?? 0,
            'customer_limit' => $request->customer_limit ?? null,
            'features' => $request->features ?? [],
            'feature_flags' => $request->feature_flags ?? [
                'has_voice_entry' => false,
                'has_soundbox' => false,
                'has_desktop_access' => true,
                'pdf_bill_access' => true,
            ],
            'sample_prompts' => $request->sample_prompts ?? [],
            'cta_text' => $request->cta_text ?? 'Subscribe Now',
            'sort_order' => $request->sort_order ?? 99,
            'is_active' => $request->boolean('is_active', true),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => "Plan '{$plan->name}' created successfully.",
            'data' => [
                'plan' => $plan,
            ],
        ], 201);
    }

    /**
     * Update an existing subscription plan.
     */
    public function updatePlan(Request $request, $id)
    {
        $plan = SubscriptionPlan::find($id);
        if (!$plan) {
            return response()->json([
                'status' => 'error',
                'message' => 'Subscription plan not found.',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:100',
            'tag' => 'nullable|string|max:50',
            'tag_color' => 'nullable|string|max:30',
            'badge' => 'nullable|string|max:50',
            'description' => 'nullable|string',
            'subtitle' => 'nullable|string',
            'monthly_price' => 'sometimes|required|numeric|min:0',
            'yearly_price' => 'sometimes|required|numeric|min:0',
            'currency' => 'nullable|string|max:10',
            'trial_days' => 'nullable|integer|min:0',
            'features' => 'nullable|array',
            'feature_flags' => 'nullable|array',
            'sample_prompts' => 'nullable|array',
            'cta_text' => 'nullable|string|max:50',
            'sort_order' => 'nullable|integer',
            'is_active' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
                'errors' => $validator->errors(),
            ], 422);
        }

        $fields = $request->only([
            'name',
            'tag',
            'tag_color',
            'badge',
            'description',
            'subtitle',
            'monthly_price',
            'yearly_price',
            'currency',
            'trial_days',
            'customer_limit',
            'features',
            'feature_flags',
            'sample_prompts',
            'cta_text',
            'sort_order',
            'is_active',
        ]);

        $plan->update($fields);

        return response()->json([
            'status' => 'success',
            'message' => "Plan '{$plan->name}' updated successfully.",
            'data' => [
                'plan' => $plan->fresh(),
            ],
        ], 200);
    }

    /**
     * Toggle plan active/inactive status.
     */
    public function togglePlanStatus($id)
    {
        $plan = SubscriptionPlan::find($id);
        if (!$plan) {
            return response()->json([
                'status' => 'error',
                'message' => 'Subscription plan not found.',
            ], 404);
        }

        $plan->is_active = !$plan->is_active;
        $plan->save();

        $statusText = $plan->is_active ? 'activated' : 'deactivated';

        return response()->json([
            'status' => 'success',
            'message' => "Plan '{$plan->name}' has been {$statusText}.",
            'data' => [
                'plan' => $plan,
            ],
        ], 200);
    }

    /**
     * List all merchant subscriptions with filtering.
     */
    public function subscribers(Request $request)
    {
        $query = MerchantSubscription::with(['plan', 'payments' => function ($q) {
            $q->orderByDesc('id')->limit(3);
        }]);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('plan_code')) {
            $query->whereHas('plan', function ($q) use ($request) {
                $q->where('code', $request->plan_code);
            });
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('phone', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $subscribers = $query->orderByDesc('id')->paginate(25);

        return response()->json([
            'status' => 'success',
            'data' => [
                'subscribers' => $subscribers,
            ],
        ], 200);
    }

    /**
     * Approve offline / manual payment for a merchant subscription.
     */
    public function approveOfflinePayment(Request $request, $id)
    {
        $subscription = MerchantSubscription::with('plan')->find($id);
        if (!$subscription) {
            return response()->json([
                'status' => 'error',
                'message' => 'Subscription record not found.',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'reference_no' => 'nullable|string',
            'notes' => 'nullable|string',
            'duration_months' => 'nullable|integer|min:1|max:36',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $durationMonths = $request->input('duration_months', $subscription->billing_cycle === 'yearly' ? 12 : 1);
        $startedAt = now();
        $renewsAt = now()->addMonths($durationMonths);

        DB::transaction(function () use ($subscription, $startedAt, $renewsAt, $request, $durationMonths) {
            $subscription->status = 'active';
            $subscription->started_at = $startedAt;
            $subscription->renews_at = $renewsAt;
            $subscription->last_payment_at = now();
            $subscription->meta = array_merge($subscription->meta ?? [], [
                'approved_by_admin' => true,
                'admin_notes' => $request->notes,
                'offline_reference' => $request->reference_no,
                'approved_at' => now()->toIso8601String(),
            ]);
            $subscription->save();

            SubscriptionPayment::create([
                'merchant_subscription_id' => $subscription->id,
                'merchant_id' => $subscription->merchant_id,
                'subscription_plan_id' => $subscription->subscription_plan_id,
                'billing_cycle' => $subscription->billing_cycle,
                'amount' => $subscription->plan ? $subscription->plan->monthly_price * $durationMonths : 0,
                'currency' => $subscription->plan?->currency ?? 'INR',
                'gateway' => 'offline',
                'external_order_id' => 'ADMIN_MANUAL_' . now()->timestamp,
                'external_payment_id' => $request->reference_no ?? ('OFFLINE_' . now()->timestamp),
                'status' => 'captured',
                'paid_at' => now(),
                'raw_payload' => [
                    'admin_approval' => true,
                    'notes' => $request->notes,
                ],
            ]);

            $user = User::find($subscription->merchant_id);
            if ($user) {
                $user->current_plan_code = $subscription->plan?->code ?? 'premium';
                $user->subscription_status = 'active';
                $user->subscription_renews_at = $renewsAt;
                $user->save();
            }
        });

        return response()->json([
            'status' => 'success',
            'message' => "Subscription #{$subscription->id} approved and activated until {$renewsAt->toDateString()}.",
            'data' => [
                'subscription' => $subscription->fresh(),
            ],
        ], 200);
    }

    /**
     * Extend free trial for a merchant account.
     */
    public function extendTrial(Request $request, $id)
    {
        $subscription = MerchantSubscription::find($id);
        if (!$subscription) {
            return response()->json([
                'status' => 'error',
                'message' => 'Subscription record not found.',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'additional_days' => 'required|integer|min:1|max:90',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $days = (int) $request->additional_days;
        $baseDate = ($subscription->trial_ends_at && now()->lt($subscription->trial_ends_at))
            ? $subscription->trial_ends_at
            : now();

        $newTrialEnd = $baseDate->copy()->addDays($days);

        $premiumPlan = SubscriptionPlan::where('code', 'premium')->first() ?? SubscriptionPlan::first();

        $subscription->subscription_plan_id = $premiumPlan->id;
        $subscription->status = 'trial';
        $subscription->trial_ends_at = $newTrialEnd;
        $subscription->renews_at = $newTrialEnd;
        $subscription->meta = array_merge($subscription->meta ?? [], [
            'plan_code' => 'premium',
            'trial_extended' => true,
            'extended_days' => $days,
            'extended_notes' => $request->notes,
            'extended_at' => now()->toIso8601String(),
        ]);
        $subscription->save();

        $user = User::find($subscription->merchant_id);
        if ($user) {
            $user->current_plan_code = 'premium';
            $user->subscription_status = 'trial';
            $user->subscription_renews_at = $newTrialEnd;
            $user->save();
        }

        return response()->json([
            'status' => 'success',
            'message' => "Trial extended by {$days} days until {$newTrialEnd->toDateString()}.",
            'data' => [
                'subscription' => $subscription->fresh(),
                'trial_ends_at' => $newTrialEnd->toIso8601String(),
                'remaining_trial_days' => $subscription->remainingTrialDays(),
            ],
        ], 200);
    }
}
