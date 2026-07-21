import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../data/repositories/verification_repo.dart';
import '../data/source/errors/check_api_status.dart';
import '../routes/routes_name.dart';
import '../utils/services/helpers.dart';

class VerificationController extends GetxController {
  bool isLoading = false;
  //----------------Two Factor Security------------//
  var TwoFAEditingController = TextEditingController();
  bool isTwoFactorEnabled = false;
  String secretKey = '';
  String qrCodeUrl = '';
  Future getTwoFa() async {
    isLoading = true;
    update();
    http.Response response = await VerificationRepo.getTwoFa();
    isLoading = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        print("================${data['message']['twoFactorEnable']}");
        isTwoFactorEnabled = data['message']['twoFactorEnable'] ?? false;
        secretKey = data['message']['secret'] ?? "";
        qrCodeUrl = data['message']['qrCodeUrl'] ?? "";
        update();
      } else {
        ApiStatus.checkStatus(data['status'], data['message']);
      }
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  bool isVerifying = false;
  Future enableTwoFa({Map<String, dynamic>? fields, context}) async {
    isVerifying = true;
    update();
    http.Response response = await VerificationRepo.enableTwoFa(fields: fields);
    isVerifying = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);
      TwoFAEditingController.clear();
      if (data['status'] == 'success') {
        getTwoFa();
        Navigator.of(context).pop();
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  Future disableTwoFa({Map<String, dynamic>? fields, context}) async {
    isVerifying = true;
    update();
    http.Response response =
        await VerificationRepo.disableTwoFa(fields: fields);
    isVerifying = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      TwoFAEditingController.clear();
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {
        getTwoFa();
        Navigator.of(context).pop();
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  final field1 = TextEditingController();
  final field2 = TextEditingController();
  final field3 = TextEditingController();
  final field4 = TextEditingController();
  final field5 = TextEditingController();
  final field6 = TextEditingController();

  //-----------------mail verify-------------------//
  Future mailVerify({required String code, context}) async {
    isVerifying = true;
    update();
    http.Response response = await VerificationRepo.mailVerify(code: code);
    isVerifying = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {
        Get.offAllNamed(RoutesName.bottomNavBar);
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  //-----------------sms verify-------------------//
  Future smsVerify({required String code, context}) async {
    isVerifying = true;
    update();
    http.Response response = await VerificationRepo.smsVerify(code: code);
    isVerifying = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {
        Get.offAllNamed(RoutesName.bottomNavBar);
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  //-----------------twofa verify-------------------//
  final twoFaController = TextEditingController();
  Future twoFaVerify({required String code, context}) async {
    isVerifying = true;
    update();
    http.Response response = await VerificationRepo.twoFaVerify(code: code);
    isVerifying = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {
        Get.offAllNamed(RoutesName.bottomNavBar);
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  //-----------------resend code-------------------//
  bool isResending = false;
  Future resendCode({required String type}) async {
    isResending = true;
    update();
    http.Response response = await VerificationRepo.resendCode(type: type);
    isResending = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {}
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  //----------------address verify-----------------//
  String imagePath = "";
  XFile? pickedImageFile;

  Future<void> pickFiles() async {
 
      try {
        final picker = ImagePicker();
        pickedImageFile = await picker.pickImage(source: ImageSource.gallery);

        imagePath = pickedImageFile!.path;
        update();
      } catch (e) {
        Helpers.showSnackBar(msg: e.toString());
      }

  }

  //------------------identity verification-------------------//
  List<CategoryNameModel> categoryNameList = [];
  List<VerificationServicesForm> verificationList = [];
  bool userIdentityVerifyFromShow = false;
  Color fileColorOfDField = Colors.transparent;
  Future getVerificationList() async {
    isLoading = true;
    update();
    http.Response response = await VerificationRepo.getVerificationList();

    isLoading = false;
    categoryNameList = [];
    verificationList = [];
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        // filter the dynamic field data
        if (data['message']['KycList'] != null &&
            data['message']['KycList'] is List) {
          List<Map<String, dynamic>> kForm =
              List.from(data['message']['KycList']);

          for (int i = 0; i < kForm.length; i += 1) {
            categoryNameList.add(CategoryNameModel(
              status: kForm[i]['user_kyc_status'] ?? "",
              id: kForm[i]['id'],
              slug: kForm[i]['slug'] ?? "",
              categoryName: kForm[i]['name'] ?? "",
            ));

            if (kForm[i]['input_form'] != null &&
                kForm[i]['input_form'] is Map) {
              Map<String, dynamic> map = kForm[i]['input_form'];

              for (var j in map.values) {
                verificationList.add(VerificationServicesForm(
                    categoryName: kForm[i]['name'],
                    fieldName: j['field_name'],
                    fieldLevel: j['field_label'],
                    type: j['type'],
                    validation: j['validation']));
              }
            }
          }

          update();
        }
        update();
      } else {
        ApiStatus.checkStatus(data['status'], data['data']);
      }
    } else {
      Helpers.showSnackBar(msg: '${data['data']}');
    }
  }

  bool isIdentitySubmitting = false;
  Future submitVerification(
      {required Map<String, String> fields,
      required BuildContext context,
      required Iterable<http.MultipartFile>? fileList}) async {
    isIdentitySubmitting = true;
    update();
    http.Response response = await VerificationRepo.submitVerification(
        fields: fields, fileList: fileList);
    isIdentitySubmitting = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {
        refreshIndentityVerificationDynamicData();
        Navigator.of(context)
          ..pop()
          ..pop();
        update();
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  //------------------let's manupulate the dynamic form data-----//
  Map<String, TextEditingController> textEditingControllerMap = {};
  List<VerificationServicesForm> fileType = [];
  List<VerificationServicesForm> requiredFile = [];
  List<VerificationServicesForm> filteredList = [];
  String selectedCategoryName = "";

  Future filterData() async {
    fileColorOfDField = Colors.transparent;
    filteredList = [];
    filteredList = verificationList
        .where((e) => e.categoryName == selectedCategoryName)
        .toList();
    // check if the field type is text, textarea, number or date
    var textType = await filteredList.where((e) => e.type != 'file').toList();

    for (var field in textType) {
      textEditingControllerMap[field.fieldName!] = TextEditingController();
    }

    // check if the field type is file
    fileType = await filteredList.where((e) => e.type == 'file').toList();
    // listing the all required file
    requiredFile =
        await fileType.where((e) => e.validation == 'required').toList();
    update();
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

    // if (kDebugMode) {
    //   print("Posting data: $dynamicData");
    // }
  }

  final formKey = GlobalKey<FormState>();
  XFile? pickedFile;
  Map<String, http.MultipartFile> fileMap = {};
  Map<String, XFile?> imagePickerResults = {};
  Future<void> pickFile(String fieldName) async {

      try {
        final picker = ImagePicker();
        final pickedImageFile =
            await picker.pickImage(source: ImageSource.camera);

        final File imageFile = File(pickedImageFile!.path);
        final int fileSizeInBytes = await imageFile.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB >= 4) {
          Helpers.showSnackBar(
              msg: "Image size exceeds 4 MB. Please choose a smaller image.");
        } else {
          imagePickerResults[fieldName] = pickedImageFile;
          requiredFile.removeWhere((e) => e.fieldName == fieldName);
          final file = await http.MultipartFile.fromPath(
              fieldName, pickedImageFile.path);
          fileMap[fieldName] = file;
        }

        update();
      } catch (e) {
        if (kDebugMode) {
          print("Error while picking files: $e");
        }
      }
  
  }

  refreshIndentityVerificationDynamicData() {
    verificationList.clear();
    imagePickerResults.clear();
    dynamicData.clear();
    textEditingControllerMap.clear();
    fileType.clear();
    requiredFile.clear();
    pickedImageFile = null;
    fileMap.clear();
    pickedFile = null;
  }
  //--------------------------------------------------//

  refreshData() {
    verificationList.clear();
    imagePickerResults.clear();
    dynamicData.clear();
    textEditingControllerMap.clear();
    fileType.clear();
    requiredFile.clear();
    pickedImageFile = null;
    fileMap.clear();
  }
}

class VerificationServicesForm {
  dynamic categoryName;
  dynamic fieldName;
  dynamic fieldLevel;
  dynamic type;
  dynamic validation;

  VerificationServicesForm({
    this.categoryName,
    this.fieldName,
    this.fieldLevel,
    this.type,
    this.validation,
  });
}

class CategoryNameModel {
  dynamic status;
  dynamic id;
  dynamic categoryName;
  dynamic slug;
  CategoryNameModel({this.categoryName, this.id, this.status, this.slug});
}
