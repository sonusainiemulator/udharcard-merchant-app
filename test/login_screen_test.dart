import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/auth_controller.dart';
import 'package:paysecure/views/screens/auth/login_screen.dart';
import 'package:paysecure/views/widgets/auth_footer_branding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen Widget Tests', () {
    late AuthController authController;

    setUp(() {
      Get.testMode = true;
      authController = AuthController();
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
            home: const LoginScreen(),
          );
        },
      );
    }

    testWidgets('Renders MERCHANT PORTAL header & Mobile Login title', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('MERCHANT PORTAL'), findsOneWidget);
      expect(find.textContaining('Mobile Login'), findsOneWidget);
    });

    testWidgets('Renders Send OTP SMS and WhatsApp buttons', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Send OTP via SMS'), findsOneWidget);
      expect(find.text('Send OTP via WhatsApp'), findsOneWidget);
    });

    testWidgets('Renders Google Sign-In option', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('Verifies legacy username & password fields are removed', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Username'), findsNothing);
      expect(find.text('Password'), findsNothing);
      expect(find.text('Forgot Password?'), findsNothing);
    });

    testWidgets('Renders AuthFooterBranding components', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('100% Secure & Trusted'), findsOneWidget);
      expect(find.text('Made in India'), findsOneWidget);
      expect(find.byType(AuthFooterBranding), findsOneWidget);
    });
  });
}
