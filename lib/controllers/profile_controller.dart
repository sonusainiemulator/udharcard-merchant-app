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

  // -----------------------shop & timing details-----------------
  TextEditingController shopNameEditingController = TextEditingController();
  TextEditingController shopOpeningTimeEditingController =
      TextEditingController(text: "09:00 AM");
  TextEditingController shopClosingTimeEditingController =
      TextEditingController(text: "09:30 PM");
  TextEditingController shopClosedDaysEditingController =
      TextEditingController(text: "Open All Days");
  TextEditingController businessTypeEditingController = TextEditingController();
  TextEditingController landmarkEditingController = TextEditingController();
  TextEditingController whatsappEditingController = TextEditingController();
  TextEditingController shopDescEditingController = TextEditingController();
  TextEditingController gstEditingController = TextEditingController();
  TextEditingController panEditingController = TextEditingController();
  TextEditingController zipCodeEditingController = TextEditingController();

  bool isShopOnline = true;
  bool isUpdatingShopStatus = false;

  String get displayShopName {
    final name = shopNameEditingController.text.trim();
    if (name.isNotEmpty) return name;
    final cached = HiveHelp.read(Keys.shopName)?.toString().trim() ?? '';
    if (cached.isNotEmpty) return cached;
    return userName.isNotEmpty ? userName : 'UdharCard Merchant';
  }

  String get shopTimingDisplay {
    final open = shopOpeningTimeEditingController.text.trim();
    final close = shopClosingTimeEditingController.text.trim();
    if (open.isNotEmpty && close.isNotEmpty) {
      return "$open - $close";
    }
    return "09:00 AM - 09:30 PM";
  }

  Future<void> toggleShopOnlineStatus([bool? targetStatus]) async {
    final newStatus = targetStatus ?? !isShopOnline;
    isShopOnline = newStatus;
    HiveHelp.write(Keys.isShopOnline, newStatus);
    update();

    try {
      isUpdatingShopStatus = true;
      update();
      final response = await ProfileRepo.updateShopStatus(
        isShopOnline: newStatus,
        shopOpeningTime: shopOpeningTimeEditingController.text.trim(),
        shopClosingTime: shopClosingTimeEditingController.text.trim(),
        shopClosedDays: shopClosedDaysEditingController.text.trim(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Fluttertoast.showToast(
            msg: newStatus
                ? "🟢 Dukan Khuli Hai (Store is Open)"
                : "🔴 Dukan Band Hai (Store is Closed)",
            backgroundColor:
                newStatus ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint("Error toggling shop status: $e");
    } finally {
      isUpdatingShopStatus = false;
      update();
    }
  }

  Future validateEditProfile(context) async {
    if (fNameEditingController.text.isEmpty && lNameEditingController.text.isEmpty) {
      Helpers.showSnackBar(msg: 'Full Name is required');
    } else if (phoneNumberEditingController.text.isEmpty) {
      Helpers.showSnackBar(msg: 'Phone Number is required');
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
  String countryCode = 'IN';
  String phoneCode = '+91';
  String countryName = 'India';
  String qrLink = '';
  Future getProfile({bool? isFromRefreshIndicator = false}) async {
    if (isLoading) return;

    if (profileList.isEmpty && isFromRefreshIndicator == false) {
      isLoading = true;
      update();
    }

    try {
      http.Response response = await ProfileRepo.getProfile();
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          profileList.clear();
          languageList.clear();
          countryList.clear();

          qrLink = data['message']['userProfile']['qr_link'] ?? "";
          HiveHelp.write(Keys.baseCurrency, data['message']['base_currency'] ?? "");
          profileList.add(ProfileModel.fromJson(data).message!.userProfile!);
          languageList.addAll(ProfileModel.fromJson(data).message!.languages!);
          countryList.addAll(ProfileModel.fromJson(data).message!.countries!);
          if (profileList.isNotEmpty) {
            var profileData = profileList[0];
            _getInfo(profileData); 
          }
        } else {
          ApiStatus.checkStatus(data['status'], data['message']);
        }
      } else {
        var data = jsonDecode(response.body);
        Helpers.showSnackBar(msg: '${data['message']}');
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      isLoading = false;
      update();
    }
  }

  _getInfo(Profile? data) {
    try {
      userId = data == null ? '' : data.id.toString();
      String fetchedName = (data?.name ?? data?.username ?? '').toString().trim();
      userName = fetchedName.isNotEmpty
          ? fetchedName
          : (HiveHelp.read(Keys.userFullName) ?? HiveHelp.read(Keys.userName) ?? '').toString();
      userEmail = (data?.email ?? '').toString().isNotEmpty
          ? data!.email!
          : (HiveHelp.read(Keys.userEmail) ?? '').toString();
      join_date = data == null ? '' : data.created_at.toString();
      final rawPhoto = data == null ? '' : (data.profilePicture ?? "");
      userPhoto = (rawPhoto.endsWith('/default.png') || rawPhoto.endsWith('default.png')) ? '' : rawPhoto;
      fNameEditingController.text = data == null ? '' : data.firstname ?? "";
      lNameEditingController.text = data == null ? '' : data.lastname ?? "";

      if (data?.name != null && data!.name!.isNotEmpty) {
        HiveHelp.write(Keys.userFullName, data.name);
      }
      if (data?.email != null && data!.email!.isNotEmpty) {
        HiveHelp.write(Keys.userEmail, data.email);
      }
      if (data?.phone != null && data!.phone!.isNotEmpty) {
        HiveHelp.write(Keys.userPhone, data.phone);
      }

      userNameEditingController.text = userName;
      phoneNumberEditingController.text = (data?.phone ?? '').toString().isNotEmpty
          ? data!.phone!
          : (HiveHelp.read(Keys.userPhone) ?? '').toString();
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

      final fetchedShopName =
          (data?.shopName ?? data?.businessName ?? '').toString().trim();
      shopNameEditingController.text = fetchedShopName.isNotEmpty
          ? fetchedShopName
          : (HiveHelp.read(Keys.shopName) ?? '').toString();
      if (fetchedShopName.isNotEmpty) {
        HiveHelp.write(Keys.shopName, fetchedShopName);
        HiveHelp.write('shop_name', fetchedShopName);
      }

      isShopOnline =
          data?.isShopOnline ?? (HiveHelp.read(Keys.isShopOnline) ?? true);
      HiveHelp.write(Keys.isShopOnline, isShopOnline);

      shopOpeningTimeEditingController.text =
          (data?.shopOpeningTime ?? HiveHelp.read(Keys.shopOpeningTime) ?? '09:00 AM')
              .toString();
      shopClosingTimeEditingController.text =
          (data?.shopClosingTime ?? HiveHelp.read(Keys.shopClosingTime) ?? '09:30 PM')
              .toString();
      shopClosedDaysEditingController.text =
          (data?.shopClosedDays ?? HiveHelp.read(Keys.shopClosedDays) ?? 'Open All Days')
              .toString();

      businessTypeEditingController.text =
          (data?.businessType ?? HiveHelp.read(Keys.businessType) ?? '')
              .toString();
      landmarkEditingController.text =
          (data?.landmark ?? HiveHelp.read(Keys.landmark) ?? '').toString();
      whatsappEditingController.text =
          (data?.whatsappNumber ?? HiveHelp.read(Keys.whatsappNumber) ?? '')
              .toString();
      shopDescEditingController.text =
          (data?.shopDescription ?? HiveHelp.read(Keys.shopDescription) ?? '')
              .toString();
      gstEditingController.text = (data?.gstNumber ?? '').toString();
      panEditingController.text = (data?.panNumber ?? '').toString();
      zipCodeEditingController.text = (data?.zipCode ?? '').toString();

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
    try {
      final multipartFile = (isUpdateProfilePic == true && pickedImage != null)
          ? await http.MultipartFile.fromPath(
              'profile_picture',
              pickedImage!.path,
            )
          : null;

      final cleanPhoneCode = phoneCode.replaceAll('+', '').trim();
      final fullName =
          "${fNameEditingController.text} ${lNameEditingController.text}"
              .trim();
      final sanitizedUsername =
          userNameEditingController.text.trim().isNotEmpty
              ? userNameEditingController.text.trim()
              : (phoneNumberEditingController.text.trim().isNotEmpty
                  ? phoneNumberEditingController.text.trim()
                  : fullName);

      final Map<String, String> data = {
        "name": fullName,
        "first_name": fNameEditingController.text.trim(),
        "last_name": lNameEditingController.text.trim(),
        "username": sanitizedUsername,
        "city": cityEditingController.text.trim(),
        "state": stateEditingController.text.trim(),
        "language": selectedLanguageId,
        "phone": phoneNumberEditingController.text.trim(),
        "address": addrEditingController.text.trim(),
        "phone_code": cleanPhoneCode.isNotEmpty ? cleanPhoneCode : "91",
        "shop_name": shopNameEditingController.text.trim(),
        "business_name": shopNameEditingController.text.trim(),
        "business_type": businessTypeEditingController.text.trim(),
        "is_shop_online": isShopOnline ? '1' : '0',
        "shop_opening_time": shopOpeningTimeEditingController.text.trim(),
        "shop_closing_time": shopClosingTimeEditingController.text.trim(),
        "shop_closed_days": shopClosedDaysEditingController.text.trim(),
        "landmark": landmarkEditingController.text.trim(),
        "whatsapp_number": whatsappEditingController.text.trim(),
        "shop_description": shopDescEditingController.text.trim(),
        "gst_number": gstEditingController.text.trim(),
        "pan_number": panEditingController.text.trim(),
        "zip_code": zipCodeEditingController.text.trim(),
      };

      http.Response response = await ProfileRepo.profileUpdate(
        files: multipartFile,
        data: data,
      );

      var resData = jsonDecode(response.body);
      if (response.statusCode == 200 && resData['status'] == 'success') {
        if (fullName.isNotEmpty) {
          HiveHelp.write(Keys.userFullName, fullName);
          userName = fullName;
        }
        if (phoneNumberEditingController.text.trim().isNotEmpty) {
          HiveHelp.write(
            Keys.userPhone,
            phoneNumberEditingController.text.trim(),
          );
        }
        if (userNameEditingController.text.trim().isNotEmpty) {
          HiveHelp.write(
            Keys.userName,
            userNameEditingController.text.trim(),
          );
        }
        if (shopNameEditingController.text.trim().isNotEmpty) {
          HiveHelp.write(Keys.shopName, shopNameEditingController.text.trim());
          HiveHelp.write('shop_name', shopNameEditingController.text.trim());
        }
        HiveHelp.write(Keys.isShopOnline, isShopOnline);
        HiveHelp.write(Keys.shopOpeningTime, shopOpeningTimeEditingController.text.trim());
        HiveHelp.write(Keys.shopClosingTime, shopClosingTimeEditingController.text.trim());
        HiveHelp.write(Keys.shopClosedDays, shopClosedDaysEditingController.text.trim());
        HiveHelp.write(Keys.businessType, businessTypeEditingController.text.trim());
        HiveHelp.write(Keys.landmark, landmarkEditingController.text.trim());
        HiveHelp.write(Keys.whatsappNumber, whatsappEditingController.text.trim());
        HiveHelp.write(Keys.shopDescription, shopDescEditingController.text.trim());
        pickedImage = null;
        await getProfile(isFromRefreshIndicator: true);

        Helpers.showSnackBar(
          title: 'Success',
          msg: isUpdateProfilePic == true
              ? 'Profile picture updated successfully'
              : (resData['message'] ?? 'Profile updated successfully'),
          bgColor: const Color(0xFF10B981),
        );

        if (isUpdateProfilePic != true && context != null) {
          Navigator.of(context).pop();
        }
      } else {
        Helpers.showSnackBar(
          msg: resData['message']?.toString() ??
              'Failed to update profile. Please try again.',
        );
      }
    } catch (e) {
      debugPrint("Profile update exception: $e");
      Helpers.showSnackBar(msg: e.toString());
    } finally {
      isUpdateProfile = false;
      update();
    }
  }

  XFile? pickedImage;
  Future<void> pickImage(ImageSource source, context) async {
    try {
      final picker = ImagePicker();
      final pickedImageFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedImageFile == null) return;

      final File imageFile = File(pickedImageFile.path);
      final int fileSizeInBytes = await imageFile.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB >= 5) {
        Helpers.showSnackBar(
          msg: "Image size exceeds 5 MB. Please choose a smaller image.",
        );
        return;
      }

      pickedImage = pickedImageFile;
      update();

      await updateProfile(context, isUpdateProfilePic: true);
    } catch (e) {
      debugPrint("pickImage error: $e");
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

  // -------------------------- Custom Merchant QR Code & UPI --------------------------
  String? customQrCodePath;
  String? merchantUpiId;
  TextEditingController upiIdEditingController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadLocalProfileInfo();
    loadCustomQrCode();
    loadMerchantUpiId();
  }

  void loadLocalProfileInfo() {
    String hiveName = (HiveHelp.read(Keys.userFullName) ?? HiveHelp.read(Keys.userName) ?? '').toString().trim();
    if (hiveName.isNotEmpty) {
      userName = hiveName;
    }
    String hiveEmail = (HiveHelp.read(Keys.userEmail) ?? '').toString().trim();
    if (hiveEmail.isNotEmpty) {
      userEmail = hiveEmail;
    }
    String hivePhone = (HiveHelp.read(Keys.userPhone) ?? '').toString().trim();
    if (hivePhone.isNotEmpty) {
      phoneNumberEditingController.text = hivePhone;
    }
    update();
  }

  void loadCustomQrCode() {
    customQrCodePath = HiveHelp.read(Keys.customQrCodePath);
    update();
  }

  void loadMerchantUpiId() {
    merchantUpiId = HiveHelp.read(Keys.merchantUpiId);
    upiIdEditingController.text = merchantUpiId ?? '';
    update();
  }

  Future<void> saveMerchantUpiId(String upiId) async {
    merchantUpiId = upiId.trim();
    upiIdEditingController.text = merchantUpiId!;
    HiveHelp.write(Keys.merchantUpiId, merchantUpiId);
    Helpers.showSnackBar(msg: "Merchant UPI ID saved successfully!");
    update();
  }

  Future<void> removeMerchantUpiId() async {
    merchantUpiId = null;
    upiIdEditingController.clear();
    HiveHelp.remove(Keys.merchantUpiId);
    Helpers.showSnackBar(msg: "Merchant UPI ID removed.");
    update();
  }

  Future<void> pickCustomQrCode(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (image != null) {
        customQrCodePath = image.path;
        HiveHelp.write(Keys.customQrCodePath, image.path);
        Helpers.showSnackBar(msg: "Custom QR Code updated successfully!");
        update();
      }
    } catch (e) {
      Helpers.showSnackBar(msg: "Failed to pick image: $e");
    }
  }

  Future<void> removeCustomQrCode() async {
    customQrCodePath = null;
    await HiveHelp.remove(Keys.customQrCodePath);
    Helpers.showSnackBar(msg: "Custom QR Code removed.");
    update();
  }
}
