import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../utils/services/helpers.dart';
import '../../widgets/fintech_auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    for (final controller in _formControllers) {
      controller.addListener(_refreshForm);
    }
  }

  List<TextEditingController> get _formControllers => [
    _authController.nameEditingController,
    _authController.phoneEditingController,
    _authController.shopNameEditingController,
    _authController.emailEditingController,
  ];

  void _refreshForm() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _formControllers) {
      controller.removeListener(_refreshForm);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return FintechAuthPage(
      eyebrow: 'Merchant onboarding',
      title: 'Build your business profile',
      subtitle: 'Set up your merchant account in a few secure steps.',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FintechTextField(
              label: 'Full name',
              hint: 'Your name',
              controller: _authController.nameEditingController,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              onChanged: (value) => _authController.nameVal = value.trim(),
            ),
            SizedBox(height: 16.h),
            FintechTextField(
              label: 'Business name',
              hint: 'Your shop or business name',
              controller: _authController.shopNameEditingController,
              textInputAction: TextInputAction.next,
              onChanged: (value) => _authController.shopNameVal = value.trim(),
            ),
            SizedBox(height: 16.h),
            FintechTextField(
              label: 'Mobile number',
              hint: 'Enter 10-digit mobile number',
              controller: _authController.phoneEditingController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.next,
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
              onChanged: (value) => _authController.phoneVal = value.trim(),
            ),
            SizedBox(height: 16.h),
            FintechTextField(
              label: 'Email address (optional)',
              hint: 'you@business.com',
              controller: _authController.emailEditingController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onChanged: (value) => _authController.emailVal = value.trim(),
            ),
            SizedBox(height: 20.h),
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
                        label: 'Verify mobile number & Register',
                        isLoading: controller.isLoading,
                        onPressed: () async {
                          Helpers.hideKeyboard();
                          final name = _authController.nameEditingController.text.trim();
                          final shop = _authController.shopNameEditingController.text.trim();
                          final phone = _authController.phoneEditingController.text.trim();

                          if (name.isEmpty) {
                            controller.loginErrorMessage = 'Please enter your full name.';
                            controller.update([AuthController.authSubmissionUpdateId]);
                            return;
                          }
                          if (shop.isEmpty) {
                            controller.loginErrorMessage = 'Please enter your business or shop name.';
                            controller.update([AuthController.authSubmissionUpdateId]);
                            return;
                          }
                          if (phone.length < 10) {
                            controller.loginErrorMessage = 'Please enter a valid 10-digit mobile number.';
                            controller.update([AuthController.authSubmissionUpdateId]);
                            return;
                          }

                          controller.firebasePhoneController.text = phone;
                          await controller.sendFirebaseOtp(phone, isLogin: false);
                        },
                      ),
                    ],
                  ),
            ),
            SizedBox(height: 14.h),
            Text(
              'By continuing, you confirm that you are authorised to register this business.',
              style: TextStyle(
                color: const Color(0xFF667085),
                fontSize: 11.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 18.h),
            Center(
              child: TextButton(
                onPressed: Get.back,
                child: Text(
                  'Already have an account? Log in',
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
      ),
    );
  }
}
