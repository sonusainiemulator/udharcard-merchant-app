import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import '../../config/app_colors.dart';
import '../data/models/profile_model.dart';
import '../data/repositories/profile_repo.dart';
import '../data/source/errors/check_api_status.dart';
import '../routes/routes_name.dart';
import '../utils/services/helpers.dart';
import '../utils/services/localstorage/keys.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find<ProfileController>();

  bool isLoading = false;

  // -----------------------edit profile--------------------------
  TextEditingController fNameEditingController = TextEditingController();
  TextEditingController lNameEditingController = TextEditingController();
  TextEditingController userNameEditingController = TextEditingController();
  TextEditingController phoneNumberEditingController = TextEditingController();
  TextEditingController cityEditingController = TextEditingController();
  TextEditingController stateEditingController = TextEditingController();
  TextEditingController addrEditingController = TextEditingController();
  TextEditingController deleteEditingController = TextEditingController();

  Future validateEditProfile(context) async {
    if (fNameEditingController.text.isEmpty) {
      Helpers.showSnackBar(msg: 'First Name is required');
    } else if (lNameEditingController.text.isEmpty) {
      Helpers.showSnackBar(msg: 'Last Name is required');
    } else if (userNameEditingController.text.isEmpty) {
      Helpers.showSnackBar(msg: 'User Name is required');
    } else if (phoneNumberEditingController.text.isEmpty) {
      Helpers.showSnackBar(msg: 'Phone Nubmer is required');
    } else {
      await updateProfile(context);
    }
  }

  List<Profile> profileList = [];
  List<Language> languageList = [];
  List<Country> countryList = [];
  String userId = '';
  String userPhoto = '';
  String userName = '';
  String join_date = '';
  String addressVerificationMsg = "";
  String selectedLanguage = "English";
  String selectedLanguageId = "1";
  bool isLanguageSelected = false;
  String userEmail = "";
  String countryCode = 'US';
  String phoneCode = '+1';
  String countryName = 'United States';
  String qrLink = '';
  Future getProfile({bool? isFromRefreshIndicator = false}) async {
    if (isFromRefreshIndicator == false) isLoading = true;
    update();
    http.Response response = await ProfileRepo.getProfile();
    profileList.clear();
    languageList.clear();
    countryList.clear();
    if (isFromRefreshIndicator == false) isLoading = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        qrLink = data['message']['userProfile']['qr_link'] ?? "";
        HiveHelp.write(Keys.baseCurrency, data['message']['base_currency'] ?? "");
        profileList.add(ProfileModel.fromJson(data).message!.userProfile!);
        languageList.addAll(ProfileModel.fromJson(data).message!.languages!);
        countryList.addAll(ProfileModel.fromJson(data).message!.countries!);
        if (profileList.isNotEmpty) {
          var data = profileList[0];
          _getInfo(data); 
        }
      } else {
        ApiStatus.checkStatus(data['status'], data['message']);
      }
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  _getInfo(Profile? data) {
    try {
      userId = data == null ? '' : data.id.toString();
      userName = data == null ? '' : data.username ?? "";
      userEmail = data == null ? '' : data.email ?? '';
      join_date = data == null ? '' : data.created_at.toString();
      userPhoto = data == null ? '' : data.profilePicture ?? "";
      fNameEditingController.text = data == null ? '' : data.firstname ?? "";
      lNameEditingController.text = data == null ? '' : data.lastname ?? "";

      HiveHelp.write(Keys.userFullName, data?.name);
      HiveHelp.write(Keys.userEmail, data?.email);
      HiveHelp.write(Keys.userEmail, data?.email);
      HiveHelp.write(Keys.userPhone, data?.phone);
      userNameEditingController.text = data == null ? '' : data.username ?? "";
      phoneNumberEditingController.text = data == null ? '' : data.phone ?? "";
      cityEditingController.text = data == null ? '' : data.city ?? "";
      stateEditingController.text = data == null ? '' : data.state ?? "";
      addrEditingController.text = data == null ? '' : data.address_one ?? "";
      selectedLanguageId = data == null ? "1" : data.languageId.toString();
      if (languageList.isNotEmpty) {
        selectedLanguage =
            languageList
                .firstWhere((e) => e.id.toString() == selectedLanguageId)
                .name;
      }

      phoneCode = data == null ? "" : data.phoneCode;
      if (countryList.isNotEmpty) {
        countryName =
            countryList
                .firstWhere((e) => e.phoneCode.toString() == phoneCode)
                .name;
        countryCode =
            countryList
                .firstWhere((e) => e.phoneCode.toString() == phoneCode)
                .code;
      }
      update();
    } catch (e, s) {
      print(s);
      Helpers.showSnackBar(msg: e.toString());
    }
  }

  bool isUpdateProfile = false;
  Future updateProfile(context, {bool? isUpdateProfilePic = false}) async {
    isUpdateProfile = true;
    update();
    http.Response response = await ProfileRepo.profileUpdate(
      files:
          isUpdateProfilePic == false
              ? null
              : await http.MultipartFile.fromPath(
                'profile_picture',
                pickedImage!.path,
              ),
      data: {
        "first_name": fNameEditingController.text,
        "last_name": lNameEditingController.text,
        "username": userNameEditingController.text,
        "city": cityEditingController.text,
        "state": stateEditingController.text,
        "language": selectedLanguageId,
        "phone": phoneNumberEditingController.text,
        "address": addrEditingController.text,
        "phone_code": phoneCode,
      },
    );
    isUpdateProfile = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {
        getProfile();
        if (context != null) Navigator.of(context).pop();
        update();
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  XFile? pickedImage;
  Future<void> pickImage(ImageSource source, context) async {
    try {
        final picker = ImagePicker();
        final pickedImageFile = await picker.pickImage(source: source);
        final File imageFile = File(pickedImageFile!.path);
        final int fileSizeInBytes = await imageFile.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        pickedImage = pickedImageFile;
        if (pickedImage != null) {
          if (fileSizeInMB >= 4) {
            Helpers.showSnackBar(
              msg: "Image size exceeds 4 MB. Please choose a smaller image.",
            );
          } else {
            await updateProfile(context, isUpdateProfilePic: true);
          }
        }
        update();
     
    } catch (e) {
      Helpers.showSnackBar(msg: e.toString());
    }
  }

  //--------------------------change password--------------------------
  TextEditingController currentPassEditingController = TextEditingController();
  TextEditingController newPassEditingController = TextEditingController();
  TextEditingController confirmEditingController = TextEditingController();

  RxString currentPassVal = "".obs;
  RxString newPassVal = "".obs;
  RxString confirmPassVal = "".obs;

  bool currentPassShow = true;
  bool isNewPassShow = true;
  bool isConfirmPassShow = true;

  currentPassObscure() {
    currentPassShow = !currentPassShow;
    update();
  }

  newPassObscure() {
    isNewPassShow = !isNewPassShow;
    update();
  }

  confirmPassObscure() {
    isConfirmPassShow = !isConfirmPassShow;
    update();
  }

  void validateUpdatePass(context) async {
    if (newPassVal.value != confirmPassVal.value) {
      Helpers.showToast(
        msg: "New Password and Confirm Password didn't match!",
        gravity: ToastGravity.CENTER,
        bgColor: AppColors.redColor,
      );
    } else {
      await updateProfilePass(context);
    }
  }

  clearChangePasswordVal() {
    currentPassEditingController.clear();
    newPassEditingController.clear();
    confirmEditingController.clear();
    currentPassVal.value = '';
    newPassVal.value = '';
    confirmPassVal.value = '';
  }

  Future updateProfilePass(context) async {
    isLoading = true;
    update();
    http.Response response = await ProfileRepo.profilePassUpdate(
      data: {
        "currentPassword": currentPassVal.value,
        "password": newPassVal.value,
        "password_confirmation": confirmPassVal.value,
      },
    );
    isLoading = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {
        clearChangePasswordVal();
        Navigator.of(context).pop();

        update();
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  //--- delete account
  bool isDeleteAccount = false;
  Color deleteFieldColor = AppColors.sliderInActiveColor;
  Future deleteAccount({required String code}) async {
    isDeleteAccount = true;
    print("hello");
    update();
    http.Response response = await ProfileRepo.deleteAccount(code: '');
    isDeleteAccount = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      print(data);
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {
        HiveHelp.cleanall();
        deleteFieldColor = AppColors.sliderInActiveColor;
        deleteEditingController.clear();
        Get.offAllNamed(RoutesName.loginScreen);
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }
}
