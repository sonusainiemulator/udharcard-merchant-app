@extends('admin.layouts.app')
@section('page_title', __('Newsletter Subscribers'))
@section('content')
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row align-items-end">
                <div class="col-sm mb-2 mb-sm-0">
                    <nav aria-label="breadcrumb">
                        <ol class="breadcrumb breadcrumb-no-gutter">
                            <li class="breadcrumb-item">
                                <a class="breadcrumb-link" href="{{ route('admin.dashboard') }}">@lang('Dashboard')</a>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">@lang('Newsletter Subscribers')</li>
                        </ol>
                    </nav>
                    <h1 class="page-header-title d-flex align-items-center gap-2">
                        <span>@lang('Newsletter Subscribers')</span>
                        <span class="badge bg-soft-primary text-primary fs-6">{{ $subscriber->total() }}</span>
                    </h1>
                </div>
                <div class="col-sm-auto d-flex align-items-center gap-2">
                    <a href="{{ route('admin.subscriptions.index') }}" class="btn btn-sm btn-soft-primary">
                        <i class="bi bi-patch-check-fill me-1"></i> @lang('Merchant Plan Subscribers')
                    </a>
                    <a href="{{ route('admin.subscriber.mail') }}" class="btn btn-sm btn-info text-white">
                        <i class="bi bi-envelope-fill me-1"></i> @lang('Send Email')
                    </a>
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-header card-header-content-md-between">
                <div class="mb-2 mb-md-0">
                    <h2 class="card-title h4 mb-0">@lang('Subscriber List')</h2>
                </div>
                <div class="d-grid d-sm-flex justify-content-md-end align-items-sm-center gap-2">
                    <form action="{{ route('admin.subscriber.index') }}" method="get" class="d-flex align-items-center">
                        <div class="input-group input-group-merge input-group-flush border rounded-2 px-2">
                            <div class="input-group-prepend input-group-text p-0 border-0">
                                <i class="bi-search"></i>
                            </div>
                            <input type="search" class="form-control form-control-sm border-0" name="search"
                                   value="{{ request('search') }}"
                                   placeholder="@lang('Search email...')" aria-label="@lang('Search email...')">
                            @if(request('search'))
                                <a href="{{ route('admin.subscriber.index') }}" class="btn btn-sm text-secondary p-0 ms-1"><i class="bi-x-circle"></i></a>
                            @endif
                        </div>
                    </form>
                </div>
            </div>
            <div class="table-responsive">
                <table class="table table-borderless table-thead-bordered table-nowrap table-align-middle card-table">
                    <thead class="thead-light">
                    <tr>
                        <th scope="col">@lang('Serial No.')</th>
                        <th scope="col">@lang('Subscriber Email')</th>
                        <th scope="col">@lang('Joined On')</th>
                        <th scope="col" class="text-center">@lang('Action')</th>
                    </tr>
                    </thead>
                    <tbody>
                    @forelse($subscriber as $key => $item)
                        <tr>
                            <td>{{ $subscriber->firstItem() + $key }}</td>
                            <td>
                                <div class="d-flex align-items-center">
                                    <div class="avatar avatar-xs avatar-soft-primary avatar-circle me-2">
                                        <span class="avatar-initials">{{ strtoupper(substr($item->email, 0, 1)) }}</span>
                                    </div>
                                    <span class="text-dark fw-semibold">{{ $item->email }}</span>
                                </div>
                            </td>
                            <td>{{ dateTime($item->created_at) }}</td>
                            <td class="text-center">
                                <button
                                    class="btn btn-white btn-sm text-danger notiflix-confirm" title="@lang('Delete')"
                                    data-bs-toggle="modal" data-bs-target="#delete"
                                    data-route="{{ route('admin.subscriber.destroy', $item->id) }}">
                                    <i class="bi-trash"></i>
                                </button>
                            </td>
                        </tr>
                    @empty
                        @include('empty')
                    @endforelse
                    </tbody>
                </table>
            </div>
            <!-- End Table -->
            <div class="card-footer">
                <div class="row d-flex justify-content-end">
                    {{ $subscriber->appends($_GET)->links($theme.'partials.pagination') }}
                </div>
            </div>

        </div>
    </div>
@endsection

@push('loadModal')
    <!-- Delete Modal -->
    <div class="modal fade" id="delete" data-bs-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="staticBackdropLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="delete-modal">{{ trans('Delete Subscriber') }}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <p class="mb-0">@lang('Are you sure you want to remove this subscriber email?')</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-white" data-bs-dismiss="modal">@lang('Close')</button>
                    <form action="" method="post" class="deleteRoute">
                        @csrf
                        @method('delete')
                        <button type="submit" class="btn btn-soft-danger">@lang('Yes, Delete')</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
    <!-- End Modal -->
@endpush

@push('script')
    <script>
        $(document).ready(function () {
            $('.notiflix-confirm').on('click', function () {
                let route = $(this).data('route');
                $('.deleteRoute').attr('action', route);
            });
        });
    </script>
@endpush
