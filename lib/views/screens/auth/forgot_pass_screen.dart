import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/auth_controller.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:paysecure/views/widgets/fintech_auth_widgets.dart';

class ForgotPassScreen extends StatefulWidget {
  const ForgotPassScreen({super.key});

  @override
  State<ForgotPassScreen> createState() => _ForgotPassScreenState();
}

class _ForgotPassScreenState extends State<ForgotPassScreen> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _authController.forgotPassEmailEditingController.addListener(_refreshForm);
  }

  void _refreshForm() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authController.forgotPassEmailEditingController.removeListener(_refreshForm);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    final emailText = _authController.forgotPassEmailEditingController.text.trim();
    final canSend = emailText.contains('@') && emailText.length > 5;

    return FintechAuthPage(
      eyebrow: 'Account Recovery',
      title: storedLanguage['Forgot Password'] ?? 'Forgot Password',
      subtitle:
          storedLanguage['Please enter your email address to receive a verification code'] ??
          'Enter your registered email address to receive password reset instructions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FintechTextField(
            label: 'Email address',
            hint: storedLanguage['Enter Email Address'] ?? 'Enter Email Address',
            controller: _authController.forgotPassEmailEditingController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onChanged: (val) {
              _authController.forgotPassEmailVal = val.trim();
            },
            prefix: const Icon(
              Icons.email_outlined,
              color: Color(0xFF667085),
            ),
          ),
          SizedBox(height: 24.h),
          GetBuilder<AuthController>(
            id: AuthController.authSubmissionUpdateId,
            builder: (controller) => Column(
              children: [
                if (controller.loginErrorMessage != null)
                  FintechErrorMessage(
                    message: controller.loginErrorMessage!,
                  ),
                FintechPrimaryButton(
                  label: storedLanguage['Send Code'] ?? "Send Code",
                  isLoading: controller.isLoading,
                  onPressed: canSend
                      ? () async {
                          Helpers.hideKeyboard();
                          await controller.forgotPass();
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
                'Remember password? Log in',
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
