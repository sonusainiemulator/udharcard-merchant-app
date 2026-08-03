import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:paysecure/data/models/worklist_model.dart';
import 'package:paysecure/data/repositories/worklist_repo.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';

class WorkListController extends GetxController {
  static WorkListController get to => Get.find<WorkListController>();

  WorkListController({
    Connectivity? connectivity,
    DateTime Function()? nowProvider,
  }) : _connectivity = connectivity ?? Connectivity(),
       _nowProvider = nowProvider ?? DateTime.now;

  final List<WorkListItem> items = [];
  final List<Map<String, dynamic>> offlineQueue = [];
  final Connectivity _connectivity;
  final DateTime Function() _nowProvider;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool isLoaded = false;
  bool isSyncing = false;
  bool isOffline = false;

  @override
  void onInit() {
    super.onInit();
    loadFromStorage().then((_) {
      initConnectivityListener();
      fetchWorkItems();
    });
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  List<WorkListItem> get overdueItems =>
      _sortItems(_filterBy((item) => !item.isCompleted && _isOverdue(item.dueDate)));

  List<WorkListItem> get todayItems =>
      _sortItems(_filterBy((item) => !item.isCompleted && _isToday(item.dueDate)));

  List<WorkListItem> get tomorrowItems =>
      _sortItems(_filterBy((item) => !item.isCompleted && _isTomorrow(item.dueDate)));

  List<WorkListItem> get upcomingItems => _sortItems(
        _filterBy(
          (item) => !item.isCompleted && !_isToday(item.dueDate) && !_isTomorrow(item.dueDate) && !_isOverdue(item.dueDate),
        ),
      );

  List<WorkListItem> get completedItems =>
      _sortItems(_filterBy((item) => item.isCompleted), completedFirst: true);

  int get pendingCount =>
      items.where((item) => !item.isCompleted).length;

  int get todayCount => todayItems.length;

  int get tomorrowCount => tomorrowItems.length;

  int get overdueCount => overdueItems.length;

  String? get pendingBadgeText {
    if (pendingCount <= 0) return null;
    return pendingCount > 99 ? '99+' : pendingCount.toString();
  }

  String get pendingSummaryText {
    if (pendingCount <= 0) return 'No pending items';
    if (pendingCount == 1) return '1 pending item';
    return '$pendingCount pending items';
  }

  Future<void> loadFromStorage() async {
    final rawItems = HiveHelp.read(Keys.workListItems);
    final rawQueue = HiveHelp.read(Keys.workListOfflineQueue);

    items
      ..clear()
      ..addAll(_decodeItems(rawItems));
    offlineQueue
      ..clear()
      ..addAll(_decodeQueue(rawQueue));

    _sortInPlace(items);
    isLoaded = true;
    update();
  }

  Future<void> fetchWorkItems() async {
    await loadFromStorage();
    await checkConnection();
    if (isOffline) {
      update();
      return;
    }

    await syncWorkItems();
  }

  Future<void> checkConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    isOffline = connectivityResult == ConnectivityResult.none;
  }

