import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/auth_controller.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:paysecure/views/widgets/fintech_auth_widgets.dart';

class FirebaseOtpVerifyScreen extends StatefulWidget {
  const FirebaseOtpVerifyScreen({super.key});

  @override
  State<FirebaseOtpVerifyScreen> createState() => _FirebaseOtpVerifyScreenState();
}

class _FirebaseOtpVerifyScreenState extends State<FirebaseOtpVerifyScreen> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _authController.firebaseOtpController.addListener(_refreshForm);
  }

  void _refreshForm() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authController.firebaseOtpController.removeListener(_refreshForm);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    final otpCode = _authController.firebaseOtpController.text.trim();
    final canVerify = otpCode.length >= 6;

    return FintechAuthPage(
      eyebrow: 'OTP Verification',
      title: storedLanguage['Verify OTP'] ?? "Verify OTP",
      subtitle:
          storedLanguage['Enter the 6-digit code sent to your phone'] ??
          "Enter the 6-digit verification code sent to your mobile number.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FintechTextField(
            label: 'Verification Code (OTP)',
            hint: 'Enter 6-digit code',
            controller: _authController.firebaseOtpController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.done,
            onChanged: (val) {
              _authController.firebaseOtpVal = val.trim();
            },
            prefix: const Icon(
              Icons.lock_clock_outlined,
              color: Color(0xFF667085),
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
                  label: storedLanguage['Verify'] ?? "Verify OTP",
                  isLoading: controller.isLoading,
                  onPressed: canVerify
                      ? () async {
                          Helpers.hideKeyboard();
                          await controller.verifyFirebaseOtp();
                        }
                      : null,
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          Center(
            child: TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Change phone number',
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
