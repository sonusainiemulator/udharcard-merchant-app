import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paysecure/controllers/profile_controller.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_qr_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(Keys.hiveinit);
  });

  tearDown(() {
    Get.reset();
  });

  test('ProfileController loadCustomQrCode validates file existence and clears stale paths', () async {
    final controller = Get.put(ProfileController());

    // Non-existent path
    const nonExistentPath = '/tmp/non_existent_qr_code_12345.png';
    HiveHelp.write(Keys.customQrCodePath, nonExistentPath);

    controller.loadCustomQrCode();
    expect(controller.customQrCodePath, isNull);
    expect(HiveHelp.read(Keys.customQrCodePath), isNull);

    // Existing path
    final realFile = File('${Directory.systemTemp.path}/test_qr_real.png');
    await realFile.writeAsString('dummy_qr_data');

    HiveHelp.write(Keys.customQrCodePath, realFile.path);
    controller.loadCustomQrCode();
    expect(controller.customQrCodePath, equals(realFile.path));

    // Cleanup
    await realFile.delete();
  });

  test('ProfileController saveQrCodeBytes saves file, writes base64 to Hive, and restores from base64', () async {
    final controller = Get.put(ProfileController());

    final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
    await controller.saveQrCodeBytes(dummyBytes, extension: '.png');

    expect(controller.customQrCodePath, isNotNull);
    expect(File(controller.customQrCodePath!).existsSync(), isTrue);
    expect(HiveHelp.read(Keys.customQrCodeBase64), isNotNull);

    // Simulate file getting deleted on disk
    await File(controller.customQrCodePath!).delete();
    expect(File(controller.customQrCodePath!).existsSync(), isFalse);

    // Call loadCustomQrCode - it should restore from base64 backup!
    controller.loadCustomQrCode();
    expect(controller.customQrCodePath, isNotNull);
    expect(HiveHelp.read(Keys.customQrCodeBase64), isNotNull);

    // Clean up
    await controller.removeCustomQrCode();
    expect(controller.customQrCodePath, isNull);
    expect(HiveHelp.read(Keys.customQrCodePath), isNull);
    expect(HiveHelp.read(Keys.customQrCodeBase64), isNull);
  });

  test('ProfileController saveMerchantUpiId and removeMerchantUpiId manage state and storage', () async {
    final controller = Get.put(ProfileController());

    await controller.saveMerchantUpiId('store@upi');
    expect(controller.merchantUpiId, equals('store@upi'));
    expect(HiveHelp.read(Keys.merchantUpiId), equals('store@upi'));

    await controller.removeMerchantUpiId();
    expect(controller.merchantUpiId, isNull);
    expect(HiveHelp.read(Keys.merchantUpiId), isNull);
  });
}
