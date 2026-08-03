import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/app_controller.dart';
import '../../../controllers/bottom_nav_controller.dart';
import '../../../notification_service/notification_controller.dart';
import '../../../utils/services/pop_app.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
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
                PopApp.onWillPop();
              },
              child: Scaffold(
                body: IndexedStack(
                  index: controller.selectedIndex,
                  children: controller.screens,
                ),
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Container(
                      height: 62.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            index: 0,
                            label: 'Home',
                            iconData: Icons.home_rounded,
                            controller: controller,
                            isDark: isDark,
                          ),
                          _buildNavItem(
                            index: 1,
                            label: 'Dashboard',
                            iconData: Icons.dashboard_rounded,
                            controller: controller,
                            isDark: isDark,
                          ),
                          _buildNavItem(
                            index: 2,
                            label: 'History',
                            iconData: Icons.receipt_long_rounded,
                            controller: controller,
                            isDark: isDark,
                          ),
                          _buildNavItem(
                            index: 3,
                            label: 'Profile',
                            iconData: Icons.person_rounded,
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
    required IconData iconData,
    required BottomNavController controller,
    required bool isDark,
  }) {
    final isSelected = controller.selectedIndex == index;
    final activeColor = AppColors.mainColor;
    final inactiveColor =
        isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => controller.changeScreen(index),
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 22.sp,
              color: isSelected ? activeColor : inactiveColor,
            ),
            if (isSelected) ...[
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
