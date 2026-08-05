import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/app_lock_controller.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLockController Unit Tests', () {
    late AppLockController appLockController;

    setUp(() {
      Get.testMode = true;
      appLockController = AppLockController();
      Get.put<AppLockController>(appLockController);
    });

    tearDown(() {
      Get.reset();
    });

    test('Initial App Lock state defaults to disabled and unlocked', () {
      expect(appLockController.isAppLockEnabled.value, false);
      expect(appLockController.isLocked.value, false);
      expect(appLockController.isAuthenticating.value, false);
    });

    test('didChangeAppLifecycleState triggers lock when paused if lock is enabled', () {
      appLockController.isAppLockEnabled.value = true;
      appLockController.isLocked.value = false;

      appLockController.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(appLockController.isLocked.value, true);
    });

    test('didChangeAppLifecycleState does not trigger lock when paused if lock is disabled', () {
      appLockController.isAppLockEnabled.value = false;
      appLockController.isLocked.value = false;

      appLockController.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(appLockController.isLocked.value, false);
    });

    test('Keys.isAppLockEnabled key matches storage constant string', () {
      expect(Keys.isAppLockEnabled, 'isAppLockEnabled');
    });
  });
}
