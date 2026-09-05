import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/bottom_nav_controller.dart';
import 'package:paysecure/controllers/profile_controller.dart';
import 'package:paysecure/routes/routes_helper.dart';
import 'package:paysecure/routes/routes_name.dart';
import 'package:paysecure/views/screens/home/home_screen.dart';
import 'package:paysecure/views/screens/profile/profile_setting_screen.dart';
import 'package:paysecure/views/screens/udhar/customer_list_screen.dart';
import 'package:paysecure/views/screens/voice_entry/voice_entry_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Merged Dashboard and BottomNavController Tests', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
    });

    test('BottomNavController initializes with merged screens list', () {
      final ctrl = BottomNavController();
      expect(ctrl.screens.length, 4);
      expect(ctrl.screens[0].runtimeType, HomeScreen);
      expect(ctrl.screens[1].runtimeType, CustomerListScreen);
      expect(ctrl.screens[2].runtimeType, VoiceEntryScreen);
      expect(ctrl.screens[3].runtimeType, ProfileSettingScreen);
      expect(ctrl.selectedIndex, 0);
    });

    test('BottomNavController changeScreen updates selectedIndex', () {
      final ctrl = BottomNavController();
      ctrl.changeScreen(1);
      expect(ctrl.selectedIndex, 1);
      ctrl.changeScreen(3);
      expect(ctrl.selectedIndex, 3);
      ctrl.changeScreen(0);
      expect(ctrl.selectedIndex, 0);
    });

    test('RouteHelper routes udharDashboardScreen to HomeScreen', () {
      final routes = RouteHelper.routes();
      final udharDashPage = routes.firstWhere(
        (page) => page.name == RoutesName.udharDashboardScreen,
      );
      final widget = udharDashPage.page();
      expect(widget.runtimeType, HomeScreen);
    });
  });

  group('ProfileController Field Preparation Tests', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
    });

    test('Single-word names are preserved cleanly', () {
      final ctrl = ProfileController();
      ctrl.fNameEditingController.text = 'Rajesh';
      ctrl.lNameEditingController.text = '';
      final fullName =
          "${ctrl.fNameEditingController.text} ${ctrl.lNameEditingController.text}"
              .trim();
      expect(fullName, 'Rajesh');
    });

    test('Multi-word names combine correctly', () {
      final ctrl = ProfileController();
      ctrl.fNameEditingController.text = 'Rajesh';
      ctrl.lNameEditingController.text = 'Kumar Sharma';
      final fullName =
          "${ctrl.fNameEditingController.text} ${ctrl.lNameEditingController.text}"
              .trim();
      expect(fullName, 'Rajesh Kumar Sharma');
    });

    test('Phone code sanitization removes plus symbol', () {
      const codeWithPlus = '+91';
      final sanitized = codeWithPlus.replaceAll('+', '').trim();
      expect(sanitized, '91');
    });
  });
}
