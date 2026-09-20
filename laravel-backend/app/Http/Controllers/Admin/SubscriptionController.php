<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\MerchantSubscription;
use App\Models\SubscriptionPlan;
use App\Models\SubscriptionRequest;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class SubscriptionController extends Controller
{
    /**
     * Display all merchants with their active/trial subscription plans.
     */
    public function index(Request $request)
    {
        $statusFilter = $request->query('status', 'all');
        $planFilter = $request->query('plan', 'all');
        $search = $request->query('search', '');

        $query = User::query()
            ->whereIn('type', ['merchant', 'user'])
            ->with(['activeSubscription.plan', 'currentPlan']);

        if (!empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('firstname', 'like', "%{$search}%")
                    ->orWhere('lastname', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('shop_name', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%");
            });
        }

        if ($planFilter !== 'all') {
            if ($planFilter === 'basic') {
                $query->where(function ($q) {
                    $q->whereNull('current_plan_code')
                        ->orWhere('current_plan_code', 'basic');
                });
            } else {
                $query->where('current_plan_code', $planFilter);
            }
        }

        if ($statusFilter !== 'all') {
            if ($statusFilter === 'trial') {
                $query->where('subscription_status', 'trial');
            } elseif ($statusFilter === 'active') {
                $query->where('subscription_status', 'active');
            } elseif ($statusFilter === 'expired') {
                $query->where('subscription_status', 'expired');
            } elseif ($statusFilter === 'basic') {
                $query->where(function ($q) {
                    $q->whereNull('subscription_status')
                        ->orWhere('subscription_status', 'basic')
                        ->orWhereNull('current_plan_code')
                        ->orWhere('current_plan_code', 'basic');
                });
            }
        }

        $merchants = $query->orderBy('id', 'desc')->paginate(20)->withQueryString();

        $stats = [
            'total_merchants' => User::whereIn('type', ['merchant', 'user'])->count(),
            'active_subscribers' => User::whereIn('type', ['merchant', 'user'])->where('subscription_status', 'active')->count(),
            'trial_subscribers' => User::whereIn('type', ['merchant', 'user'])->where('subscription_status', 'trial')->count(),
            'premium_count' => User::whereIn('type', ['merchant', 'user'])->where('current_plan_code', 'premium')->count(),
            'gold_count' => User::whereIn('type', ['merchant', 'user'])->where('current_plan_code', 'gold')->count(),
            'pending_requests' => SubscriptionRequest::where('status', 'pending')->count(),
        ];

        $plans = SubscriptionPlan::orderBy('sort_order', 'asc')->get();

        return view('admin.subscriptions.index', compact(
            'merchants',
            'stats',
            'plans',
            'statusFilter',
            'planFilter',
            'search'
        ));
    }

    /**
     * Dedicated view for active 7-Day Free Trials.
     */
    public function trials(Request $request)
    {
        $search = $request->query('search', '');

        $query = MerchantSubscription::with(['merchant', 'plan'])
            ->where('status', 'trial');

        if (!empty($search)) {
            $query->whereHas('merchant', function ($q) use ($search) {
                $q->where('firstname', 'like', "%{$search}%")
                    ->orWhere('lastname', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%")
                    ->orWhere('shop_name', 'like', "%{$search}%");
            });
        }

        $trials = $query->orderBy('trial_ends_at', 'asc')->paginate(20)->withQueryString();
        $plans = SubscriptionPlan::where('is_active', true)->get();

        $trialStats = [
            'active_trials' => MerchantSubscription::where('status', 'trial')->count(),
            'expiring_today' => MerchantSubscription::where('status', 'trial')
                ->whereDate('trial_ends_at', Carbon::today())
                ->count(),
            'extended_trials' => MerchantSubscription::where('status', 'trial')
                ->where('meta->trial_extended', true)
                ->count(),
        ];

        return view('admin.subscriptions.trials', compact('trials', 'plans', 'trialStats', 'search'));
    }

    /**
     * Manage Plans, Pricing, and Features.
     */
    public function plans()
    {
        $plans = SubscriptionPlan::orderBy('sort_order', 'asc')
            ->withCount([
                'subscriptions as active_subscribers_count' => function ($q) {
                    $q->where('status', 'active');
                },
                'subscriptions as trial_subscribers_count' => function ($q) {
                    $q->where('status', 'trial');
                },
            ])
            ->get();

        return view('admin.subscriptions.plans', compact('plans'));
    }

    /**
     * Update plan settings, pricing, features, and trial duration.
     */
    public function updatePlan(Request $request, $id)
    {
        $plan = SubscriptionPlan::findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:100',
            'monthly_price' => 'required|numeric|min:0',
            'yearly_price' => 'required|numeric|min:0',
            'trial_days' => 'required|integer|min:0|max:365',
            'subtitle' => 'nullable|string|max:255',
            'tag' => 'nullable|string|max:50',
            'badge' => 'nullable|string|max:50',
            'features' => 'nullable|string',
            'sample_prompts' => 'nullable|string',
        ]);

        $featuresArray = [];
        if ($request->filled('features')) {
            $rawLines = explode("\n", $request->features);
            foreach ($rawLines as $line) {
                $line = trim($line);
                if ($line !== '') {
                    $featuresArray[] = $line;
                }
            }
        }

        $promptsArray = [];
        if ($request->filled('sample_prompts')) {
            $rawLines = explode("\n", $request->sample_prompts);
            foreach ($rawLines as $line) {
                $line = trim($line);
                if ($line !== '') {
                    $promptsArray[] = $line;
                }
            }
        }

        $plan->update([
            'name' => $request->name,
            'monthly_price' => $request->monthly_price,
            'yearly_price' => $request->yearly_price,
            'trial_days' => $request->trial_days,
            'subtitle' => $request->subtitle,
            'tag' => $request->tag,
            'badge' => $request->badge,
            'features' => $featuresArray,
            'sample_prompts' => !empty($promptsArray) ? $promptsArray : null,
            'is_active' => $request->has('is_active') ? (bool)$request->is_active : $plan->is_active,
        ]);

        return back()->with('success', "Plan '{$plan->name}' has been updated successfully.");
    }

    /**
     * Toggle plan active/inactive status.
     */
    public function togglePlanStatus($id)
    {
        $plan = SubscriptionPlan::findOrFail($id);
        $plan->is_active = !$plan->is_active;
        $plan->save();

        $state = $plan->is_active ? 'activated' : 'deactivated';
        return back()->with('success', "Plan '{$plan->name}' has been {$state}.");
    }

    /**
     * Extend trial duration for a merchant.
     */
    public function extendTrial(Request $request, $id)
    {
        $request->validate([
            'additional_days' => 'required|integer|min:1|max:90',
            'notes' => 'nullable|string|max:255',
        ]);

        $days = (int) $request->additional_days;

        $sub = MerchantSubscription::find($id);
        if (!$sub) {
            $sub = MerchantSubscription::where('merchant_id', $id)->orderByDesc('id')->first();
        }

        $merchant = $sub ? User::find($sub->merchant_id) : User::find($id);
        if (!$merchant) {
            return back()->with('error', 'Merchant account not found.');
        }

        $baseDate = ($sub && $sub->trial_ends_at && Carbon::parse($sub->trial_ends_at)->isFuture())
            ? Carbon::parse($sub->trial_ends_at)
            : Carbon::now();

        $newTrialEnd = $baseDate->copy()->addDays($days);

        // A free trial in UdharCard is EXCLUSIVELY for the Premium Plan (AI Voice Khata).
        // Gold Plan does not offer trials as it includes physical soundbox hardware.
        $premiumPlan = SubscriptionPlan::where('code', 'premium')->first() ?? SubscriptionPlan::first();

        // If existing subscription is already an active trial for Premium, extend it
        if ($sub && $sub->status === 'trial') {
            $sub->subscription_plan_id = $premiumPlan->id; // Enforce Premium
            $sub->trial_ends_at = $newTrialEnd;
            $sub->renews_at = $newTrialEnd;
            $meta = $sub->meta ?? [];
            $meta['plan_code'] = 'premium';
            $meta['trial_extended'] = true;
            $meta['extended_days'] = $days;
            $meta['extended_at'] = now()->toIso8601String();
            $meta['admin_notes'] = $request->notes;
            $sub->meta = $meta;
            $sub->save();
        } else {
            // Cancel any old active, trial or pending records so they don't conflict
            MerchantSubscription::where('merchant_id', $merchant->id)
                ->whereIn('status', ['active', 'trial', 'pending'])
                ->update(['status' => 'cancelled', 'cancelled_at' => Carbon::now()]);

            $sub = MerchantSubscription::create([
                'merchant_id' => $merchant->id,
                'subscription_plan_id' => $premiumPlan->id,
                'billing_cycle' => 'monthly',
                'status' => 'trial',
                'started_at' => Carbon::now(),
                'renews_at' => $newTrialEnd,
                'trial_ends_at' => $newTrialEnd,
                'meta' => [
                    'plan_code' => 'premium',
                    'created_by' => 'admin_trial_extension',
                    'trial_extended' => true,
                    'extended_days' => $days,
                    'admin_notes' => $request->notes,
                ],
            ]);
        }

        $merchant->current_plan_code = 'premium';
        $merchant->subscription_status = 'trial';
        $merchant->subscription_renews_at = $newTrialEnd;
        $merchant->save();

        return back()->with('success', "Premium Free Trial extended by {$days} days for {$merchant->firstname} (Valid until {$newTrialEnd->format('d M, Y')}).");
    }

    /**
     * Manually assign or change a merchant's plan.
     */
    public function assignPlan(Request $request)
    {
        $request->validate([
            'merchant_id' => 'required|exists:users,id',
            'plan_id' => 'required|exists:subscription_plans,id',
            'billing_cycle' => 'required|in:monthly,yearly',
            'status' => 'required|in:active,trial,expired,basic',
            'duration_months' => 'nullable|integer|min:1|max:36',
        ]);

        $merchant = User::findOrFail($request->merchant_id);
        $plan = SubscriptionPlan::findOrFail($request->plan_id);

        // Free trial is strictly Premium plan (AI Voice Khata)
        if ($request->status === 'trial' && $plan->trial_days <= 0) {
            $plan = SubscriptionPlan::where('code', 'premium')->first() ?? $plan;
        }

        $startedAt = Carbon::now();
        $durationMonths = (int) ($request->duration_months ?? ($request->billing_cycle === 'yearly' ? 12 : 1));
        $renewsAt = (clone $startedAt)->addMonths($durationMonths);

        MerchantSubscription::where('merchant_id', $merchant->id)
            ->whereIn('status', ['active', 'trial', 'pending'])
            ->update(['status' => 'cancelled', 'cancelled_at' => Carbon::now()]);

        if ($request->status === 'basic') {
            $merchant->current_plan_code = 'basic';
            $merchant->subscription_status = null;
            $merchant->subscription_renews_at = null;
            $merchant->save();
            return back()->with('success', "Merchant {$merchant->firstname} switched to Free Basic Plan.");
        }

        $trialEndsAt = $request->status === 'trial'
            ? (clone $startedAt)->addDays($plan->trial_days ?: 7)
            : null;

        $sub = MerchantSubscription::create([
            'merchant_id' => $merchant->id,
            'subscription_plan_id' => $plan->id,
            'billing_cycle' => $request->billing_cycle,
            'status' => $request->status,
            'started_at' => $startedAt,
            'renews_at' => $renewsAt,
            'trial_ends_at' => $trialEndsAt,
            'meta' => [
                'plan_code' => $plan->code,
                'assigned_by_admin' => true,
                'admin_id' => Auth::id(),
                'assigned_at' => now()->toIso8601String(),
            ],
        ]);

        $merchant->current_plan_code = $plan->code;
        $merchant->subscription_status = $request->status;
        $merchant->subscription_renews_at = $request->status === 'trial' ? $trialEndsAt : $renewsAt;
        $merchant->save();

        return back()->with('success', "Merchant {$merchant->firstname} assigned to {$plan->name} ({$request->status}) successfully.");
    }

    /**
     * Offline upgrade requests list.
     */
    public function requests(Request $request)
    {
        $status = $request->query('status', 'all');
        $query = SubscriptionRequest::with(['merchant', 'plan'])->orderBy('id', 'desc');

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $requests = $query->paginate(20)->withQueryString();

        return view('admin.subscriptions.requests', compact('requests', 'status'));
    }

    /**
     * Approve upgrade request.
     */
    public function approveRequest(Request $request, $id)
    {
        $req = SubscriptionRequest::with('plan')->findOrFail($id);
        if ($req->status !== 'pending') {
            return back()->with('error', 'Request already processed.');
        }

        $merchant = User::findOrFail($req->merchant_id);
        $plan = $req->plan ?? SubscriptionPlan::where('code', $req->requested_plan_code)->firstOrFail();

        $startedAt = Carbon::now();
        $renewsAt = $req->billing_cycle === 'yearly' ? (clone $startedAt)->addYear() : (clone $startedAt)->addMonth();

        MerchantSubscription::where('merchant_id', $merchant->id)
            ->whereIn('status', ['active', 'trial'])
            ->update(['status' => 'cancelled', 'cancelled_at' => Carbon::now()]);

        MerchantSubscription::create([
            'merchant_id' => $merchant->id,
            'subscription_plan_id' => $plan->id,
            'billing_cycle' => $req->billing_cycle,
            'status' => 'active',
            'started_at' => $startedAt,
            'renews_at' => $renewsAt,
            'last_payment_at' => Carbon::now(),
            'auto_renew' => false,
            'meta' => [
                'activated_by' => 'admin_web_approval',
                'subscription_request_id' => $req->id,
                'approved_by' => Auth::id(),
            ],
        ]);

        $merchant->current_plan_code = $plan->code;
        $merchant->subscription_status = 'active';
        $merchant->subscription_renews_at = $renewsAt;
        $merchant->save();

        $req->status = 'approved';
        $req->admin_remark = $request->admin_remark ?? 'Approved by Admin';
        $req->resolved_at = Carbon::now();
        $req->resolved_by = Auth::id();
        $req->save();

        return back()->with('success', "Request #{$req->id} approved. {$merchant->firstname} is now on {$plan->name}.");
    }

    /**
     * Reject upgrade request.
     */
    public function rejectRequest(Request $request, $id)
    {
        $req = SubscriptionRequest::findOrFail($id);
        $req->status = 'rejected';
        $req->admin_remark = $request->admin_remark ?? 'Rejected by Admin';
        $req->resolved_at = Carbon::now();
        $req->resolved_by = Auth::id();
        $req->save();

        return back()->with('success', "Request #{$req->id} rejected.");
    }
}
