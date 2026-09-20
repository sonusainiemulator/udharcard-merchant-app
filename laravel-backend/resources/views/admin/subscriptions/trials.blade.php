@extends('admin.layouts.app')
@section('page_title', __('7-Day Free Trials'))

@section('content')
<div class="content container-fluid">
    <!-- Page Header -->
    <div class="page-header pb-2 mb-3 border-bottom">
        <div class="row align-items-center">
            <div class="col-sm mb-2 mb-sm-0">
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb breadcrumb-no-gutter">
                        <li class="breadcrumb-item"><a class="breadcrumb-link" href="{{ route('admin.dashboard') }}">@lang('Dashboard')</a></li>
                        <li class="breadcrumb-item"><a class="breadcrumb-link" href="{{ route('admin.subscriptions.index') }}">@lang('Subscriptions')</a></li>
                        <li class="breadcrumb-item active" aria-current="page">@lang('Free Trials')</li>
                    </ol>
                </nav>
                <h1 class="page-header-title">
                    <i class="bi bi-lightning-charge text-warning me-2"></i>@lang('7-Day Free Trial Merchants')
                </h1>
                <p class="page-header-text mb-0">@lang('Monitor merchants experiencing AI Voice Khata on the 7-day trial and extend trials with 1 click.')</p>
            </div>
            <div class="col-sm-auto">
                <a href="{{ route('admin.subscriptions.index') }}" class="btn btn-outline-secondary btn-sm">
                    <i class="bi bi-arrow-left me-1"></i> @lang('All Subscribers')
                </a>
            </div>
        </div>
    </div>
    <!-- End Page Header -->

    <!-- Trial Stats Row -->
    <div class="row mb-3 g-3">
        <div class="col-sm-4">
            <div class="card h-100 border-start border-3 border-info">
                <div class="card-body">
                    <h6 class="card-subtitle text-muted mb-1">@lang('Active Free Trials')</h6>
                    <span class="card-title h2 text-info mb-0">{{ number_format($trialStats['active_trials'] ?? 0) }}</span>
                </div>
            </div>
        </div>
        <div class="col-sm-4">
            <div class="card h-100 border-start border-3 border-danger">
                <div class="card-body">
                    <h6 class="card-subtitle text-muted mb-1">@lang('Expiring Today')</h6>
                    <span class="card-title h2 text-danger mb-0">{{ number_format($trialStats['expiring_today'] ?? 0) }}</span>
                </div>
            </div>
        </div>
        <div class="col-sm-4">
            <div class="card h-100 border-start border-3 border-success">
                <div class="card-body">
                    <h6 class="card-subtitle text-muted mb-1">@lang('Extended by Admin')</h6>
                    <span class="card-title h2 text-success mb-0">{{ number_format($trialStats['extended_trials'] ?? 0) }}</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Search Form -->
    <div class="card mb-3">
        <div class="card-body p-3">
            <form action="{{ route('admin.subscriptions.trials') }}" method="GET" class="row g-2 align-items-center">
                <div class="col-md-9">
                    <div class="input-group input-group-sm">
                        <span class="input-group-text"><i class="bi bi-search"></i></span>
                        <input type="text" name="search" class="form-control" placeholder="@lang('Search trial merchants by name, phone, shop...')" value="{{ request('search') }}">
                    </div>
                </div>
                <div class="col-md-3 d-flex gap-1">
                    <button type="submit" class="btn btn-primary btn-sm flex-fill">@lang('Search Trials')</button>
                    <a href="{{ route('admin.subscriptions.trials') }}" class="btn btn-outline-secondary btn-sm"><i class="bi bi-arrow-clockwise"></i></a>
                </div>
            </form>
        </div>
    </div>

    <!-- Trials Table -->
    <div class="card shadow-sm">
        <div class="table-responsive">
            <table class="table table-borderless table-thead-bordered table-nowrap table-align-middle card-table table-hover">
                <thead class="thead-light">
                    <tr>
                        <th>@lang('Merchant')</th>
                        <th>@lang('Phone & Store')</th>
                        <th>@lang('Trial Plan')</th>
                        <th>@lang('Started On')</th>
                        <th>@lang('Trial Expiry')</th>
                        <th>@lang('Remaining Time')</th>
                        <th class="text-end">@lang('Actions')</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($trials as $t)
                    @php
                        $merchant = $t->merchant;
                        $trialEnds = $t->trial_ends_at ? \Carbon\Carbon::parse($t->trial_ends_at) : null;
                        $daysLeft = $trialEnds ? \Carbon\Carbon::now()->diffInDays($trialEnds, false) : 0;
                    @endphp
                    <tr>
                        <td>
                            <div class="d-flex align-items-center">
                                <div class="avatar avatar-sm avatar-circle me-2 bg-soft-info text-info fw-bold d-flex align-items-center justify-content-center">
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
                            <span class="d-block text-dark fw-semibold">{{ $merchant->phone }}</span>
                            <small class="text-muted">{{ $merchant->shop_name ?: 'Merchant Shop' }}</small>
                        </td>
                        <td>
                            <span class="badge bg-primary px-2 py-1">
                                <i class="bi bi-mic-fill me-1"></i> {{ $t->plan->name ?? 'Premium Plan' }}
                            </span>
                        </td>
                        <td>
                            {{ $t->started_at ? \Carbon\Carbon::parse($t->started_at)->format('d M, Y') : 'N/A' }}
                        </td>
                        <td>
                            <strong>{{ $trialEnds ? $trialEnds->format('d M, Y (h:i A)') : 'N/A' }}</strong>
                        </td>
                        <td>
                            @if($daysLeft > 0)
                                <span class="badge bg-soft-success text-success px-2 py-1">
                                    <i class="bi bi-hourglass-split me-1"></i> {{ (int)$daysLeft }} days left
                                </span>
                            @elseif($daysLeft == 0 && $trialEnds && $trialEnds->isFuture())
                                <span class="badge bg-soft-warning text-warning px-2 py-1">
                                    <i class="bi bi-exclamation-circle me-1"></i> Ends Today
                                </span>
                            @else
                                <span class="badge bg-soft-danger text-danger px-2 py-1">
                                    <i class="bi bi-x-circle me-1"></i> Expired
                                </span>
                            @endif
                        </td>
                        <td class="text-end">
                            <button type="button" class="btn btn-primary btn-xs" data-bs-toggle="modal" data-bs-target="#trialExtendModal{{ $t->id }}">
                                <i class="bi bi-plus-circle me-1"></i> @lang('+7 Days Trial')
                            </button>

                            <!-- Modal: Extend Trial -->
                            <div class="modal fade" id="trialExtendModal{{ $t->id }}" tabindex="-1" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered">
                                    <div class="modal-content text-start">
                                        <div class="modal-header">
                                            <h5 class="modal-title">
                                                <i class="bi bi-gift text-primary me-2"></i>@lang('Extend Free Trial')
                                            </h5>
                                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>
                                        <form action="{{ route('admin.subscriptions.extendTrial', $t->id) }}" method="POST">
                                            @csrf
                                            <div class="modal-body">
                                                <p>
                                                    @lang('Add extra free days for')
                                                    <strong>{{ $merchant->firstname ?? $merchant->username }}</strong> ({{ $merchant->phone }}).
                                                </p>
                                                <div class="mb-3">
                                                    <label class="form-label">@lang('Additional Days')</label>
                                                    <select name="additional_days" class="form-select">
                                                        <option value="7" selected>+7 Days (1 Week)</option>
                                                        <option value="14">+14 Days (2 Weeks)</option>
                                                        <option value="30">+30 Days (1 Month)</option>
                                                    </select>
                                                </div>
                                                <div class="mb-3">
                                                    <label class="form-label">@lang('Reason / Admin Note')</label>
                                                    <input type="text" name="notes" class="form-control" placeholder="@lang('e.g. VIP merchant trial bonus')">
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-white btn-sm" data-bs-dismiss="modal">@lang('Cancel')</button>
                                                <button type="submit" class="btn btn-primary btn-sm">@lang('Confirm Extension')</button>
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
                            <i class="bi bi-lightning-charge fs-1 d-block mb-2 text-secondary"></i>
                            @lang('No merchants currently on free trial.')
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($trials->hasPages())
        <div class="card-footer d-flex justify-content-between align-items-center py-2">
            <span class="text-muted small">Showing {{ $trials->firstItem() }} to {{ $trials->lastItem() }} of {{ $trials->total() }}</span>
            <div>{{ $trials->links() }}</div>
        </div>
        @endif
    </div>
</div>
@endsection
