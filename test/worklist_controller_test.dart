import 'package:flutter_test/flutter_test.dart';
import 'package:paysecure/controllers/worklist_controller.dart';
import 'package:paysecure/data/models/worklist_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkListController', () {
    late DateTime now;
    late WorkListController controller;

    setUp(() {
      now = DateTime(2026, 8, 3, 9, 0);
      controller = WorkListController(nowProvider: () => now);
      controller.isOffline = true;
    });

    WorkListItem buildItem({
      required String id,
      required DateTime dueDate,
      String status = WorkListItem.statusPending,
      String priority = 'medium',
      String? customerId,
      String? customerName,
    }) {
      return WorkListItem(
        id: id,
        title: 'Task $id',
        note: 'Note $id',
        dueDate: dueDate,
        status: status,
        priority: priority,
        customerId: customerId,
        customerName: customerName,
        isSynced: false,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('groups items into overdue, today, tomorrow, upcoming, and completed buckets', () async {
      await controller.saveItem(
        buildItem(id: '1', dueDate: now.subtract(const Duration(days: 1))),
      );
      await controller.saveItem(buildItem(id: '2', dueDate: now));
      await controller.saveItem(
        buildItem(id: '3', dueDate: now.add(const Duration(days: 1))),
      );
      await controller.saveItem(
        buildItem(id: '4', dueDate: now.add(const Duration(days: 3))),
      );
      await controller.saveItem(
        buildItem(
          id: '5',
          dueDate: now,
          status: WorkListItem.statusCompleted,
        ),
      );

      expect(controller.overdueItems.map((item) => item.id), ['1']);
      expect(controller.todayItems.map((item) => item.id), ['2']);
      expect(controller.tomorrowItems.map((item) => item.id), ['3']);
      expect(controller.upcomingItems.map((item) => item.id), ['4']);
      expect(controller.completedItems.map((item) => item.id), ['5']);
      expect(controller.pendingCount, 4);
      expect(controller.pendingBadgeText, '4');
      expect(controller.pendingSummaryText, '4 pending items');
    });

    test('saveItem queues one upsert per task and updates existing entries in place', () async {
      final original = buildItem(id: 'local_task_1', dueDate: now);
      await controller.saveItem(original);
      await controller.saveItem(
        original.copyWith(title: 'Updated title', note: 'Updated note'),
      );

      expect(controller.items, hasLength(1));
      expect(controller.items.first.title, 'Updated title');
      expect(controller.offlineQueue, hasLength(1));
      expect(controller.offlineQueue.first['action'], 'upsert');
      expect(controller.offlineQueue.first['item_id'], 'local_task_1');
    });
  });

  group('WorkListItem', () {
    test('copyWith can clear customer linkage explicitly', () {
      final now = DateTime(2026, 8, 3, 10, 0);
      final item = WorkListItem(
        id: '1',
        title: 'Follow up',
        note: 'Call customer',
        dueDate: now,
        status: WorkListItem.statusPending,
        priority: 'high',
        customerId: '99',
        customerName: 'Asha',
        isSynced: true,
        createdAt: now,
        updatedAt: now,
      );

      final cleared = item.copyWith(customerId: null, customerName: null);

      expect(cleared.customerId, isNull);
      expect(cleared.customerName, isNull);
    });

    test('serializes and deserializes core fields correctly', () {
      final now = DateTime(2026, 8, 3, 10, 0);
      final item = WorkListItem(
        id: 'server_7',
        title: 'Collect payment',
        note: 'UPI reminder',
        dueDate: now,
        status: WorkListItem.statusPending,
        priority: 'high',
        customerId: '12',
        customerName: 'Ravi',
        isSynced: true,
        createdAt: now,
        updatedAt: now,
      );

      final decoded = WorkListItem.fromJson(item.toJson());

      expect(decoded.id, item.id);
      expect(decoded.title, item.title);
      expect(decoded.customerId, item.customerId);
      expect(decoded.customerName, item.customerName);
      expect(decoded.isSynced, isTrue);
    });
  });
}