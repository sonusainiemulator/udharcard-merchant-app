@extends('admin.layouts.app')
@section('page_title', __('Plans & Pricing'))
@section('content')
<div class="content container-fluid">
    <div class="page-header pb-2 mb-3 border-bottom">
        <div class="row align-items-center">
            <div class="col-sm mb-2 mb-sm-0">
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb breadcrumb-no-gutter">
                        <li class="breadcrumb-item"><a href="{{ route('admin.dashboard') }}">@lang('Dashboard')</a></li>
                        <li class="breadcrumb-item"><a href="{{ route('admin.subscriptions.index') }}">@lang('Subscriptions')</a></li>
                        <li class="breadcrumb-item active">@lang('Plans & Pricing')</li>
                    </ol>
                </nav>
                <h1 class="page-header-title">
                    <i class="bi bi-sliders text-primary me-2"></i>@lang('Plans & Pricing Control')
                </h1>
                <p class="page-header-text mb-0">@lang('Edit plan names, pricing (monthly/yearly), features, trial days, and voice prompts.')</p>
            </div>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-soft-success alert-dismissible fade show" role="alert">
            <i class="bi bi-check-circle me-1"></i> {{ session('success') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
    @endif

    <div class="row g-4">
        @foreach($plans as $plan)
        @php
            $isBasic = strtolower($plan->code) === 'basic';
            $isPremium = strtolower($plan->code) === 'premium';
            $isGold = strtolower($plan->code) === 'gold';
            $cardBorder = $isGold ? 'warning' : ($isPremium ? 'primary' : 'secondary');
        @endphp
        <div class="col-lg-4">
            <div class="card shadow-sm border-top border-{{ $cardBorder }} border-4">
                <div class="card-header card-header-content-between py-3">
                    <div>
                        <h5 class="card-header-title mb-0">
                            @if($isGold)
                                <i class="bi bi-speaker-fill text-warning me-1"></i>
                            @elseif($isPremium)
                                <i class="bi bi-mic-fill text-primary me-1"></i>
                            @else
                                <i class="bi bi-card-checklist text-secondary me-1"></i>
                            @endif
                            {{ $plan->name }}
                        </h5>
                        <small class="text-muted">Code: <code>{{ $plan->code }}</code></small>
                    </div>
                    <div class="d-flex gap-2 align-items-center">
                        @if($plan->is_active)
                            <span class="badge bg-soft-success text-success">Active</span>
                        @else
                            <span class="badge bg-soft-danger text-danger">Inactive</span>
                        @endif
                        <div class="text-end">
                            <div class="small text-muted">
                                <i class="bi bi-people me-1"></i>{{ $plan->active_subscribers_count ?? 0 }} active
                                | <i class="bi bi-lightning-charge me-1"></i>{{ $plan->trial_subscribers_count ?? 0 }} trial
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card-body">
                    <form action="{{ route('admin.subscriptions.plans.update', $plan->id) }}" method="POST">
                        @csrf
                        @method('POST')

                        <div class="row g-2 mb-3">
                            <div class="col-12">
                                <label class="form-label form-label-sm fw-semibold">@lang('Plan Name')</label>
                                <input type="text" name="name" class="form-control form-control-sm" value="{{ $plan->name }}" required>
                            </div>
                            <div class="col-6">
                                <label class="form-label form-label-sm fw-semibold">@lang('Tag Label')</label>
                                <input type="text" name="tag" class="form-control form-control-sm" value="{{ $plan->tag }}" placeholder="e.g. MOST POPULAR">
                            </div>
                            <div class="col-6">
                                <label class="form-label form-label-sm fw-semibold">@lang('Badge Text')</label>
                                <input type="text" name="badge" class="form-control form-control-sm" value="{{ $plan->badge }}" placeholder="e.g. VOICE">
                            </div>
                        </div>

                        <div class="row g-2 mb-3">
                            <div class="col-6">
                                <label class="form-label form-label-sm fw-semibold">@lang('Monthly Price (₹)')</label>
                                <div class="input-group input-group-sm">
                                    <span class="input-group-text">₹</span>
                                    <input type="number" name="monthly_price" class="form-control" value="{{ $plan->monthly_price }}" min="0" step="1">
                                </div>
                            </div>
                            <div class="col-6">
                                <label class="form-label form-label-sm fw-semibold">@lang('Yearly Price (₹)')</label>
                                <div class="input-group input-group-sm">
                                    <span class="input-group-text">₹</span>
                                    <input type="number" name="yearly_price" class="form-control" value="{{ $plan->yearly_price }}" min="0" step="1">
                                </div>
                            </div>
                        </div>

                        <div class="mb-3">
                            <label class="form-label form-label-sm fw-semibold">@lang('Free Trial Days')</label>
                            <div class="input-group input-group-sm">
                                <input type="number" name="trial_days" class="form-control" value="{{ $plan->trial_days }}" min="0" max="365">
                                <span class="input-group-text">days</span>
                            </div>
                            <small class="text-muted">Set 0 to disable free trial for this plan.</small>
                        </div>

                        <div class="mb-3">
                            <label class="form-label form-label-sm fw-semibold">@lang('Subtitle / Description')</label>
                            <textarea name="subtitle" class="form-control form-control-sm" rows="2">{{ $plan->subtitle }}</textarea>
                        </div>

                        <div class="mb-3">
                            <label class="form-label form-label-sm fw-semibold">
                                @lang('Features List')
                                <small class="text-muted fw-normal">(one per line)</small>
                            </label>
                            <textarea name="features" class="form-control form-control-sm" rows="5" placeholder="Manually add customer credit entries&#10;Track outstanding balances&#10;Access from mobile or desktop">{{ is_array($plan->features) ? implode("\n", $plan->features) : $plan->features }}</textarea>
                        </div>

                        @if(!$isBasic)
                        <div class="mb-3">
                            <label class="form-label form-label-sm fw-semibold">
                                @lang('Sample Voice Prompts')
                                <small class="text-muted fw-normal">(one per line — shown in app)</small>
                            </label>
                            <textarea name="sample_prompts" class="form-control form-control-sm" rows="3" placeholder="How much is pending from Ram?&#10;Add ₹500 credit to Mohan">{{ is_array($plan->sample_prompts) ? implode("\n", $plan->sample_prompts) : $plan->sample_prompts }}</textarea>
                        </div>
                        @endif

                        <div class="d-flex gap-2 mt-3">
                            <button type="submit" class="btn btn-{{ $cardBorder === 'secondary' ? 'secondary' : $cardBorder }} btn-sm flex-fill">
                                <i class="bi bi-save me-1"></i> @lang('Save Changes')
                            </button>
                            <form action="{{ route('admin.subscriptions.plans.toggle', $plan->id) }}" method="POST" class="mb-0">
                                @csrf
                                <button type="submit" class="btn btn-{{ $plan->is_active ? 'outline-danger' : 'outline-success' }} btn-sm" title="{{ $plan->is_active ? 'Deactivate Plan' : 'Activate Plan' }}">
                                    <i class="bi bi-{{ $plan->is_active ? 'eye-slash' : 'eye' }}"></i>
                                </button>
                            </form>
                        </div>
                    </form>
                </div>

                <div class="card-footer py-2 bg-soft-light">
                    <small class="text-muted">
                        Last updated: {{ $plan->updated_at ? \Carbon\Carbon::parse($plan->updated_at)->diffForHumans() : 'Never' }}
                    </small>
                </div>
            </div>
        </div>
        @endforeach
    </div>
</div>
@endsection
