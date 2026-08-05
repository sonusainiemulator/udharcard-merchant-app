import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:paysecure/routes/routes_name.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppLockController extends GetxController with WidgetsBindingObserver {
  static AppLockController get to => Get.find<AppLockController>();

  final LocalAuthentication _auth = LocalAuthentication();

  final RxBool isAppLockEnabled = false.obs;
  final RxBool isLocked = false.obs;
  final RxBool isAuthenticating = false.obs;
  final RxBool canCheckBiometrics = false.obs;
  final RxList<BiometricType> availableBiometrics = <BiometricType>[].obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadLockState();
    checkBiometrics();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  void loadLockState() {
    bool storedState = HiveHelp.read(Keys.isAppLockEnabled) ?? false;
    isAppLockEnabled.value = storedState;
  }

  Future<void> checkBiometrics() async {
    try {
      bool canCheck = await _auth.canCheckBiometrics;
      bool isSupported = await _auth.isDeviceSupported();
      canCheckBiometrics.value = canCheck || isSupported;
      if (canCheck) {
        availableBiometrics.value = await _auth.getAvailableBiometrics();
      }
    } catch (e) {
      debugPrint("AppLockController checkBiometrics error: $e");
      canCheckBiometrics.value = false;
    }
  }

  Future<bool> authenticate({String? reason}) async {
    if (isAuthenticating.value) return false;
    try {
      isAuthenticating.value = true;
      bool authenticated = await _auth.authenticate(
        localizedReason: reason ?? 'Use fingerprint, PIN, or pattern lock to unlock app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
          biometricOnly: false,
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint("Authentication PlatformException: $e");
      Fluttertoast.showToast(msg: "Authentication failed: ${e.message ?? e.code}");
      return false;
    } catch (e) {
      debugPrint("Authentication error: $e");
      return false;
    } finally {
      isAuthenticating.value = false;
    }
  }

  Future<void> toggleAppLock(bool enable) async {
    bool canAuth = await _auth.isDeviceSupported() || await _auth.canCheckBiometrics;
    if (!canAuth) {
      Fluttertoast.showToast(
        msg: "Device lock (Fingerprint/PIN/Pattern) is not configured on this device.",
      );
      return;
    }

    bool success = await authenticate(
      reason: enable
          ? 'Confirm your fingerprint, PIN, or pattern to enable App Lock'
          : 'Confirm your fingerprint, PIN, or pattern to disable App Lock',
    );

    if (success) {
      isAppLockEnabled.value = enable;
      HiveHelp.write(Keys.isAppLockEnabled, enable);
      Fluttertoast.showToast(
        msg: enable ? "App Lock enabled successfully!" : "App Lock disabled successfully!",
      );
      update();
    } else {
      Fluttertoast.showToast(msg: "Authentication cancelled or failed.");
    }
  }

  Future<void> unlockApp() async {
    bool success = await authenticate(
      reason: 'Use fingerprint, PIN, or pattern lock to unlock UdharCard Merchant App',
    );

    if (success) {
      isLocked.value = false;
      if (Get.currentRoute == RoutesName.appLockScreen) {
        Get.offAllNamed(RoutesName.bottomNavBar);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isAppLockEnabled.value) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      isLocked.value = true;
    } else if (state == AppLifecycleState.resumed) {
      if (isLocked.value && Get.currentRoute != RoutesName.appLockScreen) {
        Get.toNamed(RoutesName.appLockScreen);
      }
    }
  }
}
