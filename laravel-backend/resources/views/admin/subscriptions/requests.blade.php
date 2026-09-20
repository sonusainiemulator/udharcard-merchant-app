@extends('admin.layouts.app')
@section('page_title', __('Upgrade Requests'))
@section('content')
<div class="content container-fluid">
    <div class="page-header pb-2 mb-3 border-bottom">
        <div class="row align-items-center">
            <div class="col-sm mb-2 mb-sm-0">
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb breadcrumb-no-gutter">
                        <li class="breadcrumb-item"><a href="{{ route('admin.dashboard') }}">Dashboard</a></li>
                        <li class="breadcrumb-item"><a href="{{ route('admin.subscriptions.index') }}">Subscriptions</a></li>
                        <li class="breadcrumb-item active">Upgrade Requests</li>
                    </ol>
                </nav>
                <h1 class="page-header-title">
                    <i class="bi bi-hourglass-split text-warning me-2"></i>@lang('Offline Upgrade Requests')
                </h1>
                <p class="page-header-text mb-0">@lang('Review and approve merchant requests to upgrade via offline bank/UPI payments.')</p>
            </div>
            <div class="col-sm-auto">
                <a href="{{ route('admin.subscriptions.index') }}" class="btn btn-outline-secondary btn-sm">
                    <i class="bi bi-arrow-left me-1"></i> @lang('All Subscribers')
                </a>
            </div>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-soft-success alert-dismissible fade show" role="alert">
            <i class="bi bi-check-circle me-1"></i> {{ session('success') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
    @endif
    @if(session('error'))
        <div class="alert alert-soft-danger alert-dismissible fade show" role="alert">
            <i class="bi bi-exclamation-triangle me-1"></i> {{ session('error') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
    @endif

    {{-- Status Filter Tabs --}}
    <div class="mb-3">
        <ul class="nav nav-pills nav-fill">
            @foreach(['all' => 'All', 'pending' => 'Pending', 'approved' => 'Approved', 'rejected' => 'Rejected'] as $key => $label)
            <li class="nav-item">
                <a class="nav-link {{ request('status', 'all') === $key ? 'active' : '' }}" href="{{ route('admin.subscriptions.requests', ['status' => $key]) }}">
                    {{ $label }}
                    @if($key === 'pending')
                        <span class="badge bg-warning text-dark ms-1">{{ $pendingCount ?? 0 }}</span>
                    @elseif($key === 'approved' && ($approvedCount ?? 0) > 0)
                        <span class="badge bg-success ms-1">{{ $approvedCount }}</span>
                    @elseif($key === 'rejected' && ($rejectedCount ?? 0) > 0)
                        <span class="badge bg-danger ms-1">{{ $rejectedCount }}</span>
                    @elseif($key === 'all' && ($allCount ?? 0) > 0)
                        <span class="badge bg-light text-dark border ms-1">{{ $allCount }}</span>
                    @endif
                </a>
            </li>
            @endforeach
        </ul>
    </div>

    {{-- Requests Table --}}
    <div class="card shadow-sm">
        <div class="table-responsive">
            <table class="table table-borderless table-thead-bordered table-nowrap table-align-middle card-table table-hover mb-0">
                <thead class="thead-light">
                    <tr>
                        <th>#</th>
                        <th>@lang('Merchant')</th>
                        <th>@lang('Requested Plan')</th>
                        <th>@lang('Billing')</th>
                        <th>@lang('Amount')</th>
                        <th>@lang('Status')</th>
                        <th>@lang('Requested At')</th>
                        <th class="text-end">@lang('Action')</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($requests as $req)
                    @php
                        $merchant = $req->merchant;
                        $plan = $req->plan;
                        $amount = $plan ? ($req->billing_cycle === 'yearly' ? $plan->yearly_price : $plan->monthly_price) : null;
                    @endphp
                    <tr>
                        <td>{{ $req->id }}</td>
                        <td>
                            @if($merchant)
                            <div>
                                <span class="d-block fw-semibold text-dark">
                                    {{ trim(($merchant->firstname ?? '') . ' ' . ($merchant->lastname ?? '')) ?: $merchant->username }}
                                </span>
                                <small class="text-muted">{{ $merchant->phone }}</small>
                            </div>
                            @else
                                <span class="text-muted">Unknown</span>
                            @endif
                        </td>
                        <td>
                            @if($plan)
                                <span class="badge bg-primary">{{ $plan->name }}</span>
                            @else
                                <code>{{ $req->requested_plan_code }}</code>
                            @endif
                        </td>
                        <td><span class="text-capitalize">{{ $req->billing_cycle ?? '—' }}</span></td>
                        <td>
                            @if($amount !== null)
                                <strong>₹{{ number_format($amount) }}</strong>
                            @else
                                <span class="text-muted">—</span>
                            @endif
                        </td>
                        <td>
                            @if($req->status === 'pending')
                                <span class="badge bg-soft-warning text-warning">
                                    <i class="bi bi-hourglass-split me-1"></i>Pending
                                </span>
                            @elseif($req->status === 'approved')
                                <span class="badge bg-soft-success text-success">
                                    <i class="bi bi-check-circle me-1"></i>Approved
                                </span>
                            @elseif($req->status === 'rejected')
                                <span class="badge bg-soft-danger text-danger">
                                    <i class="bi bi-x-circle me-1"></i>Rejected
                                </span>
                            @else
                                <span class="badge bg-secondary">{{ ucfirst($req->status) }}</span>
                            @endif
                        </td>
                        <td>
                            <span>{{ $req->created_at ? \Carbon\Carbon::parse($req->created_at)->format('d M, Y') : '—' }}</span>
                            <small class="text-muted d-block">{{ $req->created_at ? \Carbon\Carbon::parse($req->created_at)->format('h:i A') : '' }}</small>
                        </td>
                        <td class="text-end">
                            @if($req->status === 'pending')
                            <div class="btn-group">
                                <button type="button" class="btn btn-success btn-xs" data-bs-toggle="modal" data-bs-target="#approveModal{{ $req->id }}">
                                    <i class="bi bi-check me-1"></i>@lang('Approve')
                                </button>
                                <button type="button" class="btn btn-danger btn-xs" data-bs-toggle="modal" data-bs-target="#rejectModal{{ $req->id }}">
                                    <i class="bi bi-x me-1"></i>@lang('Reject')
                                </button>
                            </div>

                            {{-- Approve Modal --}}
                            <div class="modal fade" id="approveModal{{ $req->id }}" tabindex="-1" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered">
                                    <div class="modal-content text-start">
                                        <div class="modal-header">
                                            <h5 class="modal-title text-success">
                                                <i class="bi bi-check-circle me-2"></i>@lang('Approve Upgrade Request')
                                            </h5>
                                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                        </div>
                                        <form action="{{ route('admin.subscriptions.requests.approve', $req->id) }}" method="POST">
                                            @csrf
                                            <div class="modal-body">
                                                <p>
                                                    Approve upgrade for <strong>{{ $merchant->firstname ?? $merchant->username ?? 'Merchant' }}</strong>
                                                    to <strong>{{ $plan->name ?? $req->requested_plan_code }}</strong>
                                                    ({{ $req->billing_cycle }} billing)?
                                                </p>
                                                @if($amount)
                                                <p class="text-success fw-bold">Amount Received: ₹{{ number_format($amount) }}</p>
                                                @endif
                                                @if($req->note)
                                                <div class="alert alert-soft-info py-2">
                                                    <small><strong>Merchant Note:</strong> {{ $req->note }}</small>
                                                </div>
                                                @endif
                                                <div class="mb-2">
                                                    <label class="form-label">Admin Remark (Optional)</label>
                                                    <input type="text" name="admin_remark" class="form-control form-control-sm" value="Payment verified and confirmed" placeholder="Payment confirmed">
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-white btn-sm" data-bs-dismiss="modal">Cancel</button>
                                                <button type="submit" class="btn btn-success btn-sm">
                                                    <i class="bi bi-check me-1"></i> Approve & Activate Plan
                                                </button>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>

                            {{-- Reject Modal --}}
                            <div class="modal fade" id="rejectModal{{ $req->id }}" tabindex="-1" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered">
                                    <div class="modal-content text-start">
                                        <div class="modal-header">
                                            <h5 class="modal-title text-danger">
                                                <i class="bi bi-x-circle me-2"></i>@lang('Reject Request')
                                            </h5>
                                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                        </div>
                                        <form action="{{ route('admin.subscriptions.requests.reject', $req->id) }}" method="POST">
                                            @csrf
                                            <div class="modal-body">
                                                <p>Reject upgrade request from <strong>{{ $merchant->firstname ?? 'Merchant' }}</strong>?</p>
                                                <div class="mb-2">
                                                    <label class="form-label">Reason for Rejection</label>
                                                    <input type="text" name="admin_remark" class="form-control form-control-sm" placeholder="e.g. Payment not received, invalid proof">
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-white btn-sm" data-bs-dismiss="modal">Cancel</button>
                                                <button type="submit" class="btn btn-danger btn-sm">
                                                    <i class="bi bi-x me-1"></i> Reject Request
                                                </button>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>
                            @else
                                <span class="text-muted small">
                                    {{ $req->admin_remark ?? 'No remark' }}
                                </span>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="8" class="text-center py-5 text-muted">
                            <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                            No upgrade requests found for selected filter.
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($requests->hasPages())
        <div class="card-footer d-flex justify-content-between align-items-center py-2">
            <span class="text-muted small">
                Showing {{ $requests->firstItem() }} to {{ $requests->lastItem() }} of {{ $requests->total() }} requests
            </span>
            <div>{{ $requests->links() }}</div>
        </div>
        @endif
    </div>
</div>
@endsection
