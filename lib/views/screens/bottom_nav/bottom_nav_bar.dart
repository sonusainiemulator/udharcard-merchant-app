import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/app_controller.dart';
import '../../../controllers/bottom_nav_controller.dart';
import '../../../controllers/profile_controller.dart';
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
  @override
  void initState() {
    appCtrlconnectivity.onConnectivityChanged.listen(
      Get.find<AppController>().updateConnectionStatus,
    );
    Get.put(PushNotificationController()).getPushNotificationConfig();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Get.put(ProfileController()).getProfile();
      Get.put(AppController()).getDashboard();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (appCtrl) {
        return GetBuilder<BottomNavController>(
          builder: (controller) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                return PopApp.onWillPop();
              },
              child: Scaffold(
                body: controller.currentScreen,
                bottomNavigationBar: SafeArea(
                  child: Container(
                    height: 84.h,
                    padding: EdgeInsets.only(
                      top: 33.h,
                      left: 24.w,
                      right: 24.w,
                    ),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color:
                              appCtrl.isDarkMode() == true
                                  ? AppColors.darkBgColor
                                  : Colors.grey.shade100,
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                      image: DecorationImage(
                        colorFilter: ColorFilter.mode(
                          appCtrl.isDarkMode() == true
                              ? AppColors.darkCardColor
                              : AppColors.whiteColor,
                          BlendMode.srcATop,
                        ),
                        image: AssetImage("$rootImageDir/bottom_nav_shape.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        InkResponse(
                          onTap: () {
                            controller.changeScreen(0);
                          },
                          child: Container(
                            padding: EdgeInsets.only(
                              left: 10.w,
                              right: 10.w,
                              top: 10.h,
                              bottom: 10.h,
                            ),
                            child: Image.asset(
                              controller.selectedIndex == 0
                                  ? "$rootImageDir/home1.png"
                                  : "$rootImageDir/home.png",
                              height: 24.h,
                              color:
                                  controller.selectedIndex == 0
                                      ? Get.isDarkMode
                                          ? AppColors.mainColor
                                          : AppColors.blackColor
                                      : appCtrl.isDarkMode() == true
                                      ? AppColors.whiteColor
                                      : AppColors.black50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        InkResponse(
                          onTap: () {
                            controller.changeScreen(1);
                          },
                          child: Container(
                            padding: EdgeInsets.zero,
                            child: Image.asset(
                              controller.selectedIndex == 1
                                  ? "$rootImageDir/wallet1.png"
                                  : "$rootImageDir/wallet.png",
                              height:
                                  controller.selectedIndex == 1 ? 28.h : 26.h,
                              color:
                                  controller.selectedIndex == 1
                                      ? Get.isDarkMode
                                          ? AppColors.mainColor
                                          : AppColors.blackColor
                                      : appCtrl.isDarkMode() == true
                                      ? AppColors.whiteColor
                                      : AppColors.black50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        InkResponse(
                          onTap: () {
                            controller.changeScreen(2);
                          },
                          child: Container(
                            padding: EdgeInsets.zero,
                            child: Image.asset(
                              "$rootImageDir/transaction.png",
                              height: 22.h,
                              color:
                                  controller.selectedIndex == 2
                                      ? Get.isDarkMode
                                          ? AppColors.mainColor
                                          : AppColors.blackColor
                                      : appCtrl.isDarkMode() == true
                                      ? AppColors.whiteColor
                                      : AppColors.black50,
                              fit:
                                  controller.selectedIndex == 2
                                      ? BoxFit.fitWidth
                                      : BoxFit.cover,
                            ),
                          ),
                        ),
                        InkResponse(
                          onTap: () {
                            controller.changeScreen(3);
                          },
                          child: Container(
                            padding: EdgeInsets.only(
                              left: 10.w,
                              right: 10.w,
                              top: 10.h,
                              bottom: 10.h,
                            ),
                            child: Image.asset(
                              controller.selectedIndex == 3
                                  ? "$rootImageDir/person2.png"
                                  : "$rootImageDir/person.png",
                              height:
                                  controller.selectedIndex == 3 ? 20.h : 23.h,
                              color:
                                  controller.selectedIndex == 3
                                      ? Get.isDarkMode
                                          ? AppColors.mainColor
                                          : AppColors.blackColor
                                      : appCtrl.isDarkMode() == true
                                      ? AppColors.whiteColor
                                      : AppColors.black50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
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
}
