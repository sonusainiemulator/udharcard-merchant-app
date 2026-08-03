import 'package:flutter/material.dart';
import '../views/screens/udhar/udhar_dashboard_screen.dart';
import '../routes/page_index.dart';

class BottomNavController extends GetxController {
  static BottomNavController get to => Get.find<BottomNavController>();
  int selectedIndex = 0;
  final List<Widget> screens = [
    const HomeScreen(),
    const UdharDashboardScreen(),
    const VoiceEntryScreen(),
    const ProfileSettingScreen(),
  ];

  void changeScreen(int index) {
    if (selectedIndex == index) return;
    selectedIndex = index;
    update();
  }
}
