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
    _authController.firebaseOtpVal =
        _authController.firebaseOtpController.text.trim();
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
    final phoneDisplay = _authController.activeAuthPhoneNumber.isNotEmpty
        ? _authController.activeAuthPhoneNumber
        : "your mobile number";

    return FintechAuthPage(
      eyebrow: 'OTP Verification',
      title: storedLanguage['Verify OTP'] ?? "Verify OTP",
      subtitle: "Enter the 6-digit verification code sent to $phoneDisplay.",
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
              if (val.trim().length == 6) {
                Helpers.hideKeyboard();
                _authController.verifyFirebaseOtp();
              }
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
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive code? ",
                      style: TextStyle(
                        color: const Color(0xFF667085),
                        fontSize: 13.sp,
                      ),
                    ),
                    if (controller.otpCountdown > 0)
                      Text(
                        'Resend in ${controller.otpCountdown}s',
                        style: TextStyle(
                          color: const Color(0xFF101828),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: controller.isLoading
                            ? null
                            : () async {
                                Helpers.hideKeyboard();
                                await controller.resendFirebaseOtp();
                              },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: const Color(0xFF175CD3),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
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
