import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:paysecure/data/models/worklist_model.dart';
import 'package:paysecure/data/repositories/worklist_repo.dart';
import 'package:paysecure/utils/services/helpers.dart';
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

    items
      ..clear()
      ..addAll(_decodeItems(rawItems));

    _sortInPlace(items);
    isLoaded = true;
    update();
  }

  Future<void> fetchWorkItems() async {
    await checkConnection();
    if (isOffline) {
      Helpers.showSnackBar(msg: 'No internet. Realtime work list sync is unavailable.');
      update();
      return;
    }

    isSyncing = true;
    update();
    try {
      final response = await WorkListRepo.getItems();
      final data = _decodeJsonMap(response.body);
      if (response.statusCode == 200 && data?['status'] == 'success') {
        final payload = data?['data'];
        final rawItems =
            (payload is Map<String, dynamic>) ? payload['items'] : null;
        final remoteItems = (rawItems is List)
            ? rawItems
                .whereType<Map>()
                .map(
                  (entry) => WorkListItem.fromJson(
                    Map<String, dynamic>.from(entry.cast<dynamic, dynamic>()),
                  ).copyWith(isSynced: true),
                )
                .toList()
            : <WorkListItem>[];

        items
          ..clear()
          ..addAll(_sortItems(remoteItems));
        isLoaded = true;
        HiveHelp.write(
          Keys.workListItems,
          items.map((item) => item.toJson()).toList(),
        );
      } else {
        final msg = data?['message']?.toString().trim();
        Helpers.showSnackBar(
          msg:
              (msg != null && msg.isNotEmpty)
                  ? msg
                  : 'Unable to fetch realtime work list.',
        );
      }
    } catch (_) {
      Helpers.showSnackBar(msg: 'Unable to fetch realtime work list.');
    } finally {
      isSyncing = false;
      update();
    }
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
    await checkConnection();
    if (isOffline) {
      Helpers.showSnackBar(msg: 'No internet. Saving tasks requires live sync.');
      return;
    }

    isSyncing = true;
    update();

    try {
      final payload = {
        'title': item.title,
        'note': item.note,
        'due_date': item.dueDate.toIso8601String(),
        'status': item.status,
        'priority': item.priority,
        'customer_id': item.customerId,
      };

      final bool isServerId = int.tryParse(item.id) != null;
      final http.Response response = isServerId
          ? await WorkListRepo.updateItem(itemId: item.id, payload: payload)
          : await WorkListRepo.createItem(
              payload: {...payload, 'client_local_id': item.id},
            );

      final data = _decodeJsonMap(response.body);
      if (response.statusCode == 200 && data?['status'] == 'success') {
        await fetchWorkItems();
      } else {
        final msg = data?['message']?.toString().trim();
        Helpers.showSnackBar(
          msg:
              (msg != null && msg.isNotEmpty)
                  ? msg
                  : 'Unable to save task in realtime.',
        );
      }
    } catch (_) {
      Helpers.showSnackBar(msg: 'Unable to save task in realtime.');
    } finally {
      isSyncing = false;
      update();
    }
  }

  Future<void> toggleCompletion(String id, bool isCompleted) async {
    final index = items.indexWhere((element) => element.id == id);
    if (index < 0) return;

    await checkConnection();
    if (isOffline) {
      Helpers.showSnackBar(msg: 'No internet. Status update requires live sync.');
      return;
    }

    final current = items[index];
    final payload = {
      'title': current.title,
      'note': current.note,
      'due_date': current.dueDate.toIso8601String(),
      'status':
          isCompleted
              ? WorkListItem.statusCompleted
              : WorkListItem.statusPending,
      'priority': current.priority,
      'customer_id': current.customerId,
    };

    try {
      final response = await WorkListRepo.updateItem(itemId: id, payload: payload);
      final data = _decodeJsonMap(response.body);
      if (response.statusCode == 200 && data?['status'] == 'success') {
        await fetchWorkItems();
      } else {
        final msg = data?['message']?.toString().trim();
        Helpers.showSnackBar(
          msg:
              (msg != null && msg.isNotEmpty)
                  ? msg
                  : 'Unable to update task status.',
        );
      }
    } catch (_) {
      Helpers.showSnackBar(msg: 'Unable to update task status.');
    }
  }

  Future<void> deleteItem(String id) async {
    await checkConnection();
    if (isOffline) {
      Helpers.showSnackBar(msg: 'No internet. Delete requires live sync.');
      return;
    }

    try {
      final response = await WorkListRepo.deleteItem(itemId: id);
      final data = _decodeJsonMap(response.body);
      if (response.statusCode == 200 && data?['status'] == 'success') {
        items.removeWhere((element) => element.id == id);
        await _persist();
        update();
      } else {
        final msg = data?['message']?.toString().trim();
        Helpers.showSnackBar(
          msg:
              (msg != null && msg.isNotEmpty)
                  ? msg
                  : 'Unable to delete task.',
        );
      }
    } catch (_) {
      Helpers.showSnackBar(msg: 'Unable to delete task.');
    }
  }

  Future<void> syncWorkItems() async {
    await fetchWorkItems();
  }

  Map<String, dynamic>? _decodeJsonMap(String input) {
    try {
      final dynamic parsed = jsonDecode(input);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
    } catch (_) {}
    return null;
  }

  String createLocalId() {
    return 'local_task_${_nowProvider().millisecondsSinceEpoch}';
  }

  Future<void> _persist() async {
    HiveHelp.write(
      Keys.workListItems,
      items.map((item) => item.toJson()).toList(),
    );
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