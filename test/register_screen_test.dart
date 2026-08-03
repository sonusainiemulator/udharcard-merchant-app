import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/auth_controller.dart';
import 'package:paysecure/views/screens/auth/register_screen.dart';

class TestAuthController extends AuthController {
  String? submittedPhone;
  bool? submittedIsLogin;
  int submitCalls = 0;

  @override
  Future sendFirebaseOtp(String phoneNumber, {bool isLogin = false}) async {
    submitCalls += 1;
    submittedPhone = phoneNumber;
    submittedIsLogin = isLogin;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RegisterScreen Widget Tests', () {
    late TestAuthController authController;

    setUp(() {
      Get.testMode = true;
      authController = TestAuthController();
      Get.put<AuthController>(authController);
    });

    tearDown(() {
      Get.reset();
    });

    Widget createWidgetUnderTest() {
      return ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        builder: (context, child) {
          return GetMaterialApp(
            home: const RegisterScreen(),
          );
        },
      );
    }

    testWidgets('Renders current register eyebrow and title', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('MERCHANT ONBOARDING'), findsOneWidget);
      expect(find.text('Build your business profile'), findsOneWidget);
    });

    testWidgets('Renders current registration CTA and key fields', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Verify mobile number & Register'), findsOneWidget);
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Business name'), findsOneWidget);
    });

    testWidgets('Verifies legacy password fields are removed', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Password'), findsNothing);
      expect(find.text('Confirm Password'), findsNothing);
    });

    testWidgets('Submits registration details into OTP flow with merchant register mode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(4));

      await tester.enterText(fields.at(0), 'Jane Merchant');
      await tester.enterText(fields.at(1), 'Jane General Store');
      await tester.enterText(fields.at(2), '9876543210');
      await tester.enterText(fields.at(3), 'jane@example.com');
      await tester.tap(find.text('Verify mobile number & Register'));
      await tester.pump();

      expect(authController.submitCalls, 1);
      expect(authController.submittedPhone, '9876543210');
      expect(authController.submittedIsLogin, isFalse);
      expect(authController.firebasePhoneController.text, '9876543210');
      expect(authController.nameEditingController.text, 'Jane Merchant');
      expect(authController.shopNameEditingController.text, 'Jane General Store');
      expect(authController.emailEditingController.text, 'jane@example.com');
    });
  });
}
