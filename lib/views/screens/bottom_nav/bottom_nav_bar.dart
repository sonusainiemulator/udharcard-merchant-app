import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/app_controller.dart';
import '../../../controllers/bottom_nav_controller.dart';
import '../../../notification_service/notification_controller.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/services/pop_app.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => appCtrlBottomNavBarState();
}

class appCtrlBottomNavBarState extends State<BottomNavBar> {
  final Connectivity appCtrlconnectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = appCtrlconnectivity.onConnectivityChanged
        .listen(Get.find<AppController>().updateConnectionStatus);
    Get.find<PushNotificationController>().getPushNotificationConfig();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (appCtrl) {
        return GetBuilder<BottomNavController>(
          builder: (controller) {
            final isDark = appCtrl.isDarkMode();
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                return PopApp.onWillPop();
              },
              child: Scaffold(
                body: IndexedStack(
                  index: controller.selectedIndex,
                  children: controller.screens,
                ),
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1D2939) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Container(
                      height: 64.h,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            index: 0,
                            label: 'Home',
                            activeIcon: "$rootImageDir/home1.png",
                            inactiveIcon: "$rootImageDir/home.png",
                            controller: controller,
                            isDark: isDark,
                          ),
                          _buildNavItem(
                            index: 1,
                            label: 'Udhar',
                            activeIcon: "$rootImageDir/wallet1.png",
                            inactiveIcon: "$rootImageDir/wallet.png",
                            controller: controller,
                            isDark: isDark,
                          ),
                          _buildNavItem(
                            index: 2,
                            label: 'Transactions',
                            activeIcon: "$rootImageDir/transaction.png",
                            inactiveIcon: "$rootImageDir/transaction.png",
                            controller: controller,
                            isDark: isDark,
                          ),
                          _buildNavItem(
                            index: 3,
                            label: 'Profile',
                            activeIcon: "$rootImageDir/person2.png",
                            inactiveIcon: "$rootImageDir/person.png",
                            controller: controller,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required String activeIcon,
    required String inactiveIcon,
    required BottomNavController controller,
    required bool isDark,
  }) {
    final isSelected = controller.selectedIndex == index;
    final activeColor = AppColors.mainColor;
    final inactiveColor = isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085);

    return InkWell(
      onTap: () => controller.changeScreen(index),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isSelected ? activeIcon : inactiveIcon,
              height: 22.h,
              color: isSelected ? activeColor : inactiveColor,
              fit: BoxFit.contain,
            ),
            if (isSelected) ...[
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
