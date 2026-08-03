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

    test('buildRegisterPayload normalizes merchant registration fields', () {
      final payload = authController.buildRegisterPayload(
        name: 'Jane Mary Doe',
        email: '',
        phone: '+91 98765-43210',
        shopName: 'Acme Shop',
        password: 'secret123',
        confirmPassword: 'secret123',
      );

      expect(payload['name'], 'Jane Mary Doe');
      expect(payload['firstname'], 'Jane');
      expect(payload['lastname'], 'Mary Doe');
      expect(payload['phone'], '9876543210');
      expect(payload['mobile'], '9876543210');
      expect(payload['username'], '9876543210');
      expect(payload['email'], '9876543210@merchant.udharcard.shop');
      expect(payload['shop_name'], 'Acme Shop');
      expect(payload['business_name'], 'Acme Shop');
      expect(payload['phone_code'], '+91');
      expect(payload['country'], 'India');
      expect(payload['country_code'], 'IN');
      expect(payload['type'], 'merchant');
      expect(payload['password'], 'secret123');
      expect(payload['password_confirmation'], 'secret123');
    });
  });
}
