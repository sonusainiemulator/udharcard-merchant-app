import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/udhar_controller.dart';
import 'package:paysecure/views/screens/udhar/supplier_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupplierListScreen and Supplier Partition Tests', () {
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
            home: SupplierListScreen(),
          );
        },
      );
    }

    test('UdharController partitions customers and suppliers correctly', () {
      udharController.usersList = [
        {
          'id': '1',
          'name': 'Customer Ram',
          'phone': '9876500001',
          'type': 'Customer',
          'outstanding_balance': 500.0,
        },
        {
          'id': '2',
          'name': 'Supplier Shyam',
          'phone': '9876500002',
          'type': 'Supplier',
          'payable_amount': 10000.0,
          'due_date': 'Next Week',
        },
        {
          'id': '3',
          'name': 'Dealer Mohan',
          'phone': '9876500003',
          'type': 'Dealer',
          'payable_amount': 25000.0,
        },
        {
          'id': '4',
          'name': 'Wholesaler Sohan',
          'phone': '9876500004',
          'type': 'Wholesaler',
          'payable_amount': 15000.0,
        },
      ];

      expect(udharController.customersOnlyList.length, 1);
      expect(udharController.customersOnlyList.first['name'], 'Customer Ram');

      expect(udharController.suppliersList.length, 3);
      expect(udharController.totalPayableToSuppliers, 50000.0);
    });

    testWidgets('Renders SupplierListScreen with hero card and filter chips',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      udharController.usersList = [
        {
          'id': '10',
          'name': 'Aggarwal Traders',
          'phone': '9876543219',
          'type': 'Wholesaler',
          'payable_amount': 10000.0,
          'due_date': '2026-10-01',
        },
      ];

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 300));

      // Title & Subtitle
      expect(find.text('Suppliers & Dealers'), findsWidgets);
      expect(find.text('Payables Ledger (Dene Hain)'), findsOneWidget);

      // Hero Card Header & Amount
      expect(find.text('Total You Owe (कुल देने हैं)'), findsOneWidget);
      expect(find.text('₹10000'), findsWidgets);

      // Supplier Details Card
      expect(find.text('Aggarwal Traders'), findsOneWidget);
      expect(find.text('WHOLESALER'), findsOneWidget);
      expect(find.text('Dene Hain'), findsOneWidget);
      expect(find.text('Due: 2026-10-01'), findsOneWidget);
      expect(find.text('✓ Pay / Settle'), findsOneWidget);

      // Filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Payment Due'), findsOneWidget);
      expect(find.text('Wholesalers'), findsOneWidget);
      expect(find.text('Dealers'), findsOneWidget);
      expect(find.text('Suppliers'), findsOneWidget);
    });
  });
}
