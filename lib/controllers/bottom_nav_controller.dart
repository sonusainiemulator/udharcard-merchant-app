import 'package:flutter/material.dart';
import 'package:paysecure/views/screens/merchant-settings/merchant_settings_screen.dart';
import '../routes/page_index.dart';

class BottomNavController extends GetxController {
  static BottomNavController get to => Get.find<BottomNavController>();
  int selectedIndex = 0;
  List<Widget> screens = [
    HomeScreen(),
    TransactionScreen(),
    MerchantSettingScreen(),
    const ProfileSettingScreen(),
  ];

  Widget get currentScreen => screens[selectedIndex];

  void changeScreen(int index) {
    selectedIndex = index;
    update();
  }
}
