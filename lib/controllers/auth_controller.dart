import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:paysecure/data/repositories/auth_repo.dart';
import 'package:paysecure/data/source/errors/check_api_status.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'subscription_controller.dart';
import '../routes/routes_name.dart';
import '../utils/services/localstorage/keys.dart';
import '../utils/services/subscription_gate_service.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();
  static const authSubmissionUpdateId = 'authSubmission';

  bool isLoading = false;
  bool _isOtpRequestInProgress = false;
  bool _isCompletingAuthentication = false;
  bool _isPendingRegistrationFlow = false;

  void _debugAuth(String message) {
    if (kDebugMode) {
      debugPrint('[AUTH] $message');
    }
  }

  void _notifyAuthSubmission() {
    // Keep existing auth screens reactive while limiting the costly form rebuild
    // to the small submission area on the login and registration pages.
    update();
    update([authSubmissionUpdateId]);
  }

  @override
  void onInit() {
    super.onInit();
    firebasePhoneController.addListener(() {
      firebasePhoneVal = firebasePhoneController.text.trim();
      loginErrorMessage = null;
    });
  }

  @override
  void onClose() {
    firebasePhoneController.dispose();
    firebaseOtpController.dispose();
    userNameEditingController.dispose();
    signInPassEditingController.dispose();
    super.onClose();
  }

  // -----------------------sign in--------------------------
  TextEditingController userNameEditingController = TextEditingController();
  TextEditingController signInPassEditingController = TextEditingController();

  String userNameVal = "";
  String singInPassVal = "";
  bool isRemember = false;
  String? loginErrorMessage;

  clearSignInController() {
    userNameEditingController.clear();
    signInPassEditingController.clear();
    userNameVal = "";
    singInPassVal = "";
    loginErrorMessage = null;
  }

  Future login() async {
    isLoading = true;
    loginErrorMessage = null;
    update();
    try {
      http.Response response = await AuthRepo.login(
        data: {
          "username": userNameVal,
          "password": singInPassVal,
          "type": 'merchant',
        },
      );
      isLoading = false;
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['status'] == 'success') {
          ApiStatus.checkStatus(data['status'], data['message']);
          if (isRemember == true) {
            HiveHelp.write(Keys.userName, userNameVal);
            HiveHelp.write(Keys.userPass, singInPassVal);
          }
          HiveHelp.write(Keys.token, data['token']);
          final user = data['user'];
          if (user is Map) {
            if (user['id'] != null) {
              HiveHelp.write(Keys.userId, user['id'].toString());
            }
            final phone = user['phone']?.toString() ?? userNameVal;
            HiveHelp.write(Keys.userPhone, phone);
            HiveHelp.write(Keys.userName, phone);
          }
          await _navigatePostAuthentication();
          clearSignInController();
        } else {
          loginErrorMessage =
              data['message']?.toString() ?? 'Invalid credentials';
        }
      } else {
        loginErrorMessage =
            data['message']?.toString() ?? 'Invalid credentials';
      }
    } catch (e) {
      isLoading = false;
      loginErrorMessage = 'Connection error. Please try again.';
    }
    update();
  }

  //------------------------forgot password----------------------
  TextEditingController forgotPassEmailEditingController =
      TextEditingController();
  TextEditingController forgotPassNewPassEditingController =
      TextEditingController();
  TextEditingController forgotPassConfirmPassEditingController =
      TextEditingController();
  TextEditingController otpEditingController1 = TextEditingController();
  TextEditingController otpEditingController2 = TextEditingController();
  TextEditingController otpEditingController3 = TextEditingController();
  TextEditingController otpEditingController4 = TextEditingController();
  TextEditingController otpEditingController5 = TextEditingController();

  String forgotPassEmailVal = "";
  String forgotPassNewPassVal = "";
  String forgotPassConfirmPassVal = "";
  String otpVal1 = "";
  String otpVal2 = "";
  String otpVal3 = "";
  String otpVal4 = "";
  String otpVal5 = "";

  bool isNewPassShow = true;
  bool isConfirmPassShow = true;

  clearForgotPassNewPassVal() {
    forgotPassNewPassEditingController.clear();
    forgotPassConfirmPassEditingController.clear();
    forgotPassNewPassVal = "";
    forgotPassConfirmPassVal = "";
  }

  clearForgotPassOtpVal() {
    otpEditingController1.clear();
    otpEditingController2.clear();
    otpEditingController3.clear();
    otpEditingController4.clear();
    otpEditingController5.clear();
    otpVal1 = "";
    otpVal2 = "";
    otpVal3 = "";
    otpVal4 = "";
    otpVal5 = "";
  }

  Future forgotPass({bool? isFromOtpPage = false}) async {
    if (isFromOtpPage == false) {
      isLoading = true;
      update();
    }
    http.Response response = await AuthRepo.forgotPass(
      data: {"email": forgotPassEmailEditingController.text},
    );
    if (isFromOtpPage == false) {
      isLoading = false;
      update();
    }
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {
        Get.toNamed(RoutesName.otpScreen);
      }
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  //----------------------verify email-----------------
  ///COUNT DOWN TIMER
  int counter = 60;
  late Timer timer;
  bool isStartTimer = false;
  Duration duration = const Duration(seconds: 1);

  void startTimer() {
    timer = Timer.periodic(duration, (timer) {
      if (counter > 0) {
        counter -= 1;
        isStartTimer = true;
        update();
      } else {
        timer.cancel();
        counter = 60;
        isStartTimer = false;
        update();
      }
    });
  }

  Future geCode() async {
    isLoading = true;
    update();
    http.Response response = await AuthRepo.getCode(
      data: {
        "email": forgotPassEmailEditingController.text,
        "code": '${otpVal1 + otpVal2 + otpVal3 + otpVal4 + otpVal5}',
      },
    );
    isLoading = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {
        Get.toNamed(RoutesName.createNewPassScreen);
        clearForgotPassOtpVal();
      }
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  Future updatePass() async {
    isLoading = true;
    update();
    http.Response response = await AuthRepo.updatePass(
      data: {
        "password": forgotPassNewPassEditingController.text,
        "password_confirmation": forgotPassConfirmPassEditingController.text,
        "email": forgotPassEmailEditingController.text,
      },
    );
    isLoading = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {
        Get.offAllNamed(RoutesName.loginScreen);
        clearForgotPassNewPassVal();
      }
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  // -----------------------register--------------------------
  TextEditingController nameEditingController = TextEditingController();
  TextEditingController emailEditingController = TextEditingController();
  TextEditingController phoneEditingController = TextEditingController();
  TextEditingController shopNameEditingController = TextEditingController();
  TextEditingController passwordEditingController = TextEditingController();
  TextEditingController confirmPasswordEditingController =
      TextEditingController();

  String nameVal = "";
  String emailVal = "";
  String phoneVal = "";
  String shopNameVal = "";
  String passwordVal = "";
  String confirmPasswordVal = "";
  bool isRegisterPassShow = true;
  bool isRegisterConfirmPassShow = true;

  clearRegisterController() {
    nameEditingController.clear();
    emailEditingController.clear();
    phoneEditingController.clear();
    shopNameEditingController.clear();
    passwordEditingController.clear();
    confirmPasswordEditingController.clear();
    nameVal = "";
    emailVal = "";
    phoneVal = "";
    shopNameVal = "";
    passwordVal = "";
    confirmPasswordVal = "";
    isRegisterPassShow = true;
    isRegisterConfirmPassShow = true;
  }

  Map<String, dynamic> buildRegisterPayload({
    String? name,
    String? email,
    String? phone,
    String? shopName,
    String? password,
    String? confirmPassword,
  }) {
    final String rawPhone = (phone ?? phoneVal).trim();
    String cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
    }

    final String normalizedName = (name ?? nameVal).trim();
    final List<String> parts = normalizedName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final String firstName = parts.isNotEmpty ? parts.first : 'Merchant';
    final String lastName = parts.length > 1
        ? parts.sublist(1).join(' ')
        : 'Merchant';
    final String effectivePhone = cleanPhone.isNotEmpty ? cleanPhone : rawPhone;
    final String trimmedEmail = (email ?? emailVal).trim();
    final String effectiveEmail = trimmedEmail.isNotEmpty
        ? trimmedEmail
        : '$effectivePhone@merchant.udharcard.shop';
    final String normalizedShopName = (shopName ?? shopNameVal).trim();

    return {
      "name": normalizedName,
      "firstname": firstName,
      "lastname": lastName,
      "email": effectiveEmail,
      "phone": effectivePhone,
      "mobile": effectivePhone,
      "username": effectivePhone,
      "shop_name": normalizedShopName,
      "business_name": normalizedShopName,
      "phone_code": "+91",
      "country": "India",
      "country_code": "IN",
      "type": "merchant",
      "password": password ?? passwordVal,
      "password_confirmation": confirmPassword ?? confirmPasswordVal,
    };
  }

  Future register() async {
    isLoading = true;
    update();
    try {
      http.Response response = await AuthRepo.register(
        data: buildRegisterPayload(),
      );
      isLoading = false;
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ApiStatus.checkStatus(data['status'], data['message']);
        if (data['status'] == 'success') {
          Get.offAllNamed(RoutesName.loginScreen);
          clearRegisterController();
        }
      } else {
        Helpers.showSnackBar(
          msg: data['message']?.toString() ?? 'Registration failed',
        );
      }
    } catch (e) {
      isLoading = false;
      Helpers.showSnackBar(msg: 'Connection error. Please try again.');
    }
    update();
  }

  // -----------------------Firebase OTP--------------------------
  TextEditingController firebasePhoneController = TextEditingController();
  TextEditingController firebaseOtpController = TextEditingController();
  String firebasePhoneVal = "";
  String firebaseOtpVal = "";
  String? firebaseVerificationId;

  clearFirebaseOtpController({bool resetFlow = true}) {
    firebasePhoneController.clear();
    firebaseOtpController.clear();
    firebasePhoneVal = "";
    firebaseOtpVal = "";
    firebaseVerificationId = null;
    loginErrorMessage = null;
    if (resetFlow) {
      _isOtpRequestInProgress = false;
      _isCompletingAuthentication = false;
      _isPendingRegistrationFlow = false;
    }
  }

  Future<bool> _checkMerchantAccountExists(String phoneNumber) async {
    try {
      String cleanPhone =
          phoneNumber.trim().replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
      if (cleanPhone.startsWith('91') && cleanPhone.length > 10) {
        cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
      }
      _debugAuth('check-exist start phone=$cleanPhone');

      // 1. Try check merchant endpoint first
      try {
        http.Response response = await AuthRepo.checkMerchantExist(
          data: {
            "phone": cleanPhone,
            "mobile": cleanPhone,
            "username": cleanPhone,
            "type": "merchant",
          },
        );
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          _debugAuth('check-exist 200 body=${response.body}');
          if (data['status'] == 'success' ||
              data['exists'] == true ||
              data['is_exist'] == true) {
            _debugAuth('check-exist result=true via primary endpoint');
            return true;
          }
          if (data['status'] == 'error' ||
              data['exists'] == false ||
              data['is_exist'] == false) {
            String msg = (data['message'] ?? '').toString().toLowerCase();
            if (msg.contains('not found') ||
                msg.contains('not exist') ||
                msg.contains('does not exist') ||
                msg.contains('no account') ||
                msg.contains('invalid') ||
                msg.contains('register') ||
                data['exists'] == false ||
                data['is_exist'] == false) {
              _debugAuth('check-exist result=false via primary endpoint');
              return false;
            }
          }
        } else if (response.statusCode == 404 || response.statusCode == 422) {
          try {
            var data = jsonDecode(response.body);
            _debugAuth('check-exist ${response.statusCode} body=${response.body}');
            if (data['exists'] == false ||
                data['status'] == 'error' ||
                data['message'] != null) {
              String msg = (data['message'] ?? '').toString().toLowerCase();
              if (msg.contains('not exist') ||
                  msg.contains('not found') ||
                  msg.contains('register') ||
                  data['exists'] == false) {
                _debugAuth('check-exist result=false via primary endpoint ${response.statusCode}');
                return false;
              }
            }
          } catch (_) {}
        }
      } catch (_) {
        _debugAuth('check-exist primary endpoint failed, falling back to login probe');
        // Fallthrough if check-exist endpoint is not available
      }

      // 2. Fallback: check against standard login endpoint
      http.Response loginResponse = await AuthRepo.login(
        data: {
          "username": cleanPhone,
          "password": "check_existence_dummy_password",
          "type": "merchant",
        },
      );

      if (loginResponse.statusCode == 200 ||
          loginResponse.statusCode == 404 ||
          loginResponse.statusCode == 422 ||
          loginResponse.statusCode == 400 ||
          loginResponse.statusCode == 401) {
        var data = jsonDecode(loginResponse.body);
        String msg = (data['message'] ?? '').toString().toLowerCase();
        _debugAuth('login probe ${loginResponse.statusCode} body=${loginResponse.body}');

        // If backend explicitly says username/user is invalid, account does not exist.
        if (msg.contains('invalid username') ||
            msg.contains('invalid user') ||
            msg.contains('invalid mobile') ||
            msg.contains('user not found')) {
          _debugAuth('check-exist result=false via login probe invalid user message');
          return false;
        }

        // If server says phone already taken or password invalid -> account exists!
        if (msg.contains('already been taken') ||
            msg.contains('password') ||
            msg.contains('credential') ||
            data['status'] == 'success') {
          _debugAuth('check-exist result=true via login probe');
          return true;
        }

        // If server explicitly says user/account not found -> does not exist
        if (msg.contains('not found') ||
            msg.contains('does not exist') ||
            msg.contains('no account') ||
            msg.contains('no merchant')) {
          _debugAuth('check-exist result=false via login probe not found message');
          return false;
        }
      }

      // 3. Additional fallback check: if login response returned status error with message indicating no user
      if (loginResponse.statusCode == 200) {
        var data = jsonDecode(loginResponse.body);
        if (data['status'] == 'error' || data['status'] == 'failed') {
          String msg = (data['message'] ?? '').toString().toLowerCase();
          if (msg.isNotEmpty &&
              (msg.contains('invalid') ||
                  msg.contains('not found') ||
                  msg.contains('not exist') ||
                  !msg.contains('password'))) {
            _debugAuth('check-exist result=false via login probe status=${data['status']}');
            return false;
          }
        }
      }

      _debugAuth('check-exist default result=true (conservative pass-through)');
      return true;
    } catch (e) {
      _debugAuth('check-exist exception=$e (allowing OTP to avoid hard block)');
      // In case of network exception, allow OTP to proceed so user is not blocked offline
      return true;
    }
  }

  Future<void> saveRegistrationProfileToHiveAndBackend() async {
    String regName = nameEditingController.text.trim();
    String rawPhone = phoneEditingController.text.trim();
    String regShop = shopNameEditingController.text.trim();
    String regEmail = emailEditingController.text.trim();

    if (regName.isEmpty && regShop.isEmpty) return;

    String cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
    }
    if (cleanPhone.isEmpty) cleanPhone = rawPhone;

    List<String> nameParts = regName.split(' ');
    String firstName = nameParts.first;
    String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Merchant';
    String effectiveEmail = regEmail.isNotEmpty ? regEmail : '$cleanPhone@merchant.udharcard.shop';

    HiveHelp.write(Keys.userFullName, regName);
    HiveHelp.write(Keys.userPhone, cleanPhone);
    HiveHelp.write(Keys.userName, cleanPhone);
    HiveHelp.write('shop_name', regShop);
    if (regEmail.isNotEmpty) {
      HiveHelp.write(Keys.userEmail, regEmail);
    }

    try {
      await AuthRepo.register(
        data: {
          "name": regName,
          "firstname": firstName,
          "lastname": lastName,
          "phone": cleanPhone,
          "mobile": cleanPhone,
          "username": cleanPhone,
          "shop_name": regShop,
          "business_name": regShop,
          "email": effectiveEmail,
          "password": "merchant_default_password",
          "password_confirmation": "merchant_default_password",
          "phone_code": "+91",
          "country": "India",
          "country_code": "IN",
          "type": "merchant",
        },
      );
    } catch (e) {
      // Offline fallback: allow onboarding to proceed
    }
  }

  Future sendFirebaseOtp(String phoneNumber, {bool isLogin = false}) async {
    if (_isOtpRequestInProgress || _isCompletingAuthentication) return;
    String formattedPhone = phoneNumber.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (formattedPhone.length < 7) {
      loginErrorMessage = 'Enter a valid mobile number.';
      _notifyAuthSubmission();
      return;
    }
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+91$formattedPhone';
    }
    _isOtpRequestInProgress = true;
    _isPendingRegistrationFlow = !isLogin;
    isLoading = true;
    loginErrorMessage = null;
    _notifyAuthSubmission();

    if (isLogin) {
      bool accountExists = await _checkMerchantAccountExists(phoneNumber);
      if (!accountExists) {
        _isOtpRequestInProgress = false;
        _isPendingRegistrationFlow = false;
        isLoading = false;
        loginErrorMessage =
            'Merchant account does not exist. Please register first.';
        _notifyAuthSubmission();
        return;
      }
    }
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (Android only)
          await _signInWithFirebaseCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _isOtpRequestInProgress = false;
          _isPendingRegistrationFlow = false;
          isLoading = false;
          String errorMsg = e.message ?? 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMsg = 'Please enter a valid mobile number.';
          } else if (e.code == 'too-many-requests' || errorMsg.contains('blocked')) {
            errorMsg =
                'SMS limit reached for this mobile number. Please wait a few minutes before requesting another OTP.';
          } else if (e.code == 'app-not-authorized' || e.code == 'invalid-app-credential') {
            errorMsg = 'App not authorized in Firebase. Check SHA-1/SHA-256 in Firebase Console.';
          }
          loginErrorMessage = errorMsg;
          _notifyAuthSubmission();
        },
        codeSent: (String verificationId, int? resendToken) {
          _isOtpRequestInProgress = false;
          isLoading = false;
          firebaseVerificationId = verificationId;
          loginErrorMessage = null;
          _notifyAuthSubmission();
          if (_isCompletingAuthentication) return;
          if (Get.currentRoute != RoutesName.firebaseOtpVerifyScreen) {
            Get.toNamed(RoutesName.firebaseOtpVerifyScreen);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          firebaseVerificationId = verificationId;
        },
      );
    } catch (e) {
      _isOtpRequestInProgress = false;
      _isPendingRegistrationFlow = false;
      isLoading = false;
      loginErrorMessage = 'Failed to send OTP: $e';
      _notifyAuthSubmission();
    }
  }

  Future verifyFirebaseOtp() async {
    if (firebaseVerificationId == null ||
        firebaseOtpVal.isEmpty ||
        _isCompletingAuthentication) {
      return;
    }
    isLoading = true;
    loginErrorMessage = null;
    _notifyAuthSubmission();
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: firebaseVerificationId!,
        smsCode: firebaseOtpVal,
      );
      await _signInWithFirebaseCredential(credential);
    } catch (e) {
      isLoading = false;
      loginErrorMessage = 'Invalid OTP or verification failed.';
      _notifyAuthSubmission();
    }
  }

  Future _signInWithFirebaseCredential(PhoneAuthCredential credential) async {
    if (_isCompletingAuthentication) return;
    _isCompletingAuthentication = true;
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      if (userCredential.user != null) {
        String? token = await userCredential.user!.getIdToken();
        token ??= "firebase_auth_token_${userCredential.user!.uid}";

        // Persist merchant session permanently into local storage
        HiveHelp.write(Keys.token, token);
        HiveHelp.write(Keys.isNewUser, false);
        HiveHelp.write(Keys.isRemember, true);
        HiveHelp.write(Keys.userId, userCredential.user!.uid);
        if (userCredential.user?.phoneNumber != null &&
            userCredential.user!.phoneNumber!.isNotEmpty) {
          HiveHelp.write(Keys.userName, userCredential.user!.phoneNumber);
          HiveHelp.write(Keys.userPhone, userCredential.user!.phoneNumber);
        }

        if (_isPendingRegistrationFlow) {
          await saveRegistrationProfileToHiveAndBackend();
        }

        isLoading = false;
        _notifyAuthSubmission();
        final bool onboardingCompleted =
            HiveHelp.read('onboarding_completed') ?? false;
        if (!onboardingCompleted) {
          Get.offAllNamed(RoutesName.merchantOnboardingWizardScreen);
        } else {
          await _navigatePostAuthentication();
        }
        clearFirebaseOtpController(resetFlow: false);
        clearRegisterController();
      } else {
        _isCompletingAuthentication = false;
        isLoading = false;
        loginErrorMessage = 'Unable to complete sign in. Please try again.';
        _notifyAuthSubmission();
      }
    } catch (e) {
      isLoading = false;
      _notifyAuthSubmission();
      Helpers.showSnackBar(msg: 'Sign in failed: $e');
    } finally {
      _isCompletingAuthentication = false;
      _isOtpRequestInProgress = false;
      _isPendingRegistrationFlow = false;
    }
  }

  Future<void> _navigatePostAuthentication() async {
    if (!SubscriptionGateService.isPlanEnrollmentRequired()) {
      Get.offAllNamed(RoutesName.bottomNavBar);
      return;
    }

    final bool planSelected =
        (HiveHelp.read(Keys.subscriptionPlanSelected) ?? false) == true;

    if (planSelected) {
      Get.offAllNamed(RoutesName.bottomNavBar);
      return;
    }

    try {
      if (Get.isRegistered<SubscriptionController>()) {
        await Get.find<SubscriptionController>().getCurrentSubscription();
      } else {
        await Get.put(SubscriptionController(), permanent: true)
            .getCurrentSubscription();
      }
    } catch (_) {}

    final bool refreshedSelection =
        (HiveHelp.read(Keys.subscriptionPlanSelected) ?? false) == true;

    if (refreshedSelection) {
      Get.offAllNamed(RoutesName.bottomNavBar);
    } else {
      Get.offAllNamed(RoutesName.subscriptionPlansScreen);
    }
  }

  // ------------------- Social Logins -----------------------
  Future<void> signInWithGoogle() async {
    isLoading = true;
    update();
    try {
      // Stub: Here we will use GoogleSignIn to get the auth credentials,
      // and send it to our backend to authenticate the merchant.
      await Future.delayed(const Duration(seconds: 1));
      Helpers.showSnackBar(
        msg:
            'Google Sign-In is not fully configured yet. Backend integration required.',
        title: 'Coming Soon',
      );
    } catch (e) {
      loginErrorMessage = 'Google Sign-In failed: $e';
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> signInWithApple() async {
    isLoading = true;
    update();
    try {
      // Stub: Here we will use SignInWithApple to get the auth credentials,
      // and send it to our backend to authenticate the merchant.
      await Future.delayed(const Duration(seconds: 1));
      Helpers.showSnackBar(
        msg:
            'Apple Sign-In is not fully configured yet. Backend integration required.',
        title: 'Coming Soon',
      );
    } catch (e) {
      loginErrorMessage = 'Apple Sign-In failed: $e';
    } finally {
      isLoading = false;
      update();
    }
  }
}
