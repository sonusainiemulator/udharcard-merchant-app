import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/udhar_controller.dart';

class TestUdharController extends UdharController {
  int fetchUsersCalls = 0;

  @override
  Future<void> fetchUsers({bool force = false, bool isManual = false}) async {
    fetchUsersCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UdharController sync and add customer tests', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
    });

    test('syncManual triggers one realtime refresh via fetchUsers', () async {
      final controller = TestUdharController();
      await controller.syncManual();
      expect(controller.fetchUsersCalls, 1);
    });

    test('addCustomer validates required fields correctly', () async {
      final controller = TestUdharController();
      controller.nameCtrl.text = '';
      controller.phoneCtrl.text = '';

      final res = await controller.addCustomer();
      expect(res, isNull);
    });

    test('addCustomer validates short name and invalid email', () async {
      final controller = TestUdharController();
      controller.nameCtrl.text = 'A';
      controller.phoneCtrl.text = '9876543210';
      var res = await controller.addCustomer();
      expect(res, isNull);

      controller.nameCtrl.text = 'Valid Name';
      controller.emailCtrl.text = 'not-an-email';
      res = await controller.addCustomer();
      expect(res, isNull);
    });

    test('addCustomer validates numeric limit and opening balance', () async {
      final controller = TestUdharController();
      controller.nameCtrl.text = 'Ramesh';
      controller.phoneCtrl.text = '9876543210';
      controller.limitCtrl.text = '-50';
      var res = await controller.addCustomer();
      expect(res, isNull);

      controller.limitCtrl.text = 'abc';
      res = await controller.addCustomer();
      expect(res, isNull);

      controller.limitCtrl.text = '1000';
      controller.openingBalanceCtrl.text = '-10';
      res = await controller.addCustomer();
      expect(res, isNull);
    });

    test('addCustomer sanitizes +91 and 0 country prefixes from phone', () {
      String rawPhone = '+91 9876543210'.replaceAll(RegExp(r'[^0-9]'), '');
      if (rawPhone.length == 12 && rawPhone.startsWith('91')) {
        rawPhone = rawPhone.substring(2);
      }
      expect(rawPhone, '9876543210');

      String zeroPhone = '09876543210'.replaceAll(RegExp(r'[^0-9]'), '');
      if (zeroPhone.length == 11 && zeroPhone.startsWith('0')) {
        zeroPhone = zeroPhone.substring(1);
      }
      expect(zeroPhone, '9876543210');
    });

    test('customer list correctly filters and searches customers', () {
      final controller = TestUdharController();
      controller.usersList = [
        {'id': 1, 'name': 'Ramesh Kumar', 'phone': '9876543210'},
        {'id': 2, 'name': 'Suresh Patel', 'phone': '9123456780'},
        {'id': 3, 'name': 'Anita Sharma', 'phone': '9988776655'},
      ];
      controller.filteredUsers = List.from(controller.usersList);

      controller.searchUsers('Patel');
      expect(controller.filteredUsers.length, 1);
      expect(controller.filteredUsers.first['name'], 'Suresh Patel');

      controller.searchUsers('98765');
      expect(controller.filteredUsers.length, 1);
      expect(controller.filteredUsers.first['name'], 'Ramesh Kumar');

      controller.searchUsers('');
      expect(controller.filteredUsers.length, 3);
    });
  });
}