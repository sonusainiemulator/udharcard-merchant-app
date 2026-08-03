<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\UdharCustomer;
use App\Models\WorkListItem;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class WorkListController extends Controller
{
    public function index(Request $request)
    {
        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;
        $lastSyncTime = $request->query('last_sync_time');

        $query = WorkListItem::with('customer')
            ->where('merchant_id', $merchantId)
            ->orderByRaw('CASE WHEN due_date IS NULL THEN 1 ELSE 0 END')
            ->orderBy('due_date')
            ->orderByDesc('updated_at');

        if ($lastSyncTime) {
            try {
                $query->where('updated_at', '>=', Carbon::parse($lastSyncTime));
            } catch (\Exception $e) {
            }
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'items' => $query->get()->map(fn (WorkListItem $item) => $this->serializeItem($item))->values(),
            ],
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), $this->validationRules());

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;
        $customerId = $this->resolveCustomerId($request, $merchantId);
        if ($request->filled('customer_id') && $customerId === null) {
            return response()->json([
                'status' => 'error',
                'message' => 'Selected customer was not found for this merchant.',
            ], 404);
        }

        $item = WorkListItem::create([
            'merchant_id' => $merchantId,
            'client_local_id' => $request->input('client_local_id'),
            'customer_id' => $customerId,
            'title' => $request->input('title'),
            'note' => $request->input('note', ''),
            'due_date' => $request->input('due_date'),
            'status' => $request->input('status', 'pending'),
            'priority' => $request->input('priority', 'medium'),
        ]);

        $item->load('customer');

        return response()->json([
            'status' => 'success',
            'message' => 'Work item created successfully.',
            'data' => $this->serializeItem($item),
        ]);
    }

    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), $this->validationRules());

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;
        $item = WorkListItem::where('merchant_id', $merchantId)->find($id);
        if (!$item) {
            return response()->json([
                'status' => 'error',
                'message' => 'Work item not found.',
            ], 404);
        }

        $customerId = $this->resolveCustomerId($request, $merchantId);
        if ($request->filled('customer_id') && $customerId === null) {
            return response()->json([
                'status' => 'error',
                'message' => 'Selected customer was not found for this merchant.',
            ], 404);
        }

        $item->fill([
            'customer_id' => $customerId,
            'title' => $request->input('title'),
            'note' => $request->input('note', ''),
            'due_date' => $request->input('due_date'),
            'status' => $request->input('status', 'pending'),
            'priority' => $request->input('priority', 'medium'),
        ]);
        $item->save();
        $item->load('customer');

        return response()->json([
            'status' => 'success',
            'message' => 'Work item updated successfully.',
            'data' => $this->serializeItem($item),
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;
        $item = WorkListItem::where('merchant_id', $merchantId)->find($id);

        if (!$item) {
            return response()->json([
                'status' => 'error',
                'message' => 'Work item not found.',
            ], 404);
        }

        $item->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Work item deleted successfully.',
        ]);
    }

    public function pullSync(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'last_sync_time' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;
        $lastSyncTime = $request->filled('last_sync_time')
            ? Carbon::parse($request->input('last_sync_time'))
            : null;

        $itemsQuery = WorkListItem::with('customer')->where('merchant_id', $merchantId);
        $deletedQuery = WorkListItem::onlyTrashed()->where('merchant_id', $merchantId);

        if ($lastSyncTime) {
            $itemsQuery->where('updated_at', '>=', $lastSyncTime);
            $deletedQuery->where('deleted_at', '>=', $lastSyncTime);
        }

        $items = $itemsQuery
            ->orderByRaw('CASE WHEN due_date IS NULL THEN 1 ELSE 0 END')
            ->orderBy('due_date')
            ->orderByDesc('updated_at')
            ->get();

        $deletedIds = $deletedQuery->pluck('id')->map(fn ($id) => (string) $id)->values();

        return response()->json([
            'status' => 'success',
            'data' => [
                'last_sync_time' => now()->toDateTimeString(),
                'items' => $items->map(fn (WorkListItem $item) => $this->serializeItem($item))->values(),
                'deleted_ids' => $deletedIds,
            ],
        ]);
    }

    public function pushSync(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'upserts' => 'nullable|array',
            'upserts.*.local_id' => 'required|string|max:191',
            'upserts.*.title' => 'required|string|max:191',
            'upserts.*.note' => 'nullable|string',
            'upserts.*.due_date' => 'nullable|date',
            'upserts.*.status' => 'required|in:pending,completed',
            'upserts.*.priority' => 'required|in:low,medium,high',
            'upserts.*.customer_id' => 'nullable',
            'deletes' => 'nullable|array',
            'deletes.*' => 'required|string|max:191',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;
        $syncedItems = [];
        $deletedIds = [];

        DB::transaction(function () use ($request, $merchantId, &$syncedItems, &$deletedIds) {
            foreach ($request->input('upserts', []) as $payload) {
                $localId = (string) $payload['local_id'];
                $item = WorkListItem::where('merchant_id', $merchantId)
                    ->when(is_numeric($localId), fn ($query) => $query->orWhere('id', (int) $localId))
                    ->orWhere(function ($query) use ($merchantId, $localId) {
                        $query->where('merchant_id', $merchantId)
                            ->where('client_local_id', $localId);
                    })
                    ->first();

                $customerId = $this->resolveCustomerIdFromPayload($payload, $merchantId);

                if (!$item) {
                    $item = new WorkListItem();
                    $item->merchant_id = $merchantId;
                    if (!is_numeric($localId)) {
                        $item->client_local_id = $localId;
                    }
                }

                $item->customer_id = $customerId;
                $item->title = $payload['title'];
                $item->note = $payload['note'] ?? '';
                $item->due_date = $payload['due_date'] ?? null;
                $item->status = $payload['status'] ?? 'pending';
                $item->priority = $payload['priority'] ?? 'medium';
                $item->save();
                $item->load('customer');

                $syncedItems[] = [
                    'local_id' => $localId,
                    'server_id' => (string) $item->id,
                    'item' => $this->serializeItem($item),
                ];
            }

            foreach ($request->input('deletes', []) as $rawIdentifier) {
                $identifier = (string) $rawIdentifier;

                $item = WorkListItem::where('merchant_id', $merchantId)
                    ->when(is_numeric($identifier), fn ($query) => $query->orWhere('id', (int) $identifier))
                    ->orWhere(function ($query) use ($merchantId, $identifier) {
                        $query->where('merchant_id', $merchantId)
                            ->where('client_local_id', $identifier);
                    })
                    ->first();

                if ($item) {
                    $deletedIds[] = (string) $item->id;
                    $item->delete();
                } else {
                    $deletedIds[] = $identifier;
                }
            }
        });

        return response()->json([
            'status' => 'success',
            'data' => [
                'synced_items' => $syncedItems,
                'deleted_ids' => array_values(array_unique($deletedIds)),
            ],
        ]);
    }

    protected function validationRules(): array
    {
        return [
            'title' => 'required|string|max:191',
            'note' => 'nullable|string',
            'due_date' => 'nullable|date',
            'status' => 'required|in:pending,completed',
            'priority' => 'required|in:low,medium,high',
            'customer_id' => 'nullable',
            'client_local_id' => 'nullable|string|max:191',
        ];
    }

    protected function resolveCustomerId(Request $request, int $merchantId): ?int
    {
        if (!$request->filled('customer_id')) {
            return null;
        }

        return UdharCustomer::where('merchant_id', $merchantId)
            ->where('id', (int) $request->input('customer_id'))
            ->value('id');
    }

    protected function resolveCustomerIdFromPayload(array $payload, int $merchantId): ?int
    {
        if (!isset($payload['customer_id']) || $payload['customer_id'] === null || $payload['customer_id'] === '') {
            return null;
        }

        return UdharCustomer::where('merchant_id', $merchantId)
            ->where('id', (int) $payload['customer_id'])
            ->value('id');
    }

    protected function serializeItem(WorkListItem $item): array
    {
        return [
            'id' => (string) $item->id,
            'client_local_id' => $item->client_local_id,
            'title' => $item->title,
            'note' => $item->note ?? '',
            'due_date' => optional($item->due_date)->toDateString(),
            'status' => $item->status,
            'priority' => $item->priority,
            'customer_id' => $item->customer_id ? (string) $item->customer_id : null,
            'customer_name' => $item->customer?->name,
            'is_synced' => true,
            'created_at' => optional($item->created_at)->toIso8601String(),
            'updated_at' => optional($item->updated_at)->toIso8601String(),
        ];
    }
}