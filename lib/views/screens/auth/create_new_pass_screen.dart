import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/auth_controller.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:paysecure/views/widgets/fintech_auth_widgets.dart';

class CreateNewPassScreen extends StatefulWidget {
  const CreateNewPassScreen({super.key});

  @override
  State<CreateNewPassScreen> createState() => _CreateNewPassScreenState();
}

class _CreateNewPassScreenState extends State<CreateNewPassScreen> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _authController.forgotPassNewPassEditingController.addListener(_refreshForm);
    _authController.forgotPassConfirmPassEditingController.addListener(_refreshForm);
  }

  void _refreshForm() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authController.forgotPassNewPassEditingController.removeListener(_refreshForm);
    _authController.forgotPassConfirmPassEditingController.removeListener(_refreshForm);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    final newPass = _authController.forgotPassNewPassEditingController.text.trim();
    final confirmPass = _authController.forgotPassConfirmPassEditingController.text.trim();
    final canSubmit = newPass.length >= 6 && confirmPass.isNotEmpty;

    return GetBuilder<AuthController>(
      builder: (controller) {
        return FintechAuthPage(
          eyebrow: 'New Security Password',
          title: storedLanguage['Create New Password'] ?? 'Create New Password',
          subtitle:
              storedLanguage['Set the new password for your account so that you can login'] ??
              'Set a strong password for your merchant account to keep your finances secure.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FintechTextField(
                label: 'New Password',
                hint: storedLanguage['New Password'] ?? 'New Password',
                controller: controller.forgotPassNewPassEditingController,
                textInputAction: TextInputAction.next,
                onChanged: (val) {
                  controller.forgotPassNewPassVal = val.trim();
                },
                prefix: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF667085),
                ),
              ),
              SizedBox(height: 16.h),
              FintechTextField(
                label: 'Confirm Password',
                hint: storedLanguage['Confirm Password'] ?? 'Confirm Password',
                controller: controller.forgotPassConfirmPassEditingController,
                textInputAction: TextInputAction.done,
                onChanged: (val) {
                  controller.forgotPassConfirmPassVal = val.trim();
                },
                prefix: const Icon(
                  Icons.lock_reset_rounded,
                  color: Color(0xFF667085),
                ),
              ),
              SizedBox(height: 24.h),
              if (controller.loginErrorMessage != null)
                FintechErrorMessage(
                  message: controller.loginErrorMessage!,
                ),
              FintechPrimaryButton(
                label: storedLanguage['Continue'] ?? "Update Password",
                isLoading: controller.isLoading,
                onPressed: canSubmit
                    ? () async {
                        if (newPass != confirmPass) {
                          Helpers.showSnackBar(
                            msg: "New Password and Confirm Password do not match!",
                            title: "Error",
                          );
                        } else {
                          Helpers.hideKeyboard();
                          await controller.updatePass();
                        }
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
