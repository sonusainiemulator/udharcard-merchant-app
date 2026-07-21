import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../controllers/auth_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/spacing.dart';

class CreateNewPassScreen extends StatelessWidget {
  const CreateNewPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    AuthController controller = Get.find<AuthController>();
    TextTheme t = Theme.of(context).textTheme;
    return GetBuilder<AuthController>(builder: (_) {
      return Scaffold(
          appBar: CustomAppBar(
            title:
                storedLanguage['Create New Password'] ?? 'Create New Password',
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: Dimensions.kDefaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 70.h),
                    child: Center(
                      child: Image.asset(
                        "$rootImageDir/new_pass_header.png",
                        height: 200.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  VSpace(60.h),
                  Center(
                    child: Text(
                      'Set the new password for your account so that\nyou can login and access all the features.',
                      textAlign: TextAlign.center,
                      style: t.displayMedium?.copyWith(
                          color: AppThemes.getParagraphColor(), height: 1.75),
                    ),
                  ),
                  VSpace(48.h),
                  CustomTextField(
                    hintext: storedLanguage['New Password'] ?? " New Password",
                    isPrefixIcon: true,
                    isSuffixIcon: true,
                    obsCureText: controller.isNewPassShow ? true : false,
                    prefixIcon: 'lock',
                    suffixIcon: controller.isNewPassShow ? 'hide' : 'show',
                    controller: controller.forgotPassNewPassEditingController,
                    onChanged: (v) {
                      controller.forgotPassNewPassVal = v;
                      controller.update();
                    },
                    onSuffixPressed: () {
                      controller.isNewPassShow = !controller.isNewPassShow;
                      controller.update();
                    },
                  ),
                  VSpace(40.h),
                  CustomTextField(
                    hintext: storedLanguage['Confirm Password'] ??
                        "Confirm Password",
                    isPrefixIcon: true,
                    isSuffixIcon: true,
                    obsCureText: controller.isConfirmPassShow ? true : false,
                    prefixIcon: 'lock',
                    suffixIcon: controller.isConfirmPassShow ? 'hide' : 'show',
                    controller:
                        controller.forgotPassConfirmPassEditingController,
                    onChanged: (v) {
                      controller.forgotPassConfirmPassVal = v;
                      controller.update();
                    },
                    onSuffixPressed: () {
                      controller.isConfirmPassShow =
                          !controller.isConfirmPassShow;
                      controller.update();
                    },
                  ),
                  VSpace(60.h),
                  AppButton(
                    text: storedLanguage['Continue'] ?? "Continue",
                    isLoading: controller.isLoading ? true : false,
                    bgColor: controller.forgotPassNewPassVal.isEmpty ||
                            controller.forgotPassConfirmPassVal.isEmpty
                        ? AppThemes.getInactiveColor()
                        : AppColors.mainColor,
                    onTap: controller.forgotPassNewPassVal.isEmpty ||
                            controller.forgotPassConfirmPassVal.isEmpty
                        ? null
                        : controller.isLoading
                            ? null
                            : () async {
                                if (controller
                                        .forgotPassNewPassEditingController
                                        .text !=
                                    controller
                                        .forgotPassConfirmPassEditingController
                                        .text) {
                                  Helpers.showSnackBar(
                                      msg:
                                          "New Password and Confirm Password didn't match!");
                                } else {
                                  Helpers.hideKeyboard();
                                  await controller.updatePass();
                                }
                              },
                  ),
                ],
              ),
            ),
          ));
    });
  }
}
