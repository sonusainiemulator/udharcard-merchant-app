import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:paysecure/data/repositories/auth_repo.dart';
import 'package:paysecure/data/source/errors/check_api_status.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/app_constants.dart';
import 'subscription_controller.dart';
import '../routes/routes_name.dart';
import '../utils/services/localstorage/keys.dart';
import '../utils/services/subscription_gate_service.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();
  static const authSubmissionUpdateId = 'authSubmission';

  bool isLoading = false;
  bool isGoogleLoading = false;
  bool _isGoogleSignInInitialized = false;
  bool _isOtpRequestInProgress = false;
  bool _isCompletingAuthentication = false;
  bool _isPendingRegistrationFlow = false;


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
    firebaseOtpController.addListener(() {
      firebaseOtpVal = firebaseOtpController.text.trim();
      loginErrorMessage = null;
    });
  }

  @override
  void onClose() {
    _otpTimer?.cancel();
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
    isGoogleLoading = false;
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

  Timer? _otpTimer;
  int otpCountdown = 0;
  int? _firebaseResendToken;

  void startOtpTimer({int seconds = 60}) {
    _otpTimer?.cancel();
    otpCountdown = seconds;
    _notifyAuthSubmission();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpCountdown > 0) {
        otpCountdown--;
        _notifyAuthSubmission();
      } else {
        timer.cancel();
        otpCountdown = 0;
        _notifyAuthSubmission();
      }
    });
  }

  clearFirebaseOtpController({bool resetFlow = true}) {
    firebasePhoneController.clear();
    firebaseOtpController.clear();
    firebasePhoneVal = "";
    firebaseOtpVal = "";
    firebaseVerificationId = null;
    _firebaseResendToken = null;
    _otpTimer?.cancel();
    otpCountdown = 0;
    loginErrorMessage = null;
    isGoogleLoading = false;
    if (resetFlow) {
      _isOtpRequestInProgress = false;
      _isCompletingAuthentication = false;
      _isPendingRegistrationFlow = false;
    }
  }

  Future<void> saveRegistrationProfileToHiveAndBackend() async {
    String regName = nameEditingController.text.trim();
    String rawPhone = phoneEditingController.text.trim();
    String regShop = shopNameEditingController.text.trim();
    String regEmail = emailEditingController.text.trim();

    if (regName.isEmpty && regShop.isEmpty && rawPhone.isEmpty) return;

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
      final response = await AuthRepo.register(
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
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (data['token'] != null) {
            HiveHelp.write(Keys.token, data['token'].toString());
          }
          final user = data['user'];
          if (user is Map && user['id'] != null) {
            HiveHelp.write(Keys.userId, user['id'].toString());
          }
        }
      }
    } catch (e) {
      debugPrint("Registration profile save error: $e");
    }
  }

  String activeAuthPhoneNumber = "";

  String _formatFirebasePhoneAuthError(FirebaseAuthException e) {
    if (e.message != null && e.message!.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Phone authentication is not enabled in Firebase Console. Please go to Authentication > Sign-in method and enable Phone.';
    }
    switch (e.code) {
      case 'configuration-not-found':
        return 'Phone authentication is not enabled in Firebase Console. Please go to Authentication > Sign-in method and enable Phone.';
      case 'missing-client-identifier':
      case 'app-not-authorized':
        return 'App verification failed. Please register the SHA-256 fingerprint in Firebase Console.';
      case 'quota-exceeded':
        return 'SMS quota exceeded for today. Please try again later or use Firebase test numbers.';
      case 'invalid-phone-number':
        return 'The mobile number format is invalid. Please enter a valid 10-digit number.';
      case 'too-many-requests':
        return 'Too many OTP requests. Please wait a few minutes before trying again.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      default:
        return e.message ?? 'Failed to send OTP (${e.code}). Please try again.';
    }
  }

  Future sendFirebaseOtp(
    String phoneNumber, {
    bool isLogin = false,
    bool isResend = false,
  }) async {
    if (_isOtpRequestInProgress || _isCompletingAuthentication) return;

    // Clean and extract 10-digit Indian phone number
    String digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    if (digits.length < 10) {
      loginErrorMessage = 'Please enter a valid 10-digit mobile number.';
      _notifyAuthSubmission();
      return;
    }

    final String formattedPhone = '+91$digits';
    activeAuthPhoneNumber = formattedPhone;
    firebasePhoneVal = digits;
    _isOtpRequestInProgress = true;
    _isPendingRegistrationFlow = !isLogin;
    isLoading = true;
    loginErrorMessage = null;
    _notifyAuthSubmission();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        forceResendingToken: isResend ? _firebaseResendToken : null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (Android only)
          await _signInWithFirebaseCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("Firebase verifyPhoneNumber failed: [${e.code}] ${e.message}");
          _isOtpRequestInProgress = false;
          isLoading = false;
          loginErrorMessage = _formatFirebasePhoneAuthError(e);
          _notifyAuthSubmission();
          Helpers.showSnackBar(
            msg: loginErrorMessage!,
            title: 'OTP Error',
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _isOtpRequestInProgress = false;
          isLoading = false;
          firebaseVerificationId = verificationId;
          _firebaseResendToken = resendToken;
          loginErrorMessage = null;
          startOtpTimer(seconds: 60);
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
      isLoading = false;
      loginErrorMessage = 'Failed to request OTP: $e';
      _notifyAuthSubmission();
      Helpers.showSnackBar(
        msg: loginErrorMessage!,
        title: 'Error',
      );
    }
  }

  Future resendFirebaseOtp() async {
    if (otpCountdown > 0 || isLoading || _isOtpRequestInProgress) return;
    final phone = activeAuthPhoneNumber.isNotEmpty
        ? activeAuthPhoneNumber
        : firebasePhoneController.text.trim();
    if (phone.isEmpty) return;
    await sendFirebaseOtp(
      phone,
      isLogin: !_isPendingRegistrationFlow,
      isResend: true,
    );
  }

  Future verifyFirebaseOtp() async {
    final otp = firebaseOtpController.text.trim().isNotEmpty
        ? firebaseOtpController.text.trim()
        : firebaseOtpVal.trim();

    if (firebaseVerificationId == null ||
        otp.length < 6 ||
        _isCompletingAuthentication) {
      if (otp.length < 6) {
        loginErrorMessage = 'Please enter a valid 6-digit OTP code.';
        _notifyAuthSubmission();
      }
      return;
    }

    isLoading = true;
    loginErrorMessage = null;
    _notifyAuthSubmission();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: firebaseVerificationId!,
        smsCode: otp,
      );
      await _signInWithFirebaseCredential(credential);
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      if (e.code == 'invalid-verification-code') {
        loginErrorMessage = 'Invalid OTP code. Please check and try again.';
      } else if (e.code == 'session-expired') {
        loginErrorMessage = 'OTP session has expired. Please tap Resend OTP.';
      } else {
        loginErrorMessage = e.message ?? 'Verification failed (${e.code}).';
      }
      _notifyAuthSubmission();
    } catch (e) {
      isLoading = false;
      loginErrorMessage = 'Verification error: $e';
      _notifyAuthSubmission();
    }
  }

  Future<void> _authenticateWithBackendAfterOtp(String cleanPhone) async {
    try {
      final passwordsToTry = [
        "merchant_default_password",
        "123456",
        "merchant_google_auth",
        "password",
        "",
      ];

      bool loginSucceeded = false;
      for (final pwd in passwordsToTry) {
        try {
          final loginPayload = <String, dynamic>{
            "username": cleanPhone,
            "phone": cleanPhone,
            "type": "merchant",
          };
          if (pwd.isNotEmpty) {
            loginPayload["password"] = pwd;
          }

          final response = await AuthRepo.login(data: loginPayload);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['status'] == 'success') {
              if (data['token'] != null) {
                HiveHelp.write(Keys.token, data['token'].toString());
              }
              final user = data['user'];
              if (user is Map) {
                if (user['id'] != null) {
                  HiveHelp.write(Keys.userId, user['id'].toString());
                }
                final phone = user['phone']?.toString() ?? cleanPhone;
                HiveHelp.write(Keys.userPhone, phone);
                HiveHelp.write(Keys.userName, phone);
                if (user['name'] != null || user['firstname'] != null) {
                  final name = user['name'] ?? '${user['firstname']} ${user['lastname'] ?? ''}';
                  HiveHelp.write(Keys.userFullName, name.toString().trim());
                }
                if (user['shop_name'] != null) {
                  HiveHelp.write('shop_name', user['shop_name'].toString());
                }
              }
              HiveHelp.write(Keys.isNewUser, false);
              HiveHelp.write(Keys.isRemember, true);
              HiveHelp.write('onboarding_completed', true);
              loginSucceeded = true;
              break;
            }
          }
        } catch (_) {}
      }

      if (loginSucceeded) return;

      // If backend login fails because merchant doesn't exist yet, auto-register as fallback
      final regResponse = await AuthRepo.register(data: {
        "name": "Merchant $cleanPhone",
        "firstname": "Merchant",
        "lastname": cleanPhone,
        "phone": cleanPhone,
        "mobile": cleanPhone,
        "username": cleanPhone,
        "shop_name": "My Shop",
        "business_name": "My Shop",
        "email": "$cleanPhone@merchant.udharcard.shop",
        "password": "merchant_default_password",
        "password_confirmation": "merchant_default_password",
        "phone_code": "+91",
        "country": "India",
        "country_code": "IN",
        "type": "merchant",
      });

      if (regResponse.statusCode == 200) {
        final regData = jsonDecode(regResponse.body);
        if (regData['status'] == 'success') {
          if (regData['token'] != null) {
            HiveHelp.write(Keys.token, regData['token'].toString());
          }
          if (regData['user'] is Map && regData['user']['id'] != null) {
            HiveHelp.write(Keys.userId, regData['user']['id'].toString());
          }
          HiveHelp.write(Keys.userPhone, cleanPhone);
          HiveHelp.write(Keys.userName, cleanPhone);
          HiveHelp.write(Keys.isNewUser, false);
          HiveHelp.write(Keys.isRemember, true);
          HiveHelp.write('onboarding_completed', true);
          return;
        }
      }

      // Offline / fallback session persistence
      HiveHelp.write(Keys.userPhone, cleanPhone);
      HiveHelp.write(Keys.userName, cleanPhone);
      HiveHelp.write(Keys.isNewUser, false);
      HiveHelp.write(Keys.isRemember, true);
      HiveHelp.write('onboarding_completed', true);
    } catch (e) {
      debugPrint("Backend authentication error after OTP: $e");
      HiveHelp.write(Keys.userPhone, cleanPhone);
      HiveHelp.write(Keys.userName, cleanPhone);
      HiveHelp.write(Keys.isNewUser, false);
      HiveHelp.write(Keys.isRemember, true);
      HiveHelp.write('onboarding_completed', true);
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

        String rawPhone = userCredential.user?.phoneNumber ?? activeAuthPhoneNumber;
        String cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanPhone.length > 10) {
          cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
        }
        if (cleanPhone.isEmpty) cleanPhone = rawPhone;

        // Persist initial merchant session locally
        HiveHelp.write(Keys.token, token);
        HiveHelp.write(Keys.isNewUser, false);
        HiveHelp.write(Keys.isRemember, true);
        HiveHelp.write(Keys.userId, userCredential.user!.uid);
        HiveHelp.write(Keys.userName, cleanPhone);
        HiveHelp.write(Keys.userPhone, cleanPhone);

        if (_isPendingRegistrationFlow) {
          await saveRegistrationProfileToHiveAndBackend();
        } else {
          // Exchange / obtain Sanctum token from Laravel backend
          await _authenticateWithBackendAfterOtp(cleanPhone);
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

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    try {
      final serverClientId =
          (dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '').trim().isNotEmpty
              ? dotenv.env['GOOGLE_SERVER_CLIENT_ID']!.trim()
              : AppConstants.googleServerClientId;
      await GoogleSignIn.instance.initialize(
        serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
      );
      _isGoogleSignInInitialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn.initialize warning: $e');
    }
  }

  // ------------------- Social Logins -----------------------
  Future<void> signInWithGoogle() async {
    if (isLoading || isGoogleLoading || _isCompletingAuthentication) return;
    isGoogleLoading = true;
    loginErrorMessage = null;
    _notifyAuthSubmission();

    try {
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount? googleUser =
          await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        isGoogleLoading = false;
        _notifyAuthSubmission();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Firebase user is null after Google authentication');
      }

      // Extract details
      final String displayName = (user.displayName ?? '').trim();
      final String email = (user.email ?? '').trim();
      final String phone = (user.phoneNumber ?? '').trim();
      final String uid = user.uid;
      final String? idToken = await user.getIdToken();
      final String token = idToken ?? 'firebase_google_token_$uid';

      // Persist merchant session permanently into local storage
      HiveHelp.write(Keys.token, token);
      HiveHelp.write(Keys.userId, uid);
      HiveHelp.write(Keys.isNewUser, false);
      HiveHelp.write(Keys.isRemember, true);
      if (displayName.isNotEmpty) {
        HiveHelp.write(Keys.userFullName, displayName);
      }
      if (email.isNotEmpty) {
        HiveHelp.write(Keys.userEmail, email);
      }
      if (phone.isNotEmpty) {
        HiveHelp.write(Keys.userPhone, phone);
        HiveHelp.write(Keys.userName, phone);
      } else if (email.isNotEmpty) {
        HiveHelp.write(Keys.userName, email);
      } else if (displayName.isNotEmpty) {
        HiveHelp.write(Keys.userName, displayName);
      }

      // Background registration sync with backend
      _syncGoogleUserToBackend(
        name: displayName.isNotEmpty ? displayName : 'Merchant',
        email: email,
        phone: phone,
      );

      isGoogleLoading = false;
      _notifyAuthSubmission();

      final bool onboardingCompleted =
          HiveHelp.read('onboarding_completed') ?? false;
      if (!onboardingCompleted) {
        Get.offAllNamed(RoutesName.merchantOnboardingWizardScreen);
      } else {
        await _navigatePostAuthentication();
      }
    } on GoogleSignInException catch (e) {
      isGoogleLoading = false;
      if (e.code.name != 'canceled') {
        loginErrorMessage =
            'Google Sign-In error: ${e.description ?? e.code.name}';
      }
      _notifyAuthSubmission();
    } on FirebaseAuthException catch (e) {
      isGoogleLoading = false;
      loginErrorMessage =
          e.message ?? 'Firebase authentication failed (${e.code}).';
      _notifyAuthSubmission();
    } catch (e) {
      isGoogleLoading = false;
      final errStr = e.toString().toLowerCase();
      if (!errStr.contains('canceled') && !errStr.contains('cancelled')) {
        loginErrorMessage = 'Google Sign-In failed: $e';
      }
      _notifyAuthSubmission();
    }
  }

  Future<void> _syncGoogleUserToBackend({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final List<String> nameParts = name.split(' ');
      final String firstName = nameParts.first;
      final String lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Merchant';
      final String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final String effectiveEmail =
          email.isNotEmpty ? email : '$cleanPhone@merchant.udharcard.shop';
      final String effectivePhone =
          cleanPhone.isNotEmpty ? cleanPhone : '0000000000';

      await AuthRepo.register(
        data: {
          "name": name,
          "firstname": firstName,
          "lastname": lastName,
          "phone": effectivePhone,
          "mobile": effectivePhone,
          "username": effectivePhone != '0000000000'
              ? effectivePhone
              : effectiveEmail,
          "shop_name": name,
          "business_name": name,
          "email": effectiveEmail,
          "password": "merchant_google_auth",
          "password_confirmation": "merchant_google_auth",
          "phone_code": "+91",
          "country": "India",
          "country_code": "IN",
          "type": "merchant",
        },
      );
    } catch (_) {
      // Offline fallback: allow onboarding to proceed
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
