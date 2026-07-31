import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../utils/services/helpers.dart';
import '../../widgets/fintech_auth_widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

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
              hint: 'Enter 10-digit mobile number',
              controller: authController.firebasePhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
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
              builder: (controller) => Column(
                children: [
                  if (controller.loginErrorMessage != null)
                    FintechErrorMessage(
                      message: controller.loginErrorMessage!,
                    ),
                  FintechPrimaryButton(
                    label: 'Continue with OTP',
                    isLoading: controller.isLoading,
                    onPressed: () async {
                      Helpers.hideKeyboard();
                      final phone =
                          controller.firebasePhoneController.text.trim();
                      if (phone.length < 10) {
                        controller.loginErrorMessage =
                            'Please enter a valid 10-digit mobile number.';
                        controller.update(
                          [AuthController.authSubmissionUpdateId],
                        );
                        return;
                      }
                      await controller.sendFirebaseOtp(phone, isLogin: true);
                    },
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
