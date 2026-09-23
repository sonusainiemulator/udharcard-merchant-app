import 'dart:io';
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
}
