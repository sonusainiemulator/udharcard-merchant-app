import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/auth_controller.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:paysecure/views/widgets/fintech_auth_widgets.dart';

class FirebasePhoneLoginScreen extends StatefulWidget {
  const FirebasePhoneLoginScreen({super.key});

  @override
  State<FirebasePhoneLoginScreen> createState() => _FirebasePhoneLoginScreenState();
}

class _FirebasePhoneLoginScreenState extends State<FirebasePhoneLoginScreen> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _authController.firebasePhoneController.addListener(_refreshForm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authController.clearFirebaseOtpController();
    });
  }

  void _refreshForm() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authController.firebasePhoneController.removeListener(_refreshForm);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    final phoneText = _authController.firebasePhoneController.text.trim();
    final canSubmit = phoneText.length == 10;

    return FintechAuthPage(
      eyebrow: 'Fast Authentication',
      title: storedLanguage['Phone Login'] ?? "Phone Login",
      subtitle:
          storedLanguage['Enter your phone number to continue'] ??
          "Enter your mobile number to receive a one-time verification code.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FintechTextField(
            label: 'Mobile number',
            hint: storedLanguage['Phone Number'] ?? "Phone Number",
            controller: _authController.firebasePhoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            autofillHints: const [AutofillHints.telephoneNumber],
            prefix: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "🇮🇳 +91",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    width: 1.w,
                    height: 20.h,
                    color: const Color(0xFFD0D5DD),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
          GetBuilder<AuthController>(
            id: AuthController.authSubmissionUpdateId,
            builder: (controller) => Column(
              children: [
                if (controller.loginErrorMessage != null)
                  FintechErrorMessage(
                    message: controller.loginErrorMessage!,
                  ),
                FintechPrimaryButton(
                  label: storedLanguage['Send OTP via SMS'] ?? "Send OTP via SMS",
                  isLoading: controller.isLoading,
                  onPressed: canSubmit
                      ? () async {
                          Helpers.hideKeyboard();
                          await controller.sendFirebaseOtp(phoneText, isLogin: true);
                        }
                      : null,
                ),
                SizedBox(height: 12.h),
                OutlinedButton(
                  onPressed: canSubmit
                      ? () {
                          Helpers.hideKeyboard();
                          Helpers.showSnackBar(
                            msg: "WhatsApp OTP verification is coming soon!",
                            title: "Coming Soon",
                          );
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48.h),
                    side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
                      SizedBox(width: 8.w),
                      Text(
                        'Send OTP via WhatsApp (Soon)',
                        style: TextStyle(
                          color: const Color(0xFF25D366),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          Center(
            child: TextButton(
              onPressed: () {
                Get.back();
                _authController.clearFirebaseOtpController();
              },
              child: Text(
                storedLanguage["Back to Login"] ?? "Back to Login",
                style: TextStyle(
                  color: const Color(0xFF175CD3),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
