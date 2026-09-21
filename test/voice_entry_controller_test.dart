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
  Future<bool> submitUdhar({
    bool popOnSuccess = true,
    String? billImagePath,
    String? idempotencyKey,
  }) async {
    submitCalled = true;
    return true;
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
      udharController.usersList = [
        {'id': '101', 'name': 'Ramesh', 'phone': '9876543210'},
      ];
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

  test('parseVoiceInstruction parses Given Udhar transaction correctly', () {
    final controller = VoiceEntryController();
    final result = controller.parseVoiceInstruction("Ramesh ko 500 rupaye udhar diya");
    expect(result.amount, 500.0);
    expect(result.type, 'Given');
    expect(result.name, 'Ramesh');
    expect(result.category, 'UDHAR');
  });

  test('parseVoiceInstruction parses Received Collection transaction correctly', () {
    final controller = VoiceEntryController();
    final result = controller.parseVoiceInstruction("Suresh se 1200 rupaye mile");
    expect(result.amount, 1200.0);
    expect(result.type, 'Received');
    expect(result.name, 'Suresh');
    expect(result.category, 'COLLECTION');
  });

  test('parseVoiceInstruction parses Purchase Order (Khareed List) correctly', () {
    final controller = VoiceEntryController();
    final result = controller.parseVoiceInstruction("Doodh aur bread khatam ho gaya mangwana hai");
    expect(result.isPurchaseOrder, isTrue);
    expect(result.category, 'PURCHASE');
    expect(result.purchaseItems, contains('Doodh'));
    expect(result.purchaseItems, contains('Bread'));
  });

  test('parseVoiceInstruction parses Customer Balance Query correctly', () {
    final controller = VoiceEntryController();
    final result = controller.parseVoiceInstruction("Ramesh ka kitna balance baki hai");
    expect(result.isQuery, isTrue);
    expect(result.name, contains('Ramesh'));
  });

  test('parseVoiceInstruction parses Multi-Item Voice Bill with correct totals', () {
    final controller = VoiceEntryController();
    final result = controller.parseVoiceInstruction("2 kg chini 40 rupaye aur 1 packet tel 120 rupaye");
    expect(result.items.length, 2);
    expect(result.amount, 200.0); // 2*40 + 1*120
    expect(result.category, 'BILL');
  });

  test('parseVoiceInstruction handles help keyword gracefully', () {
    final controller = VoiceEntryController();
    final result = controller.parseVoiceInstruction("namaste help kaise kare");
    expect(result.isHelp, isTrue);
    expect(result.category, 'HELP');
  });

  test('parseVoiceInstruction handles empty text gracefully', () {
    final controller = VoiceEntryController();
    final result = controller.parseVoiceInstruction("   ");
    expect(result.reply, contains('saaf'));
  });

  test('parseVoiceInstruction handles Devnagari numerals correctly', () {
    final controller = VoiceEntryController();
    final result = controller.parseVoiceInstruction("रमेश को ५०० उधार दिया");
    expect(result.amount, 500.0);
    expect(result.type, 'Given');
    expect(result.category, 'UDHAR');
  });

  test('normalizeTransactionType accurately normalizes varied speech & accounting terms', () {
    expect(VoiceEntryController.normalizeTransactionType('given', 'transaction'), 'Given');
    expect(VoiceEntryController.normalizeTransactionType('debit', 'transaction'), 'Given');
    expect(VoiceEntryController.normalizeTransactionType('lent', 'transaction'), 'Given');
    expect(VoiceEntryController.normalizeTransactionType('received', 'transaction'), 'Received');
    expect(VoiceEntryController.normalizeTransactionType('credit', 'transaction'), 'Received');
    expect(VoiceEntryController.normalizeTransactionType('jama', 'transaction'), 'Received');
    expect(VoiceEntryController.normalizeTransactionType('got', 'collection'), 'Received');
  });

  test('speech locale toggle switches between hi_IN and en_IN', () {
    final controller = VoiceEntryController();
    controller.setSpeechLocale('hi_IN');
    expect(controller.selectedSpeechLocale, 'hi_IN');

    controller.toggleSpeechLocale();
    expect(controller.selectedSpeechLocale, 'en_IN');

    controller.toggleSpeechLocale();
    expect(controller.selectedSpeechLocale, 'hi_IN');
  });
}
