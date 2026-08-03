import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/app_colors.dart';
import '../data/models/wallet_model.dart' as wallet;
import '../data/models/dashboard_model.dart' as dash;
import '../data/models/basic_controll_model.dart' as basicCtrl;
import '../data/repositories/appcontroller_repo.dart';
import '../data/source/errors/check_api_status.dart';
import '../utils/services/helpers.dart';
import '../utils/services/localstorage/hive.dart';
import '../utils/services/localstorage/keys.dart';
import 'profile_controller.dart';

class AppController extends GetxController {
  static AppController get to => Get.find<AppController>();
  //-------------- check internet connectivity--------------
  void updateConnectionStatus(ConnectivityResult connectivityResult) {
    if (connectivityResult == ConnectivityResult.none) {
      Get.dialog(
        const CustomDialog(),
        barrierDismissible:
            false, // Prevent the user from closing the dialog by tapping outside
      );
    } else {
      // Dismiss the dialog if it's currently displayed
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }

  //-------------------Handle app theme----------------
  int selectedIndex = 0;
  isDarkMode() {
    return HiveHelp.read(Keys.isDark) ?? false;
  }

  onChanged(val) {
    HiveHelp.write(Keys.isDark, val);
    updateTheme();
  }

  ThemeMode themeManager() {
    return HiveHelp.read(Keys.isDark) != null
        ? HiveHelp.read(Keys.isDark) == true
            ? ThemeMode.dark
            : ThemeMode.light
        : ThemeMode.light;
  }

  void updateTheme() {
    Get.changeThemeMode(themeManager());
    isDarkMode();
    update();
  }

  //-------------------GET LANGUAGE--------------------

  Future getLanguageListBuyId({required String id}) async {
    Get.find<ProfileController>().isUpdateProfile = true;
    Get.find<ProfileController>().update();
    http.Response response = await AppControllerRepo.getLanguageById(id: id);
    Get.find<ProfileController>().isUpdateProfile = false;
    Get.find<ProfileController>().update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        if (data['message'] != null && data['message'] is Map) {
          HiveHelp.write(Keys.languageData, data['message']);
          update();
        }
        update();
      } else {
        ApiStatus.checkStatus(data['status'], data['message']);
      }
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  //-------------------GET DASHBOARD--------------------
  List<wallet.Wallet> walletList = [];
  List<dash.Recipient> recipientList = [];
  bool isGettingDashboard = false;
  Future getDashboard() async {
    if (isGettingDashboard) return;

    if (walletList.isEmpty && recipientList.isEmpty) {
      isGettingDashboard = true;
      update();
    }
    try {
      http.Response response = await AppControllerRepo.getDashboard();
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          walletList.clear();
          recipientList.clear();
          walletList.addAll(
            wallet.WalletModel.fromJson(data).message!.wallets!,
          );
          recipientList.addAll(
            dash.DashboardModel.fromJson(data).message!.recipients!,
          );
        } else {
          Helpers.showSnackBar(
            msg: data['message']?.toString() ?? 'Unable to load dashboard',
          );
        }
      } else {
        Helpers.showSnackBar(msg: 'Unable to load dashboard');
      }
    } catch (_) {
      // Keep existing data or handle error
    } finally {
      isGettingDashboard = false;
      update();
    }
  }

  //-------------------GET BASIC CONTROLL--------------------
  List<basicCtrl.Service> basicCtrlList = [];
  bool isGettingBasicCtrl = false;
  Future getBasicCtrl() async {
    if (isGettingBasicCtrl) return;

    if (basicCtrlList.isEmpty) {
      isGettingBasicCtrl = true;
      update();
    }
    try {
      http.Response response = await AppControllerRepo.getBasicCtrl();
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          basicCtrlList.clear();
          if (data['message'] != null && data['message']['service'] != null) {
            basicCtrlList.add(
              basicCtrl.BasicCtrlModel.fromJson(data).message!.service!,
            );
          }
        } else {
          ApiStatus.checkStatus(data['status'], data['message']);
        }
      } else {
        var data = jsonDecode(response.body);
        Helpers.showSnackBar(msg: '${data['message']}');
      }
    } catch (_) {
      // Keep existing basicCtrlList or handle error
    } finally {
      isGettingBasicCtrl = false;
      update();
    }
  }
}

class CustomDialog extends StatelessWidget {
  const CustomDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  color: const Color(0xFFEF4444),
                  size: 40.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Internet Connection Issue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18.sp,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Unable to connect to the backend server. Please check your mobile data or Wi-Fi connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: () async {
                  final connectivityResult =
                      await Connectivity().checkConnectivity();
                  if (connectivityResult != ConnectivityResult.none) {
                    if (Get.isDialogOpen == true) {
                      Get.back();
                    }
                  }
                },
                icon: Icon(Icons.refresh_rounded, size: 18.sp),
                label: Text(
                  'Check Connection Again',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 44.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