  void initConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = isOffline;
      isOffline = result == ConnectivityResult.none;
      update();
      if (wasOffline && !isOffline) {
        syncWorkItems();
      }
    });
  }

  Future<void> saveItem(WorkListItem item) async {
    final existingIndex = items.indexWhere((element) => element.id == item.id);
    final itemToSave = item.copyWith(
      updatedAt: _nowProvider(),
      isSynced: false,
    );
    if (existingIndex >= 0) {
      items[existingIndex] = itemToSave;
    } else {
      items.add(itemToSave);
    }

    _sortInPlace(items);
    _queueOperation('upsert', itemToSave.id, payload: itemToSave.toJson());
    await _persist();
    update();
    if (!isOffline) {
      await syncWorkItems();
    }
  }

  Future<void> toggleCompletion(String id, bool isCompleted) async {
    final index = items.indexWhere((element) => element.id == id);
    if (index < 0) return;

    final current = items[index];
    final updated = current.copyWith(
      status: isCompleted ? WorkListItem.statusCompleted : WorkListItem.statusPending,
      updatedAt: _nowProvider(),
      isSynced: false,
    );

    items[index] = updated;
    _sortInPlace(items);
    _queueOperation('upsert', updated.id, payload: updated.toJson());
    await _persist();
    update();
    if (!isOffline) {
      await syncWorkItems();
    }
  }

  Future<void> deleteItem(String id) async {
    final index = items.indexWhere((element) => element.id == id);
    if (index < 0) return;

    items.removeAt(index);
    _queueOperation('delete', id);
    await _persist();
    update();
    if (!isOffline) {
      await syncWorkItems();
    }
  }

  Future<void> syncWorkItems() async {
    if (isSyncing) return;
    await checkConnection();
    if (isOffline) {
      update();
      return;
    }

    isSyncing = true;
    update();

    try {
      if (offlineQueue.isNotEmpty) {
        await _pushQueuedChanges();
      }
      await _pullLatestChanges();
    } finally {
      isSyncing = false;
      update();
    }
  }

  String createLocalId() {
    return 'local_task_${_nowProvider().millisecondsSinceEpoch}';
  }

  Future<void> _persist() async {
    HiveHelp.write(
      Keys.workListItems,
      items.map((item) => item.toJson()).toList(),
    );
    HiveHelp.write(Keys.workListOfflineQueue, offlineQueue);
  }

  void _queueOperation(
    String action,
    String itemId, {
    Map<String, dynamic>? payload,
  }) {
    offlineQueue.removeWhere((entry) => entry['item_id']?.toString() == itemId);
    offlineQueue.add({
      'action': action,
      'item_id': itemId,
      'payload': payload,
      'queued_at': _nowProvider().toIso8601String(),
    });
  }

  Future<void> _pushQueuedChanges() async {
    final upserts = <Map<String, dynamic>>[];
    final deletes = <String>[];

    for (final entry in offlineQueue) {
      final action = entry['action']?.toString();
      final itemId = entry['item_id']?.toString();
      if (action == null || itemId == null || itemId.isEmpty) {
        continue;
      }

      if (action == 'delete') {
        deletes.add(itemId);
        continue;
      }

      final payload = entry['payload'];
      if (payload is Map) {
        final upsertPayload = Map<String, dynamic>.from(payload.cast<dynamic, dynamic>());
        upsertPayload['local_id'] = itemId;
        upserts.add(upsertPayload);
      }
    }

    if (upserts.isEmpty && deletes.isEmpty) {
      return;
    }

    final http.Response response = await WorkListRepo.pushSync(
      upserts: upserts,
      deletes: deletes,
    );
    if (response.statusCode != 200) {
      return;
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 'success') {
      return;
    }

    final syncedItems = (data['data']?['synced_items'] as List?) ?? const [];
    for (final raw in syncedItems.whereType<Map>()) {
      final syncedEntry = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
      final localId = syncedEntry['local_id']?.toString();
      final serverItemRaw = syncedEntry['item'];
      if (localId == null || serverItemRaw is! Map) {
        continue;
      }

      final serverItem = WorkListItem.fromJson(
        Map<String, dynamic>.from(serverItemRaw.cast<dynamic, dynamic>()),
      ).copyWith(isSynced: true);

      final itemIndex = items.indexWhere(
        (item) => item.id == localId || item.id == serverItem.id,
      );
      if (itemIndex >= 0) {
        items[itemIndex] = serverItem;
      } else {
        items.add(serverItem);
      }

      offlineQueue.removeWhere(
        (entry) => entry['action']?.toString() == 'upsert' &&
            (entry['item_id']?.toString() == localId ||
                entry['item_id']?.toString() == serverItem.id),
      );
    }

    final deletedIds = (data['data']?['deleted_ids'] as List?) ?? const [];
    for (final rawId in deletedIds) {
      final deletedId = rawId.toString();
      offlineQueue.removeWhere(
        (entry) => entry['action']?.toString() == 'delete' &&
            entry['item_id']?.toString() == deletedId,
      );
    }

    _sortInPlace(items);
    await _persist();
  }

  Future<void> _pullLatestChanges() async {
    final lastSyncTime =
        (HiveHelp.read(Keys.workListLastSyncAt) ?? '1970-01-01 00:00:00').toString();

    final http.Response response = await WorkListRepo.pullSync(
      lastSyncTime: lastSyncTime,
    );
    if (response.statusCode != 200) {
      return;
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 'success') {
      return;
    }

    final payload = data['data'] as Map<String, dynamic>? ?? {};
    final remoteItems = ((payload['items'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (entry) => WorkListItem.fromJson(
            Map<String, dynamic>.from(entry.cast<dynamic, dynamic>()),
          ).copyWith(isSynced: true),
        )
        .toList();

    final deletedIds = ((payload['deleted_ids'] as List?) ?? const [])
        .map((entry) => entry.toString())
        .toSet();

    final mergedItems = _mergeRemoteItems(remoteItems, deletedIds);
    items
      ..clear()
      ..addAll(mergedItems);

    HiveHelp.write(
      Keys.workListLastSyncAt,
      (payload['last_sync_time'] ?? _nowProvider().toIso8601String()).toString(),
    );
    await _persist();
    update();
  }

  List<WorkListItem> _mergeRemoteItems(
    List<WorkListItem> remoteItems,
    Set<String> deletedIds,
  ) {
    final merged = <WorkListItem>[];
    final remoteIds = <String>{};

    for (final item in remoteItems) {
      if (deletedIds.contains(item.id)) {
        continue;
      }
      merged.add(item.copyWith(isSynced: true));
      remoteIds.add(item.id);
    }

    for (final item in items) {
      if (deletedIds.contains(item.id)) {
        continue;
      }

      final hasQueuedChange = offlineQueue.any(
        (entry) => entry['item_id']?.toString() == item.id,
      );
      if ((hasQueuedChange || !item.isSynced) && !remoteIds.contains(item.id)) {
        merged.add(item);
      }
    }

    _sortInPlace(merged);
    return merged;
  }

  List<WorkListItem> _decodeItems(dynamic rawItems) {
    if (rawItems is! List) return <WorkListItem>[];

    return rawItems
        .whereType<Map>()
        .map(
          (entry) => WorkListItem.fromJson(
            Map<String, dynamic>.from(entry.cast<dynamic, dynamic>()),
          ),
        )
        .toList();
  }

  List<Map<String, dynamic>> _decodeQueue(dynamic rawQueue) {
    if (rawQueue is! List) return <Map<String, dynamic>>[];

    return rawQueue
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry.cast<dynamic, dynamic>()))
        .toList();
  }

  List<WorkListItem> _filterBy(bool Function(WorkListItem item) test) {
    return items.where(test).toList();
  }

  List<WorkListItem> _sortItems(
    List<WorkListItem> source, {
    bool completedFirst = false,
  }) {
    final sorted = List<WorkListItem>.from(source);
    sorted.sort((left, right) {
      final dueCompare = left.dueDate.compareTo(right.dueDate);
      if (dueCompare != 0) return dueCompare;
      final updatedCompare = right.updatedAt.compareTo(left.updatedAt);
      if (updatedCompare != 0) return updatedCompare;
      if (completedFirst) {
        return right.createdAt.compareTo(left.createdAt);
      }
      return left.createdAt.compareTo(right.createdAt);
    });
    return sorted;
  }

  void _sortInPlace(List<WorkListItem> source) {
    source
      ..sort((left, right) {
        if (left.isCompleted != right.isCompleted) {
          return left.isCompleted ? 1 : -1;
        }
        final dueCompare = left.dueDate.compareTo(right.dueDate);
        if (dueCompare != 0) return dueCompare;
        return right.updatedAt.compareTo(left.updatedAt);
      });
  }

  bool _isToday(DateTime date) {
    final now = _nowProvider();
    return now.year == date.year && now.month == date.month && now.day == date.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = _nowProvider().add(const Duration(days: 1));
    return tomorrow.year == date.year &&
        tomorrow.month == date.month &&
        tomorrow.day == date.day;
  }

  bool _isOverdue(DateTime date) {
    final today = _nowProvider();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    return dueDay.isBefore(todayStart);
  }
}