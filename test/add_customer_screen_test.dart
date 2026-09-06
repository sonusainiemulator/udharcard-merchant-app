import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/udhar_controller.dart';
import 'package:paysecure/views/screens/udhar/add_customer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddCustomerScreen Widget Tests', () {
    late UdharController udharController;

    setUp(() {
      Get.testMode = true;
      udharController = UdharController();
      Get.put<UdharController>(udharController);
    });

    tearDown(() {
      Get.reset();
    });

    Widget createWidgetUnderTest() {
      return ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        builder: (context, child) {
          return const GetMaterialApp(
            home: AddCustomerScreen(),
          );
        },
      );
    }

    testWidgets('Renders screen title, +91 phone prefix, and party chips',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 300));

      // Title
      expect(find.text('Add Parties'), findsOneWidget);

      // +91 code prefix
      expect(find.text('+91'), findsOneWidget);

      // Party category chips
      expect(find.text('Customer'), findsWidgets); // chip + profile badge
      expect(find.text('Dealer'), findsOneWidget);
      expect(find.text('Wholesaler'), findsOneWidget);
      expect(find.text('Supplier'), findsOneWidget);

      // Contacts buttons
      expect(find.text('Contacts'), findsOneWidget);

      // CTA button
      expect(find.text('Add Customer'), findsOneWidget);
    });

    testWidgets('Switching party category chip updates selection',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on Dealer
      await tester.tap(find.text('Dealer'));
      await tester.pumpAndSettle();

      // Tap on Supplier
      await tester.tap(find.text('Supplier'));
      await tester.pumpAndSettle();
    });

    testWidgets('Toggling Additional Details expands optional fields',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 300));

      // Initially collapsed
      expect(find.text('Additional Details'), findsOneWidget);
      expect(find.text('Opening Balance (₹)'), findsNothing);

      // Tap accordion header to expand
      await tester.tap(find.text('Additional Details'));
      await tester.pumpAndSettle();

      // Optional fields are now visible
      expect(find.text('Opening Balance (₹)'), findsOneWidget);
      expect(find.text('Credit Limit (₹)'), findsOneWidget);
      expect(find.text('Email Address (Optional)'), findsOneWidget);
      expect(find.text('Shop / House Address (Optional)'), findsOneWidget);
      expect(find.text('Notes & Remarks (Optional)'), findsOneWidget);

      // Tap again to collapse
      await tester.tap(find.text('Additional Details'));
      await tester.pumpAndSettle();

      expect(find.text('Opening Balance (₹)'), findsNothing);
    });

    testWidgets('Entering customer name updates dynamic avatar initials',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 300));

      udharController.nameCtrl.text = 'Rajesh Kumar';
      await tester.pump();

      expect(find.text('RK'), findsOneWidget);
      expect(find.text('Rajesh Kumar'), findsNWidgets(2));
    });
  });
}
