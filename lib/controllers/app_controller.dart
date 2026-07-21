import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
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
    isGettingDashboard = true;
    update();
    try {
      http.Response response = await AppControllerRepo.getDashboard();
      isGettingDashboard = false;
      walletList.clear();
      recipientList.clear();
      update();
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          walletList.addAll(
            wallet.WalletModel.fromJson(data).message!.wallets!,
          );
          recipientList.addAll(
            dash.DashboardModel.fromJson(data).message!.recipients!,
          );
          update();
        } else {
          Helpers.showSnackBar(
            msg: data['message']?.toString() ?? 'Unable to load dashboard',
          );
        }
      } else {
        Helpers.showSnackBar(msg: 'Unable to load dashboard');
      }
    } catch (_) {
      isGettingDashboard = false;
      walletList.clear();
      recipientList.clear();
      update();
    }
  }

  //-------------------GET BASIC CONTROLL--------------------
  List<basicCtrl.Service> basicCtrlList = [];
  bool isGettingBasicCtrl = false;
  Future getBasicCtrl() async {
    isGettingBasicCtrl = true;
    update();
    http.Response response = await AppControllerRepo.getBasicCtrl();
    isGettingBasicCtrl = false;
    basicCtrlList.clear();
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        if (data['message'] != null && data['message']['service'] != null) {
          basicCtrlList.add(
            basicCtrl.BasicCtrlModel.fromJson(data).message!.service!,
          );
        }

        update();
      } else {
        ApiStatus.checkStatus(data['status'], data['message']);
      }
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }
}

class CustomDialog extends StatelessWidget {
  const CustomDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        return;
      },
      child: AlertDialog(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/json/no_internet.json', // Replace with your image path
              height: 150.h,
              width: 150.w,
            ),
            Text(
              'No Internet!!! Please check your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16.sp),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
