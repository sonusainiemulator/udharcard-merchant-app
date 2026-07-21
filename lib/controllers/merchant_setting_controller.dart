import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../data/repositories/merchant_setting_repo.dart';
import '../data/source/errors/check_api_status.dart';
import '../utils/services/helpers.dart';

class MerchantSettingController extends GetxController {
  static MerchantSettingController get to =>
      Get.find<MerchantSettingController>();

  bool isLoading = false;

  TextEditingController amountController = TextEditingController();
  TextEditingController withdrawAt = TextEditingController();
  List<String> currencyList = [];
  List<WithdrawInformationModel> withdrawInformationList = [];
  dynamic selectedCurrency = null;
  String selectedCurrencyId = "0";

  dynamic chargeApplyTo;
  dynamic autoWithdraw;
  dynamic withdrawFrequency;
  //------------------cash in screen----
  Future getMerchantSetting() async {
    isLoading = true;
    update();
    http.Response response = await MerchantSettingRepo.getMerchantSetting();
    currencyList.clear();
    withdrawInformationList.clear();
    isLoading = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        if (data['message']['payoutMethod'] != null &&
            data['message']['payoutMethod']['supported_currency'] != null) {
          currencyList = List.from(
            data['message']['payoutMethod']['supported_currency'],
          );
        }

        var settings = data['message']['setting'];
        if (settings != null) {}
        chargeApplyTo =
            settings['charge_applied_to'] == null
                ? null
                : settings['charge_applied_to'] == 'merchant'
                ? 'Myself'
                : 'Sender';
        autoWithdraw =
            settings['auto_withdraw'] == null
                ? null
                : settings['auto_withdraw'] == '1'
                ? 'On'
                : 'Off';
        withdrawFrequency =
            settings['withdraw_frequency'] == null
                ? null
                : settings['withdraw_frequency'].toString().toCapital();
        amountController.text =
            settings['withdraw_amount'] == null
                ? ""
                : Helpers.numberFormatWithAsFixed2(
                  '',
                  settings['withdraw_amount'].toString(),
                );
        selectedCurrency =
            settings['withdraw_currency'] == null
                ? null
                : settings['withdraw_currency'];
        withdrawAt.text =
            settings['last_auto_withdraw_at'] == null
                ? ""
                : DateFormat('dd/MM/yyyy').format(
                  DateTime.parse(settings['last_auto_withdraw_at'].toString()),
                );

        if (settings['withdraw_information'] != null &&
            settings['withdraw_information'] is Map) {
          Map<String, dynamic> dynamicFrom = settings['withdraw_information'];

          for (var i in dynamicFrom.entries) {
            withdrawInformationList.add(
              WithdrawInformationModel(
                fieldName: i.value['field_name'] ?? "",
                fieldValue: i.value['field_value'] ?? "",
                type: i.value['type'] ?? 'text',
                validation: i.value['validation'] ?? 'optional',
              ),
            );
          }
          if (withdrawInformationList.isNotEmpty) {
            await filterData();
          }
        }

        update();
      } else {
        ApiStatus.checkStatus(data['status'], data['message']);
      }
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  Map<String, TextEditingController> textEditingControllerMap = {};
  List<WithdrawInformationModel> fileType = [];
  List<WithdrawInformationModel> requiredFile = [];
  List<String> requiredTypeFileList = [];

  Future filterData() async {
    // check if the field type is text or textArea
    var textType =
        await withdrawInformationList.where((e) => e.type != 'file').toList();
    for (var field in textType) {
      textEditingControllerMap[field.fieldName] = TextEditingController(
        text: field.fieldValue,
      );
    }
    // check if the field type is file
    fileType =
        await withdrawInformationList.where((e) => e.type == 'file').toList();
    // listing the all required file
    requiredFile =
        await fileType.where((e) => e.validation == 'required').toList();
    // add the required file name in a seperate list for validation
    for (var file in requiredFile) {
      requiredTypeFileList.add(file.fieldName);
    }
  }

  @override
  void dispose() {
    for (var controller in textEditingControllerMap.values) {
      controller.dispose();
    }
    imagePickerResults = {};
    requiredTypeFileList.clear();
    super.dispose();
  }

  Map<String, dynamic> dynamicData = {};
  List<String> imgPathList = [];
  Future renderDynamicFieldData() async {
    imgPathList.clear();
    textEditingControllerMap.forEach((key, controller) {
      dynamicData[key] = controller.text;
    });
    await Future.forEach(imagePickerResults.keys, (String key) async {
      String filePath = imagePickerResults[key]!.path;
      imgPathList.add(imagePickerResults[key]!.path);
      dynamicData[key] = await http.MultipartFile.fromPath("", filePath);
    });
  }

  XFile? pickedFile;
  Map<String, http.MultipartFile> fileMap = {};
  Map<String, XFile?> imagePickerResults = {};
  Future<void> pickFile(String fieldName) async {
    try {
      final picker = ImagePicker();
      final pickedImageFile = await picker.pickImage(
        source: ImageSource.camera,
      );

      if (pickedImageFile != null) {
        imagePickerResults[fieldName] = pickedImageFile;
        final file = await http.MultipartFile.fromPath(
          fieldName,
          pickedImageFile.path,
        );
        fileMap[fieldName] = file;

        if (requiredTypeFileList.contains(fieldName)) {
          requiredTypeFileList.remove(fieldName);
        }
        update();
      }
    } catch (e) {
      Helpers.showSnackBar(msg: e.toString());
      if (kDebugMode) {
        print("Error while picking files: $e");
      }
    }
  }

  // update merchant setting
  bool isloadingUpdate = false;
  Future merchatSettingUpdate({
    required Map<String, String> fields,
    Iterable<http.MultipartFile>? fileList,
  }) async {
    isloadingUpdate = true;
    update();
    http.Response response = await MerchantSettingRepo.merchatSettingUpdate(
      data: fields,
      fileList: fileList,
    );
    isloadingUpdate = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        Get.back();
      }
      ApiStatus.checkStatus(data['status'], data['message']);
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  toCapital(String name) {
    var splitted = name.split("_");
    return splitted.first.toCapital()+ " "+ splitted.last.toCapital();
  }

  @override
  void onInit() {
    getMerchantSetting();
    filterData();
    super.onInit();
  }
}

class WithdrawInformationModel {
  String fieldName;
  String fieldValue;
  String type;
  String validation;
  WithdrawInformationModel({
    required this.fieldName,
    required this.fieldValue,
    required this.type,
    required this.validation,
  });
}
