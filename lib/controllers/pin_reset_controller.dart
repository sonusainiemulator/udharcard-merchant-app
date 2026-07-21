import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../data/repositories/pin_reset_repo.dart';
import '../data/source/errors/check_api_status.dart';
import '../utils/services/helpers.dart';

class PinResetController extends GetxController {
  static PinResetController get to => Get.find<PinResetController>();

  bool isLoading = false;

  TextEditingController questionController = TextEditingController();
  TextEditingController oldPin = TextEditingController();
  TextEditingController newPin = TextEditingController();
  TextEditingController confirmPin = TextEditingController();

  Future pinReset({required Map<String, String> fields}) async {
    isLoading = true;
    update();
    http.Response response = await PinResetRepo.pinReset(data: fields);
    isLoading = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        questionController.clear();
        oldPin.clear();
        newPin.clear();
        confirmPin.clear();
        Get.back();
      }
      ApiStatus.checkStatus(data['status'], data['message']);
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  String question = "";
  String hint = "";
  bool loadingPin = false;
  Future getPinReset() async {
    loadingPin = true;
    update();
    http.Response response = await PinResetRepo.getPinReset();
    loadingPin = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        if (data['message'] != null &&
            data['message']['twoFactorSetting'] != null) {
          question =
              data['message']['twoFactorSetting']['security_question'] == null
                  ? ""
                  : data['message']['twoFactorSetting']['security_question']['question'] ??
                      "";
          hint = data['message']['twoFactorSetting']['hints'] ?? "";
        }
      } else {
        ApiStatus.checkStatus(data['status'], data['message']);
      }
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  @override
  void onInit() {
    getPinReset();
    super.onInit();
  }
}
