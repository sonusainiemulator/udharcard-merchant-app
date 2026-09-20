@extends('admin.layouts.app')
@section('page_title', __('Subscription Details'))

@section('content')
<div class="content container-fluid">
    <div class="row justify-content-lg-center">
        <div class="col-lg-10 laptop-width">

            @include('admin.user_management.components.header_user_profile')

            {{-- Flash messages --}}
            @if(session('success'))
                <div class="alert alert-soft-success alert-dismissible fade show mb-3" role="alert">
                    <i class="bi bi-check-circle me-1"></i> {{ session('success') }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            @endif
            @if(session('error'))
                <div class="alert alert-soft-danger alert-dismissible fade show mb-3" role="alert">
                    <i class="bi bi-exclamation-triangle me-1"></i> {{ session('error') }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            @endif

            <div class="row g-4">

                {{-- LEFT: Plan Summary Card --}}
                <div class="col-lg-4">
                    <div class="card mb-4">
                        <div class="card-header card-header-content-between py-3">
                            <h5 class="card-header-title mb-0">
                                <i class="bi bi-gem text-primary me-1"></i> @lang('Current Plan')
                            </h5>
                        </div>
                        <div class="card-body">
                            @php
                                $activeSub = $activeSubscription ?? null;
                                $subStatus = strtolower($user->subscription_status ?? ($activeSub ? $activeSub->status : ''));
                                // Free trial in UdharCard is strictly for Premium Plan (AI Voice Khata)
                                $planCode = $subStatus === 'trial'
                                    ? 'premium'
                                    : strtolower($activeSub && $activeSub->plan ? $activeSub->plan->code : ($user->current_plan_code ?? 'basic'));
                                $renewsAt = $user->subscription_renews_at ?? ($activeSub ? ($activeSub->trial_ends_at ?? $activeSub->renews_at) : null);
                            @endphp

                            {{-- Plan Badge --}}
                            <div class="text-center mb-4">
                                @if($planCode === 'gold')
                                    <div class="avatar avatar-xl avatar-circle bg-soft-warning mx-auto mb-2">
                                        <i class="bi bi-speaker-fill fs-3 text-warning"></i>
                                    </div>
                                    <h4 class="mb-0 text-warning">Gold Plan</h4>
                                    <small class="text-muted">₹129/month • ₹1299/year</small>
                                @elseif($planCode === 'premium')
                                    <div class="avatar avatar-xl avatar-circle bg-soft-primary mx-auto mb-2">
                                        <i class="bi bi-mic-fill fs-3 text-primary"></i>
                                    </div>
                                    <h4 class="mb-0 text-primary">Premium Plan</h4>
                                    <small class="text-muted">₹29/month • ₹299/year</small>
                                @else
                                    <div class="avatar avatar-xl avatar-circle bg-soft-secondary mx-auto mb-2">
                                        <i class="bi bi-card-checklist fs-3 text-secondary"></i>
                                    </div>
                                    <h4 class="mb-0 text-secondary">Basic Plan</h4>
                                    <small class="text-muted">Free Forever</small>
                                @endif
                            </div>

                            {{-- Status --}}
                            <div class="mb-3 text-center">
                                @if($subStatus === 'trial')
                                    @php $daysLeft = $renewsAt ? \Carbon\Carbon::now()->diffInDays(\Carbon\Carbon::parse($renewsAt), false) : 0; @endphp
                                    <span class="badge bg-soft-primary text-primary px-3 py-2">
                                        <i class="bi bi-lightning-charge-fill me-1"></i> 7-Day Free Trial Active
                                        ({{ (int)max(0, $daysLeft) }} days left)
                                    </span>
                                @elseif($subStatus === 'active')
                                    <span class="badge bg-soft-success text-success px-3 py-2">
                                        <i class="bi bi-check-circle-fill me-1"></i> Active Paid Subscriber
                                    </span>
                                @elseif($subStatus === 'expired')
                                    <span class="badge bg-soft-danger text-danger px-3 py-2">
                                        <i class="bi bi-x-circle me-1"></i> Subscription Expired
                                    </span>
                                @else
                                    <span class="badge bg-soft-secondary text-secondary px-3 py-2">
                                        <i class="bi bi-person me-1"></i> Free Tier (No Subscription)
                                    </span>
                                @endif
                            </div>

                            {{-- Plan Details List --}}
                            <ul class="list-unstyled list-py-2 text-dark mb-0 border-top pt-3">
                                <li class="d-flex justify-content-between">
                                    <span class="text-muted small">@lang('Plan Code')</span>
                                    <span class="fw-semibold text-uppercase">{{ $planCode ?: 'basic' }}</span>
                                </li>
                                @if($renewsAt)
                                <li class="d-flex justify-content-between mt-2">
                                    <span class="text-muted small">
                                        {{ $subStatus === 'trial' ? __('Trial Ends') : __('Renews At') }}
                                    </span>
                                    <span class="fw-semibold">{{ \Carbon\Carbon::parse($renewsAt)->format('d M, Y') }}</span>
                                </li>
                                @endif
                                @if($activeSub)
                                <li class="d-flex justify-content-between mt-2">
                                    <span class="text-muted small">@lang('Billing Cycle')</span>
                                    <span class="fw-semibold text-capitalize">{{ $activeSub->billing_cycle ?? '—' }}</span>
                                </li>
                                <li class="d-flex justify-content-between mt-2">
                                    <span class="text-muted small">@lang('Started On')</span>
                                    <span class="fw-semibold">{{ $activeSub->started_at ? \Carbon\Carbon::parse($activeSub->started_at)->format('d M, Y') : '—' }}</span>
                                </li>
                                @endif
                            </ul>

                            {{-- Feature Flags --}}
                            @if($activeSub && $activeSub->plan && $activeSub->plan->feature_flags)
                            @php $flags = $activeSub->plan->feature_flags; @endphp
                            <div class="border-top mt-3 pt-3">
                                <p class="small text-muted mb-2">@lang('Active Features')</p>
                                <ul class="list-unstyled mb-0">
                                    <li class="small mb-1">
                                        <i class="bi {{ $flags['has_voice_entry'] ?? false ? 'bi-check-circle-fill text-success' : 'bi-x-circle-fill text-muted' }} me-1"></i>
                                        AI Voice Khata Entry
                                    </li>
                                    <li class="small mb-1">
                                        <i class="bi {{ $flags['has_soundbox'] ?? false ? 'bi-check-circle-fill text-success' : 'bi-x-circle-fill text-muted' }} me-1"></i>
                                        UdharCard Soundbox Device
                                    </li>
                                    <li class="small mb-1">
                                        <i class="bi {{ $flags['has_desktop_access'] ?? true ? 'bi-check-circle-fill text-success' : 'bi-x-circle-fill text-muted' }} me-1"></i>
                                        Desktop Access
                                    </li>
                                    <li class="small mb-1">
                                        <i class="bi {{ $flags['pdf_bill_access'] ?? true ? 'bi-check-circle-fill text-success' : 'bi-x-circle-fill text-muted' }} me-1"></i>
                                        PDF Bill Generation
                                    </li>
                                </ul>
                            </div>
                            @endif
                        </div>
                    </div>

                    {{-- Admin Actions Card --}}
                    <div class="card mb-4">
                        <div class="card-header py-3">
                            <h5 class="card-header-title mb-0">
                                <i class="bi bi-shield-lock text-warning me-1"></i> @lang('Admin Actions')
                            </h5>
                        </div>
                        <div class="card-body">
                            {{-- Extend Trial --}}
                            <button type="button" class="btn btn-primary btn-sm w-100 mb-2" data-bs-toggle="modal" data-bs-target="#extendTrialModal">
                                <i class="bi bi-gift me-1"></i> @lang('Give Free Trial Days')
                            </button>

                            {{-- Change Plan --}}
                            <button type="button" class="btn btn-outline-warning btn-sm w-100" data-bs-toggle="modal" data-bs-target="#changePlanModal">
                                <i class="bi bi-arrow-left-right me-1"></i> @lang('Change / Assign Plan')
                            </button>
                        </div>
                    </div>
                </div>

                {{-- RIGHT: Subscription History Table --}}
                <div class="col-lg-8">
                    <div class="card shadow-sm">
                        <div class="card-header card-header-content-between py-3">
                            <h5 class="card-header-title mb-0">
                                <i class="bi bi-clock-history me-1 text-info"></i> @lang('Subscription History')
                            </h5>
                            <span class="badge bg-soft-info text-info">{{ $subscriptions->count() }} @lang('records')</span>
                        </div>

                        @if($subscriptions->isEmpty())
                        <div class="card-body text-center py-5">
                            <div class="avatar avatar-xxl avatar-circle bg-soft-secondary mx-auto mb-3">
                                <i class="bi bi-gem fs-1 text-muted"></i>
                            </div>
                            <h5 class="text-muted">@lang('No Subscription Records')</h5>
                            <p class="text-muted small">@lang('This merchant is on the free Basic plan. No paid subscription history found.')</p>
                            <button type="button" class="btn btn-primary btn-sm mt-2" data-bs-toggle="modal" data-bs-target="#extendTrialModal">
                                <i class="bi bi-gift me-1"></i> @lang('Start a Free Trial for this Merchant')
                            </button>
                        </div>
                        @else
                        <div class="table-responsive">
                            <table class="table table-borderless table-thead-bordered table-nowrap table-align-middle card-table table-hover mb-0">
                                <thead class="thead-light">
                                    <tr>
                                        <th>#</th>
                                        <th>@lang('Plan')</th>
                                        <th>@lang('Status')</th>
                                        <th>@lang('Billing')</th>
                                        <th>@lang('Started')</th>
                                        <th>@lang('Expires / Trial Ends')</th>
                                        <th>@lang('Payment')</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($subscriptions as $sub)
                                    @php
                                        $plan = $sub->plan;
                                        $planName = $plan ? $plan->name : 'Unknown Plan';
                                        $planCode = $plan ? strtolower($plan->code) : 'basic';
                                        $expiry = $sub->trial_ends_at ?? $sub->renews_at;
                                        $isActive = in_array($sub->status, ['active', 'trial']);
                                    @endphp
                                    <tr class="{{ $isActive ? 'table-active' : '' }}">
                                        <td>
                                            <span class="text-muted">{{ $loop->iteration }}</span>
                                            @if($isActive)
                                                <span class="badge bg-success rounded-pill ms-1" title="Current Active Subscription">●</span>
                                            @endif
                                        </td>
                                        <td>
                                            @if($planCode === 'gold')
                                                <span class="badge bg-warning text-dark">
                                                    <i class="bi bi-speaker-fill me-1"></i>{{ $planName }}
                                                </span>
                                            @elseif($planCode === 'premium')
                                                <span class="badge bg-primary">
                                                    <i class="bi bi-mic-fill me-1"></i>{{ $planName }}
                                                </span>
                                            @else
                                                <span class="badge bg-secondary">{{ $planName }}</span>
                                            @endif
                                        </td>
                                        <td>
                                            @if($sub->status === 'trial')
                                                <span class="badge bg-soft-primary text-primary">
                                                    <i class="bi bi-lightning-charge-fill me-1"></i>Free Trial
                                                </span>
                                            @elseif($sub->status === 'active')
                                                <span class="badge bg-soft-success text-success">
                                                    <i class="bi bi-check-circle-fill me-1"></i>Active
                                                </span>
                                            @elseif($sub->status === 'expired')
                                                <span class="badge bg-soft-danger text-danger">Expired</span>
                                            @elseif($sub->status === 'cancelled')
                                                <span class="badge bg-soft-warning text-warning">Cancelled</span>
                                            @else
                                                <span class="badge bg-soft-secondary text-secondary">{{ ucfirst($sub->status) }}</span>
                                            @endif
                                        </td>
                                        <td>
                                            <span class="text-capitalize">{{ $sub->billing_cycle ?? '—' }}</span>
                                        </td>
                                        <td>
                                            <span class="d-block text-dark">
                                                {{ $sub->started_at ? \Carbon\Carbon::parse($sub->started_at)->format('d M, Y') : '—' }}
                                            </span>
                                        </td>
                                        <td>
                                            @if($expiry)
                                                @php $expired = \Carbon\Carbon::parse($expiry)->isPast(); @endphp
                                                <span class="d-block {{ $expired ? 'text-danger' : 'text-success fw-semibold' }}">
                                                    {{ \Carbon\Carbon::parse($expiry)->format('d M, Y') }}
                                                </span>
                                                <small class="text-muted">{{ \Carbon\Carbon::parse($expiry)->diffForHumans() }}</small>
                                            @else
                                                <span class="text-muted">—</span>
                                            @endif
                                        </td>
                                        <td>
                                            @if($sub->last_payment_at)
                                                <small class="text-success">
                                                    <i class="bi bi-cash-coin me-1"></i>
                                                    {{ \Carbon\Carbon::parse($sub->last_payment_at)->format('d M, Y') }}
                                                </small>
                                            @elseif($sub->status === 'trial')
                                                <small class="text-primary">Free Trial</small>
                                            @else
                                                <small class="text-muted">No payment</small>
                                            @endif
                                        </td>
                                    </tr>

                                    {{-- Show extended trial meta --}}
                                    @if($sub->meta && ($sub->meta['trial_extended'] ?? false))
                                    <tr class="bg-soft-primary">
                                        <td colspan="7" class="py-1 ps-4 small text-primary">
                                            <i class="bi bi-info-circle me-1"></i>
                                            Trial extended by admin
                                            @if(isset($sub->meta['extended_days'])) (+{{ $sub->meta['extended_days'] }} days) @endif
                                            @if(isset($sub->meta['admin_notes']) && $sub->meta['admin_notes']) — "{{ $sub->meta['admin_notes'] }}" @endif
                                            @if(isset($sub->meta['extended_at'])) on {{ \Carbon\Carbon::parse($sub->meta['extended_at'])->format('d M, Y') }} @endif
                                        </td>
                                    </tr>
                                    @endif
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                        @endif
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

{{-- Modal: Extend Free Trial --}}
<div class="modal fade" id="extendTrialModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">
                    <i class="bi bi-gift text-primary me-2"></i>@lang('Give Free Trial Days')
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form action="{{ route('admin.subscriptions.extendTrial', $activeSubscription ? $activeSubscription->id : $user->id) }}" method="POST">
                @csrf
                <div class="modal-body">
                    <p class="mb-3">
                        @lang('Grant free AI Voice Khata trial days to')
                        <strong>{{ $user->firstname ?? $user->username }}</strong> ({{ $user->phone }}).
                    </p>
                    @if($activeSubscription && $activeSubscription->trial_ends_at)
                    <div class="alert alert-soft-info py-2 mb-3">
                        <i class="bi bi-info-circle me-1"></i>
                        Current trial ends: <strong>{{ \Carbon\Carbon::parse($activeSubscription->trial_ends_at)->format('d M, Y') }}</strong>
                        ({{ \Carbon\Carbon::parse($activeSubscription->trial_ends_at)->diffForHumans() }}).
                        Extension will be added on top of this.
                    </div>
                    @endif
                    <div class="mb-3">
                        <label class="form-label fw-semibold">@lang('Additional Trial Days')</label>
                        <select name="additional_days" class="form-select">
                            <option value="7" selected>+7 Days — 1 Week Free Trial</option>
                            <option value="14">+14 Days — 2 Weeks Free Trial</option>
                            <option value="30">+30 Days — 1 Month Free Trial</option>
                            <option value="60">+60 Days — 2 Months Free Trial</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">@lang('Admin Note (Optional)')</label>
                        <input type="text" name="notes" class="form-control" placeholder="e.g. VIP merchant, promotional extension, onboarding support">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-white btn-sm" data-bs-dismiss="modal">@lang('Cancel')</button>
                    <button type="submit" class="btn btn-primary btn-sm">
                        <i class="bi bi-gift me-1"></i> @lang('Apply Free Trial Extension')
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

{{-- Modal: Change / Assign Plan --}}
@php $plans = \App\Models\SubscriptionPlan::orderBy('sort_order', 'asc')->get(); @endphp
<div class="modal fade" id="changePlanModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">
                    <i class="bi bi-shield-lock text-warning me-2"></i>@lang('Change / Assign Plan')
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form action="{{ route('admin.subscriptions.assignPlan') }}" method="POST">
                @csrf
                <input type="hidden" name="merchant_id" value="{{ $user->id }}">
                <div class="modal-body">
                    <p class="mb-3">
                        @lang('Manually set subscription plan for')
                        <strong>{{ $user->firstname ?? $user->username }}</strong> ({{ $user->phone }}).
                        <br>
                        <small class="text-muted">@lang('Current plan:') <strong>{{ ucfirst($planCode) }}</strong></small>
                    </p>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">@lang('Target Plan')</label>
                        <select name="plan_id" class="form-select" required>
                            @foreach($plans as $p)
                                <option value="{{ $p->id }}" {{ strtolower($planCode) === strtolower($p->code) ? 'selected' : '' }}>
                                    {{ $p->name }} — ₹{{ $p->monthly_price }}/month | ₹{{ $p->yearly_price }}/year
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-6">
                            <label class="form-label fw-semibold">@lang('Subscription Status')</label>
                            <select name="status" class="form-select">
                                <option value="active" {{ $subStatus === 'active' ? 'selected' : '' }}>Active (Paid)</option>
                                <option value="trial" {{ $subStatus === 'trial' ? 'selected' : '' }}>7-Day Free Trial</option>
                                <option value="basic" {{ in_array($subStatus, ['', 'basic', null]) ? 'selected' : '' }}>Basic (Free Forever)</option>
                                <option value="expired" {{ $subStatus === 'expired' ? 'selected' : '' }}>Expired</option>
                            </select>
                        </div>
                        <div class="col-6">
                            <label class="form-label fw-semibold">@lang('Billing Cycle')</label>
                            <select name="billing_cycle" class="form-select">
                                <option value="monthly" selected>Monthly</option>
                                <option value="yearly">Yearly</option>
                            </select>
                        </div>
                    </div>

                    <div class="mb-2">
                        <label class="form-label fw-semibold">@lang('Duration (Months)')</label>
                        <input type="number" name="duration_months" class="form-control" value="1" min="1" max="36">
                        <small class="text-muted">@lang('How many months should this plan remain active?')</small>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-white btn-sm" data-bs-dismiss="modal">@lang('Cancel')</button>
                    <button type="submit" class="btn btn-warning btn-sm">
                        <i class="bi bi-arrow-left-right me-1"></i> @lang('Update Plan')
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@include('admin.user_management.components.login_as_user')
@include('admin.user_management.components.update_balance_modal')
@include('admin.user_management.components.block_profile_modal')

@endsection
