import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final List<WorkListItem> items = [];
  final DateTime Function() _nowProvider;

  bool isLoaded = false;
  bool isSyncing = false;

  @override
  void onInit() {
    super.onInit();
    loadFromStorage().then((_) {
      fetchWorkItems();
    });
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

  Future<void> fetchWorkItems({bool isManualSync = false}) async {
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
        final errorText = (msg != null && msg.isNotEmpty)
            ? msg
            : 'Unable to fetch realtime work list.';
        debugPrint("WorkListController fetchWorkItems notice (${response.statusCode}): $errorText");
        if (isManualSync) {
          Helpers.showSnackBar(msg: errorText);
        }
      }
    } catch (e) {
      debugPrint("WorkListController fetchWorkItems exception: $e");
      if (isManualSync) {
        Helpers.showSnackBar(msg: 'Unable to fetch realtime work list.');
      }
    } finally {
      isSyncing = false;
      update();
    }
  }

  Future<void> saveItem(WorkListItem item) async {
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