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
import '../routes/routes_name.dart';
import '../utils/services/localstorage/keys.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  bool isLoading = false;

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
          Get.offAllNamed(RoutesName.bottomNavBar);
          clearSignInController();
        } else {
          loginErrorMessage = data['message']?.toString() ?? 'Invalid credentials';
        }
      } else {
        loginErrorMessage = data['message']?.toString() ?? 'Invalid credentials';
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
  TextEditingController confirmPasswordEditingController = TextEditingController();

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

  Future register() async {
    isLoading = true;
    update();
    try {
      http.Response response = await AuthRepo.register(
        data: {
          "name": nameVal,
          "email": emailVal,
          "phone": phoneVal,
          "shop_name": shopNameVal,
          "password": passwordVal,
          "password_confirmation": confirmPasswordVal,
        },
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
        Helpers.showSnackBar(msg: data['message']?.toString() ?? 'Registration failed');
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

  clearFirebaseOtpController() {
    firebasePhoneController.clear();
    firebaseOtpController.clear();
    firebasePhoneVal = "";
    firebaseOtpVal = "";
    firebaseVerificationId = null;
  }

  Future sendFirebaseOtp(String phoneNumber) async {
    isLoading = true;
    loginErrorMessage = null;
    update();
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (Android only)
          await _signInWithFirebaseCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          isLoading = false;
          loginErrorMessage = e.message ?? 'Verification failed';
          update();
          Helpers.showSnackBar(msg: e.message ?? 'Verification failed', title: "Error!");
        },
        codeSent: (String verificationId, int? resendToken) {
          isLoading = false;
          firebaseVerificationId = verificationId;
          loginErrorMessage = null;
          update();
          Helpers.showSnackBar(msg: "Verification code sent to $phoneNumber", title: "Success");
          Get.toNamed(RoutesName.firebaseOtpVerifyScreen);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          firebaseVerificationId = verificationId;
        },
      );
    } catch (e) {
      isLoading = false;
      loginErrorMessage = 'Failed to send OTP: $e';
      update();
      Helpers.showSnackBar(msg: 'Failed to send OTP: $e', title: "Error!");
    }
  }

  Future verifyFirebaseOtp() async {
    if (firebaseVerificationId == null || firebaseOtpVal.isEmpty) return;
    isLoading = true;
    loginErrorMessage = null;
    update();
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: firebaseVerificationId!,
        smsCode: firebaseOtpVal,
      );
      await _signInWithFirebaseCredential(credential);
    } catch (e) {
      isLoading = false;
      loginErrorMessage = 'Invalid OTP or verification failed.';
      update();
      Helpers.showSnackBar(msg: 'Invalid OTP or verification failed.', title: "Error!");
    }
  }

  Future _signInWithFirebaseCredential(PhoneAuthCredential credential) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        String? token = await userCredential.user!.getIdToken();
        token ??= "firebase_auth_token_${userCredential.user!.uid}";
        
        // Persist merchant session permanently into local storage
        HiveHelp.write(Keys.token, token);
        HiveHelp.write(Keys.isNewUser, false);
        HiveHelp.write(Keys.isRemember, true);
        HiveHelp.write(Keys.userId, userCredential.user!.uid);
        if (userCredential.user?.phoneNumber != null && userCredential.user!.phoneNumber!.isNotEmpty) {
          HiveHelp.write(Keys.userName, userCredential.user!.phoneNumber);
        }
        
        isLoading = false;
        update();
        Get.offAllNamed(RoutesName.bottomNavBar);
        clearFirebaseOtpController();
        clearRegisterController();
      }
    } catch (e) {
      isLoading = false;
      update();
      Helpers.showSnackBar(msg: 'Sign in failed: $e');
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
      Helpers.showSnackBar(msg: 'Google Sign-In is not fully configured yet. Backend integration required.', title: 'Coming Soon');
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
      Helpers.showSnackBar(msg: 'Apple Sign-In is not fully configured yet. Backend integration required.', title: 'Coming Soon');
    } catch (e) {
      loginErrorMessage = 'Apple Sign-In failed: $e';
    } finally {
      isLoading = false;
      update();
    }
  }
}
