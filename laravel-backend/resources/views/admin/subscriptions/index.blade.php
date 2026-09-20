@extends('admin.layouts.app')
@section('page_title', __('Merchant Subscriptions'))

@section('content')
<div class="content container-fluid">
    <!-- Page Header -->
    <div class="page-header pb-2 mb-3 border-bottom">
        <div class="row align-items-center">
            <div class="col-sm mb-2 mb-sm-0">
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb breadcrumb-no-gutter">
                        <li class="breadcrumb-item"><a class="breadcrumb-link" href="{{ route('admin.dashboard') }}">@lang('Dashboard')</a></li>
                        <li class="breadcrumb-item active" aria-current="page">@lang('Subscriptions')</li>
                    </ol>
                </nav>
                <h1 class="page-header-title">
                    <i class="bi bi-gem text-primary me-2"></i>@lang('Merchant Subscriptions & Plans')
                </h1>
                <p class="page-header-text mb-0">@lang('Track all merchant subscribers, active 7-day free trials, and manage account access.')</p>
            </div>
            <div class="col-sm-auto">
                <a href="{{ route('admin.subscriptions.plans') }}" class="btn btn-primary btn-sm">
                    <i class="bi bi-sliders me-1"></i> @lang('Manage Plans & Pricing')
                </a>
            </div>
        </div>
    </div>
    <!-- End Page Header -->

    <!-- Quick Stats Cards -->
    <div class="row mb-3 g-3">
        <div class="col-sm-6 col-lg-3">
            <div class="card card-hover-shadow h-100 border-start border-3 border-info">
                <div class="card-body">
                    <h6 class="card-subtitle text-muted mb-1">@lang('Total Merchants')</h6>
                    <div class="d-flex align-items-center justify-content-between">
                        <span class="card-title h2 text-dark mb-0">{{ number_format($stats['total_merchants']) }}</span>
                        <span class="avatar avatar-sm avatar-soft-info avatar-circle">
                            <i class="bi bi-people avatar-icon fs-5"></i>
                        </span>
                    </div>
                    <span class="text-muted fs-7">@lang('All registered store owners')</span>
                </div>
            </div>
        </div>

        <div class="col-sm-6 col-lg-3">
            <div class="card card-hover-shadow h-100 border-start border-3 border-primary">
                <div class="card-body">
                    <h6 class="card-subtitle text-muted mb-1">@lang('7-Day Free Trials')</h6>
                    <div class="d-flex align-items-center justify-content-between">
                        <span class="card-title h2 text-primary mb-0">{{ number_format($stats['trial_subscribers']) }}</span>
                        <span class="avatar avatar-sm avatar-soft-primary avatar-circle">
                            <i class="bi bi-lightning-charge avatar-icon fs-5"></i>
                        </span>
                    </div>
                    <a href="{{ route('admin.subscriptions.trials') }}" class="text-primary fs-7 fw-semibold">
                        @lang('View Active Trials') <i class="bi bi-arrow-right"></i>
                    </a>
                </div>
            </div>
        </div>

        <div class="col-sm-6 col-lg-3">
            <div class="card card-hover-shadow h-100 border-start border-3 border-success">
                <div class="card-body">
                    <h6 class="card-subtitle text-muted mb-1">@lang('Active Paid Subscribers')</h6>
                    <div class="d-flex align-items-center justify-content-between">
                        <span class="card-title h2 text-success mb-0">{{ number_format($stats['active_subscribers']) }}</span>
                        <span class="avatar avatar-sm avatar-soft-success avatar-circle">
                            <i class="bi bi-check-circle avatar-icon fs-5"></i>
                        </span>
                    </div>
                    <span class="text-muted fs-7">@lang('Premium') ({{ $stats['premium_count'] }}) • @lang('Gold') ({{ $stats['gold_count'] }})</span>
                </div>
            </div>
        </div>

        <div class="col-sm-6 col-lg-3">
            <div class="card card-hover-shadow h-100 border-start border-3 border-warning">
                <div class="card-body">
                    <h6 class="card-subtitle text-muted mb-1">@lang('Upgrade Requests')</h6>
                    <div class="d-flex align-items-center justify-content-between">
                        <span class="card-title h2 text-warning mb-0">{{ number_format($stats['pending_requests']) }}</span>
                        <span class="avatar avatar-sm avatar-soft-warning avatar-circle">
                            <i class="bi bi-hourglass-split avatar-icon fs-5"></i>
                        </span>
                    </div>
                    <a href="{{ route('admin.subscriptions.requests') }}" class="text-warning fs-7 fw-semibold">
                        @lang('Pending offline approvals') <i class="bi bi-arrow-right"></i>
                    </a>
                </div>
            </div>
        </div>
    </div>
    <!-- End Stats Cards -->

    <!-- Filter and Search Bar -->
    <div class="card mb-3">
        <div class="card-body p-3">
            <form action="{{ route('admin.subscriptions.index') }}" method="GET" class="row g-2 align-items-center">
                <div class="col-md-4">
                    <div class="input-group input-group-sm">
                        <span class="input-group-text"><i class="bi bi-search"></i></span>
                        <input type="text" name="search" class="form-control" placeholder="@lang('Search by name, phone, shop...')" value="{{ request('search') }}">
                    </div>
                </div>

                <div class="col-md-3">
                    <select name="plan" class="form-select form-select-sm">
                        <option value="all" {{ request('plan') == 'all' ? 'selected' : '' }}>@lang('All Plans')</option>
                        <option value="basic" {{ request('plan') == 'basic' ? 'selected' : '' }}>@lang('Basic Plan (Free)')</option>
                        <option value="premium" {{ request('plan') == 'premium' ? 'selected' : '' }}>@lang('Premium Plan (₹29)')</option>
                        <option value="gold" {{ request('plan') == 'gold' ? 'selected' : '' }}>@lang('Gold Plan (₹129)')</option>
                    </select>
                </div>

                <div class="col-md-3">
                    <select name="status" class="form-select form-select-sm">
                        <option value="all" {{ request('status') == 'all' ? 'selected' : '' }}>@lang('All Statuses')</option>
                        <option value="trial" {{ request('status') == 'trial' ? 'selected' : '' }}>@lang('7-Day Free Trial')</option>
                        <option value="active" {{ request('status') == 'active' ? 'selected' : '' }}>@lang('Active Paid')</option>
                        <option value="basic" {{ request('status') == 'basic' ? 'selected' : '' }}>@lang('Basic (Free Forever)')</option>
                        <option value="expired" {{ request('status') == 'expired' ? 'selected' : '' }}>@lang('Expired')</option>
                    </select>
                </div>

                <div class="col-md-2 d-flex gap-1">
                    <button type="submit" class="btn btn-primary btn-sm flex-fill">
                        <i class="bi bi-funnel me-1"></i> @lang('Filter')
                    </button>
                    <a href="{{ route('admin.subscriptions.index') }}" class="btn btn-outline-secondary btn-sm" title="@lang('Reset')">
                        <i class="bi bi-arrow-clockwise"></i>
                    </a>
                </div>
            </form>
        </div>
    </div>

    <!-- Subscribers Table Card -->
    <div class="card shadow-sm">
        <div class="card-header d-flex justify-content-between align-items-center py-3">
            <h5 class="card-header-title mb-0">
                <i class="bi bi-list-ul me-1"></i> @lang('Merchant Directory')
                <span class="badge bg-soft-secondary text-dark ms-2">{{ $merchants->total() }}</span>
            </h5>
        </div>

        <div class="table-responsive">
            <table class="table table-borderless table-thead-bordered table-nowrap table-align-middle card-table table-hover">
                <thead class="thead-light">
                    <tr>
                        <th>@lang('Merchant')</th>
                        <th>@lang('Phone & Shop')</th>
                        <th>@lang('Current Plan')</th>
                        <th>@lang('Status')</th>
                        <th>@lang('Billing Cycle')</th>
                        <th>@lang('Renewal / Trial Ends')</th>
                        <th class="text-end">@lang('Action')</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($merchants as $merchant)
                    @php
                        $sub = $merchant->activeSubscription;
                        $status = strtolower($merchant->subscription_status ?? ($sub ? $sub->status : 'basic'));
                        $planCode = $status === 'trial'
                            ? 'premium'
                            : strtolower($sub && $sub->plan ? $sub->plan->code : ($merchant->current_plan_code ?? 'basic'));
                        $renewsAt = $merchant->subscription_renews_at ?? ($sub ? ($sub->trial_ends_at ?? $sub->renews_at) : null);
                    @endphp
                    <tr>
                        <td>
                            <div class="d-flex align-items-center">
                                <div class="avatar avatar-sm avatar-circle me-2 bg-soft-primary text-primary fw-bold d-flex align-items-center justify-content-center">
                                    {{ strtoupper(substr($merchant->firstname ?? $merchant->username ?? 'M', 0, 1)) }}
                                </div>
                                <div>
                                    <span class="d-block h6 mb-0 text-dark">
                                        {{ trim(($merchant->firstname ?? '') . ' ' . ($merchant->lastname ?? '')) ?: $merchant->username }}
                                    </span>
                                    <small class="text-muted">{{ $merchant->email ?? 'No email' }}</small>
                                </div>
                            </div>
                        </td>
                        <td>
                            <span class="d-block fw-semibold text-dark">{{ $merchant->phone ?: 'N/A' }}</span>
                            <small class="text-muted">{{ $merchant->shop_name ?: $merchant->business_name ?: 'Individual Merchant' }}</small>
                        </td>
                        <td>
                            @if($planCode === 'gold')
                                <span class="badge bg-warning text-dark px-2 py-1">
                                    <i class="bi bi-speaker-fill me-1"></i> Gold Plan (₹129)
                                </span>
                            @elseif($planCode === 'premium')
                                <span class="badge bg-primary px-2 py-1">
                                    <i class="bi bi-mic-fill me-1"></i> Premium Plan (₹29)
                                </span>
                            @else
                                <span class="badge bg-soft-secondary text-secondary px-2 py-1">
                                    <i class="bi bi-card-checklist me-1"></i> Basic Plan (Free)
                                </span>
                            @endif
                        </td>
                        <td>
                            @if($status === 'trial')
                                @php
                                    $remaining = $renewsAt ? \Carbon\Carbon::now()->diffInDays(\Carbon\Carbon::parse($renewsAt), false) : 0;
                                @endphp
                                @if($remaining >= 0)
                                    <span class="badge bg-soft-primary text-primary px-2 py-1">
                                        <i class="bi bi-lightning-charge-fill me-1"></i> 7-Day Trial ({{ (int)$remaining }}d left)
                                    </span>
                                @else
                                    <span class="badge bg-soft-danger text-danger px-2 py-1">
                                        <i class="bi bi-clock-history me-1"></i> Trial Ended
                                    </span>
                                @endif
                            @elseif($status === 'active')
                                <span class="badge bg-soft-success text-success px-2 py-1">
                                    <i class="bi bi-check-circle-fill me-1"></i> Active Paid
                                </span>
                            @elseif($status === 'expired')
                                <span class="badge bg-soft-danger text-danger px-2 py-1">
                                    <i class="bi bi-x-circle me-1"></i> Expired
                                </span>
                            @else
                                <span class="badge bg-soft-dark text-dark px-2 py-1">
                                    Free Tier
                                </span>
                            @endif
                        </td>
                        <td>
                            @if($sub)
                                <span class="text-capitalize">{{ $sub->billing_cycle ?? 'Monthly' }}</span>
                            @else
                                <span class="text-muted">—</span>
                            @endif
                        </td>
                        <td>
                            @if($renewsAt)
                                <span class="d-block text-dark">{{ \Carbon\Carbon::parse($renewsAt)->format('d M, Y') }}</span>
                                <small class="text-muted">{{ \Carbon\Carbon::parse($renewsAt)->diffForHumans() }}</small>
                            @else
                                <span class="text-muted">Lifetime Free</span>
                            @endif
                        </td>
                        <td class="text-end">
                            <div class="btn-group">
                                <button type="button" class="btn btn-white btn-xs border" data-bs-toggle="modal" data-bs-target="#extendTrialModal{{ $merchant->id }}">
                                    <i class="bi bi-clock-history text-primary"></i> @lang('+Trial')
                                </button>
                                <button type="button" class="btn btn-white btn-xs border" data-bs-toggle="modal" data-bs-target="#assignPlanModal{{ $merchant->id }}">
                                    <i class="bi bi-pencil-square text-warning"></i> @lang('Plan')
                                </button>
                            </div>

                            <!-- Modal: Extend Trial -->
                            <div class="modal fade" id="extendTrialModal{{ $merchant->id }}" tabindex="-1" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered">
                                    <div class="modal-content text-start">
                                        <div class="modal-header">
                                            <h5 class="modal-title">
                                                <i class="bi bi-gift text-primary me-2"></i>@lang('Extend Free Trial')
                                            </h5>
                                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>
                                        <form action="{{ route('admin.subscriptions.extendTrial', $sub ? $sub->id : $merchant->id) }}" method="POST">
                                            @csrf
                                            <div class="modal-body">
                                                <p class="mb-3">
                                                    @lang('Grant free AI Voice Khata trial days to')
                                                    <strong>{{ $merchant->firstname ?? $merchant->username }}</strong> ({{ $merchant->phone }}).
                                                </p>
                                                <div class="mb-3">
                                                    <label class="form-label">@lang('Additional Trial Days')</label>
                                                    <select name="additional_days" class="form-select">
                                                        <option value="7" selected>+7 Days (1 Week)</option>
                                                        <option value="14">+14 Days (2 Weeks)</option>
                                                        <option value="30">+30 Days (1 Month)</option>
                                                        <option value="60">+60 Days (2 Months)</option>
                                                    </select>
                                                </div>
                                                <div class="mb-3">
                                                    <label class="form-label">@lang('Admin Note (Optional)')</label>
                                                    <input type="text" name="notes" class="form-control" placeholder="@lang('e.g. Courtesy promotional extension')">
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-white btn-sm" data-bs-dismiss="modal">@lang('Cancel')</button>
                                                <button type="submit" class="btn btn-primary btn-sm">@lang('Apply Extension')</button>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>

                            <!-- Modal: Assign Plan -->
                            <div class="modal fade" id="assignPlanModal{{ $merchant->id }}" tabindex="-1" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered">
                                    <div class="modal-content text-start">
                                        <div class="modal-header">
                                            <h5 class="modal-title">
                                                <i class="bi bi-shield-lock text-warning me-2"></i>@lang('Change / Assign Plan')
                                            </h5>
                                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>
                                        <form action="{{ route('admin.subscriptions.assignPlan') }}" method="POST">
                                            @csrf
                                            <input type="hidden" name="merchant_id" value="{{ $merchant->id }}">
                                            <div class="modal-body">
                                                <p class="mb-3">
                                                    @lang('Manually set subscription plan for')
                                                    <strong>{{ $merchant->firstname ?? $merchant->username }}</strong> ({{ $merchant->phone }}).
                                                </p>
                                                <div class="mb-3">
                                                    <label class="form-label">@lang('Target Plan')</label>
                                                    <select name="plan_id" class="form-select" required>
                                                        @foreach($plans as $p)
                                                            <option value="{{ $p->id }}" {{ $planCode === strtolower($p->code) ? 'selected' : '' }}>
                                                                {{ $p->name }} (Monthly: ₹{{ $p->monthly_price }} | Yearly: ₹{{ $p->yearly_price }})
                                                            </option>
                                                        @endforeach
                                                    </select>
                                                </div>
                                                <div class="row g-2 mb-3">
                                                    <div class="col-6">
                                                        <label class="form-label">@lang('Status')</label>
                                                        <select name="status" class="form-select">
                                                            <option value="active" {{ $status === 'active' ? 'selected' : '' }}>Active (Paid)</option>
                                                            <option value="trial" {{ $status === 'trial' ? 'selected' : '' }}>7-Day Free Trial</option>
                                                            <option value="basic" {{ $status === 'basic' ? 'selected' : '' }}>Basic (Free Forever)</option>
                                                            <option value="expired">Expired</option>
                                                        </select>
                                                    </div>
                                                    <div class="col-6">
                                                        <label class="form-label">@lang('Billing Cycle')</label>
                                                        <select name="billing_cycle" class="form-select">
                                                            <option value="monthly" selected>Monthly</option>
                                                            <option value="yearly">Yearly</option>
                                                        </select>
                                                    </div>
                                                </div>
                                                <div class="mb-3">
                                                    <label class="form-label">@lang('Duration (Months)')</label>
                                                    <input type="number" name="duration_months" class="form-control" value="1" min="1" max="36">
                                                    <small class="text-muted">@lang('Number of months to keep this plan active.')</small>
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-white btn-sm" data-bs-dismiss="modal">@lang('Cancel')</button>
                                                <button type="submit" class="btn btn-primary btn-sm">@lang('Update Plan')</button>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="7" class="text-center py-5 text-muted">
                            <i class="bi bi-inbox fs-1 d-block mb-2 text-secondary"></i>
                            @lang('No merchants match your filter criteria.')
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($merchants->hasPages())
        <div class="card-footer d-flex justify-content-between align-items-center py-2">
            <span class="text-muted small">
                Showing {{ $merchants->firstItem() ?? 0 }} to {{ $merchants->lastItem() ?? 0 }} of {{ $merchants->total() }} merchants
            </span>
            <div>
                {{ $merchants->links() }}
            </div>
        </div>
        @endif
    </div>
</div>
@endsection
