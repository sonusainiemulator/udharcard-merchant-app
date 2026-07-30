import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../utils/services/helpers.dart';
import '../../widgets/fintech_auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _authController.firebasePhoneController.addListener(_refreshForm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authController.clearFirebaseOtpController();
      if (mounted) setState(() {});
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
    final phoneText = _authController.firebasePhoneController.text.trim();
    final canContinue = phoneText.length >= 7;

    return FintechAuthPage(
      eyebrow: 'Merchant access',
      title: 'Welcome back',
      subtitle:
          'Enter your registered mobile number to securely access your merchant account.',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FintechTextField(
              label: 'Mobile number',
              hint: 'Enter mobile number',
              controller: _authController.firebasePhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                LengthLimitingTextInputFormatter(15),
              ],
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.done,
              prefix: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'IN',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    height: 22.h,
                    width: 1,
                    color: const Color(0xFFD0D5DD),
                  ),
                  SizedBox(width: 6.w),
                  const Text(
                    '+91',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            GetBuilder<AuthController>(
              id: AuthController.authSubmissionUpdateId,
              builder:
                  (controller) => Column(
                    children: [
                      if (controller.loginErrorMessage != null)
                        FintechErrorMessage(
                          message: controller.loginErrorMessage!,
                        ),
                      FintechPrimaryButton(
                        label: 'Continue with OTP',
                        isLoading: controller.isLoading,
                        onPressed:
                            canContinue
                                ? () async {
                                  Helpers.hideKeyboard();
                                  await controller.sendFirebaseOtp(
                                    controller.firebasePhoneController.text
                                        .trim(),
                                  );
                                }
                                : null,
                      ),
                    ],
                  ),
            ),
            SizedBox(height: 16.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16.sp,
                  color: const Color(0xFF667085),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'We will send a one-time verification code. Your mobile number is never shared.',
                    style: TextStyle(
                      color: const Color(0xFF667085),
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 22.h),
            const Divider(color: Color(0xFFEAECF0)),
            SizedBox(height: 14.h),
            Center(
              child: TextButton(
                onPressed: () => Get.toNamed(RoutesName.registerScreen),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: const Color(0xFF667085),
                      fontSize: 13.sp,
                    ),
                    children: const [
                      TextSpan(text: 'New to UdharCard? '),
                      TextSpan(
                        text: 'Create merchant account',
                        style: TextStyle(
                          color: Color(0xFF175CD3),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
