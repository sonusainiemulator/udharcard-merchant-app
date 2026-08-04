// ignore_for_file: must_call_super

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/udhar_controller.dart';
import 'package:paysecure/controllers/voice_entry_controller.dart';

class TestVoiceEntryController extends VoiceEntryController {
  bool openQuickAddEntryCalled = false;

  @override
  Future<void> openQuickAddEntry() async {
    openQuickAddEntryCalled = true;
  }
}

class TestUdharController extends UdharController {
  bool submitCalled = false;
  String? lastName;
  double? lastAmount;
  String? lastType;

  @override
  void onInit() {
    // Skip connectivity/network bootstrapping in unit tests.
  }

  @override
  void onClose() {}

  @override
  void applyVoiceEntryPrefill({String? name, double? amount, String? type}) {
    lastName = name;
    lastAmount = amount;
    lastType = type;
  }

  @override
  Future<void> submitUdhar() async {
    submitCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  test(
    'saveParsedEntryDirectly forwards parsed voice entry to udhar controller',
    () async {
      final controller = VoiceEntryController();
      final udharController = TestUdharController();
      Get.put<VoiceEntryController>(controller);
      Get.put<UdharController>(udharController);

      controller.parsedName = 'Ramesh';
      controller.parsedAmount = 500;
      controller.parsedType = 'Given';

      await controller.saveParsedEntryDirectly();

      expect(udharController.submitCalled, isTrue);
      expect(udharController.lastName, 'Ramesh');
      expect(udharController.lastAmount, 500);
      expect(udharController.lastType, 'Given');
    },
  );

  test(
    'useRecentContact opens the add form with the selected customer',
    () async {
      final controller = TestVoiceEntryController();

      await controller.useRecentContact('Ramesh');

      expect(controller.parsedName, 'Ramesh');
      expect(controller.parsedAmount, 0);
      expect(controller.openQuickAddEntryCalled, isTrue);
    },
  );

  test(
    'applyVoiceEntryPrefill matches partial names and initials from contacts',
    () {
      final controller = UdharController();
      controller.usersList = [
        {'id': 1, 'name': 'Ramesh Kumar'},
        {'id': 2, 'name': 'Asha Singh'},
      ];

      controller.applyVoiceEntryPrefill(
        name: 'R K',
        amount: 500,
        type: 'Given',
      );

      expect(controller.selectedUser?['name'], 'Ramesh Kumar');
      expect(controller.amountCtrl.text, '500');
      expect(controller.transactionType, 'given');
    },
  );
}
