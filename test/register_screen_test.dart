import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/auth_controller.dart';
import 'package:paysecure/views/screens/auth/register_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RegisterScreen Widget Tests', () {
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
            home: const RegisterScreen(),
          );
        },
      );
    }

    testWidgets('Renders MERCHANT REGISTRATION header & Create Account title', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('MERCHANT REGISTRATION'), findsOneWidget);
      expect(find.textContaining('Create Account'), findsOneWidget);
    });

    testWidgets('Renders Register & Send OTP button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Register & Send OTP'), findsOneWidget);
    });

    testWidgets('Verifies legacy password fields are removed', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Password'), findsNothing);
      expect(find.text('Confirm Password'), findsNothing);
    });
  });
}
