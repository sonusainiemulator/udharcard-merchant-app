import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
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

class ForgotPassScreen extends StatelessWidget {
  const ForgotPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AuthController controller = Get.find<AuthController>();
    TextTheme t = Theme.of(context).textTheme;
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<AuthController>(builder: (_) {
      return Scaffold(
          appBar: CustomAppBar(
            title: storedLanguage['Forgot Password'] ?? 'Forgot Password',
            actions: [],
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
                        "$rootImageDir/forgot_pass_header.png",
                        height: 200.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  VSpace(59.h),
                  Center(
                    child: Text(
                      "Please enter your email address to\nreceive a verification code",
                      textAlign: TextAlign.center,
                      style: t.displayMedium?.copyWith(
                          color: AppThemes.getParagraphColor(), height: 1.5),
                    ),
                  ),
                  VSpace(60.h),
                  CustomTextField(
                    hintext: storedLanguage['Enter Email Address'] ??
                        "Enter Email Address",
                    isPrefixIcon: true,
                    prefixIcon: 'email',
                    controller: controller.forgotPassEmailEditingController,
                    onChanged: (v) {
                      controller.forgotPassEmailVal = v;
                      if (!v.contains('@')) {
                        controller.forgotPassEmailVal = "";
                      }
                      controller.update();
                    },
                  ),
                  VSpace(48.h),
                  AppButton(
                    text: storedLanguage['Send Code'] ?? "Send Code",
                    isLoading: controller.isLoading ? true : false,
                    onTap: controller.isLoading
                        ? null
                        : () async {
                            if (controller.forgotPassEmailEditingController.text
                                .isEmpty) {
                              Helpers.showSnackBar(
                                  msg: "Email field is required");
                            } else {
                              Helpers.hideKeyboard();
                              await controller.forgotPass();
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
