import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthController Unit Tests', () {
    late AuthController authController;

    setUp(() {
      Get.testMode = true;
      authController = AuthController();
      Get.put<AuthController>(authController);
    });

    tearDown(() {
      Get.reset();
    });

    test('Initial phone & OTP state should be empty', () {
      expect(authController.firebasePhoneVal, '');
      expect(authController.firebaseOtpVal, '');
      expect(authController.firebaseVerificationId, isNull);
    });

    test('Updating firebasePhoneVal updates state correctly', () {
      authController.firebasePhoneVal = '+919876543210';
      expect(authController.firebasePhoneVal, '+919876543210');
    });

    test('clearFirebaseOtpController resets all OTP state', () {
      authController.firebasePhoneController.text = '+919876543210';
      authController.firebaseOtpController.text = '123456';
      authController.firebasePhoneVal = '+919876543210';
      authController.firebaseOtpVal = '123456';
      authController.firebaseVerificationId = 'test_verification_id';

      authController.clearFirebaseOtpController();

      expect(authController.firebasePhoneController.text, '');
      expect(authController.firebaseOtpController.text, '');
      expect(authController.firebasePhoneVal, '');
      expect(authController.firebaseOtpVal, '');
      expect(authController.firebaseVerificationId, isNull);
    });
  });
}
