import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/views/widgets/custom_textfield.dart';
import 'package:get/get.dart';
import '../../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/spacing.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  FocusNode nameNode = FocusNode();
  FocusNode emailNode = FocusNode();
  FocusNode phoneNode = FocusNode();
  FocusNode shopNode = FocusNode();
  FocusNode passNode = FocusNode();
  FocusNode confirmPassNode = FocusNode();

  @override
  void initState() {
    super.initState();
    nameNode.addListener(() => setState(() {}));
    emailNode.addListener(() => setState(() {}));
    phoneNode.addListener(() => setState(() {}));
    shopNode.addListener(() => setState(() {}));
    passNode.addListener(() => setState(() {}));
    confirmPassNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameNode.dispose();
    emailNode.dispose();
    phoneNode.dispose();
    shopNode.dispose();
    passNode.dispose();
    confirmPassNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    AuthController controller = Get.find<AuthController>();
    TextTheme t = Theme.of(context).textTheme;

    return GetBuilder<AuthController>(
      builder: (_) {
        return Scaffold(
          body: Container(
            height: Dimensions.screenHeight,
            width: Dimensions.screenWidth,
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    "$rootImageDir/shape.png",
                    height: 153.h,
                    fit: BoxFit.cover,
                    color: AppColors.mainColor.withValues(alpha: .1),
                  ),
                ),
                Padding(
                  padding: Dimensions.kDefaultPadding,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        VSpace(60.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "$rootImageDir/app_logo.png",
                              height: 60.h,
                              fit: BoxFit.contain,
                            ),
                            HSpace(10.w),
                            Text(
                              "Merchant",
                              style: t.titleLarge?.copyWith(
                                color: AppColors.mainColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 24.sp,
                              ),
                            ),
                          ],
                        ),
                        VSpace(30.h),
                        Text(
                          storedLanguage['Sign Up'] ?? "Sign Up",
                          style: t.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 30.sp,
                          ),
                        ),
                        VSpace(12.h),
                        Text(
                          storedLanguage['Create a new account to continue!'] ??
                              "Create a new account to continue!",
                          style: t.displayMedium?.copyWith(
                            color: AppThemes.getParagraphColor(),
                          ),
                        ),
                        VSpace(40.h),
                        CustomTextField(
                          hintext: storedLanguage['Full Name'] ?? "Full Name",
                          isPrefixIcon: true,
                          prefixIcon: 'person',
                          focusNode: nameNode,
                          controller: controller.nameEditingController,
                          onChanged: (v) {
                            controller.nameVal = v;
                            controller.update();
                          },
                        ),
                        VSpace(20.h),
                        CustomTextField(
                          hintext: storedLanguage['Email Address'] ?? "Email Address",
                          isPrefixIcon: true,
                          prefixIcon: 'email',
                          focusNode: emailNode,
                          controller: controller.emailEditingController,
                          onChanged: (v) {
                            controller.emailVal = v;
                            controller.update();
                          },
                        ),
                        VSpace(20.h),
                        CustomTextField(
                          hintext: storedLanguage['Phone Number'] ?? "Phone Number",
                          isPrefixIcon: true,
                          prefixIcon: 'call',
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          focusNode: phoneNode,
                          controller: controller.phoneEditingController,
                          onChanged: (v) {
                            controller.phoneVal = v;
                            controller.update();
                          },
                        ),
                        VSpace(20.h),
                        CustomTextField(
                          hintext: storedLanguage['Shop Name'] ?? "Shop Name",
                          isPrefixIcon: true,
                          prefixIcon: 'person',
                          focusNode: shopNode,
                          controller: controller.shopNameEditingController,
                          onChanged: (v) {
                            controller.shopNameVal = v;
                            controller.update();
                          },
                        ),
                        VSpace(20.h),
                        CustomTextField(
                          hintext: storedLanguage['Password'] ?? "Password",
                          isPrefixIcon: true,
                          isSuffixIcon: true,
                          obsCureText: controller.isRegisterPassShow ? true : false,
                          prefixIcon: 'lock',
                          suffixIcon:
                              controller.isRegisterPassShow ? 'hide' : 'show',
                          focusNode: passNode,
                          controller: controller.passwordEditingController,
                          onChanged: (v) {
                            controller.passwordVal = v;
                            controller.update();
                          },
                          onSuffixPressed: () {
                            controller.isRegisterPassShow =
                                !controller.isRegisterPassShow;
                            controller.update();
                          },
                        ),
                        VSpace(20.h),
                        CustomTextField(
                          hintext: storedLanguage['Confirm Password'] ?? "Confirm Password",
                          isPrefixIcon: true,
                          isSuffixIcon: true,
                          obsCureText: controller.isRegisterConfirmPassShow ? true : false,
                          prefixIcon: 'lock',
                          suffixIcon:
                              controller.isRegisterConfirmPassShow ? 'hide' : 'show',
                          focusNode: confirmPassNode,
                          controller: controller.confirmPasswordEditingController,
                          onChanged: (v) {
                            controller.confirmPasswordVal = v;
                            controller.update();
                          },
                          onSuffixPressed: () {
                            controller.isRegisterConfirmPassShow =
                                !controller.isRegisterConfirmPassShow;
                            controller.update();
                          },
                        ),
                        VSpace(30.h),
                        Material(
                          color: Colors.transparent,
                          child: AppButton(
                            text: storedLanguage['Sign Up'] ?? "Sign Up",
                            isLoading: controller.isLoading ? true : false,
                            bgColor: controller.nameVal.isEmpty ||
                                    controller.emailVal.isEmpty ||
                                    controller.phoneVal.isEmpty ||
                                    controller.shopNameVal.isEmpty ||
                                    controller.passwordVal.isEmpty ||
                                    controller.confirmPasswordVal.isEmpty
                                ? AppThemes.getInactiveColor()
                                : AppColors.mainColor,
                            onTap: controller.nameVal.isEmpty ||
                                    controller.emailVal.isEmpty ||
                                    controller.phoneVal.isEmpty ||
                                    controller.shopNameVal.isEmpty ||
                                    controller.passwordVal.isEmpty ||
                                    controller.confirmPasswordVal.isEmpty
                                ? null
                                : controller.isLoading
                                ? null
                                : () async {
                                    if (controller.passwordVal != controller.confirmPasswordVal) {
                                      Helpers.showSnackBar(msg: "Passwords do not match");
                                      return;
                                    }
                                    Helpers.hideKeyboard();
                                    await controller.register();
                                  },
                          ),
                        ),
                        VSpace(24.h),
                        Material(
                          color: Colors.transparent,
                          child: AppButton(
                            text: storedLanguage['Register with Phone / WhatsApp'] ?? "Register with Phone / WhatsApp",
                            isLoading: false,
                            bgColor: AppColors.mainColor.withValues(alpha: 0.1),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mainColor,
                                ),
                            onTap: () {
                              Get.toNamed(RoutesName.firebasePhoneLoginScreen);
                              controller.clearFirebaseOtpController();
                            },
                          ),
                        ),
                        VSpace(30.h),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.borderColor, thickness: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                storedLanguage['Or connect with'] ?? 'Or connect with',
                                style: t.bodySmall?.copyWith(color: AppColors.black50, fontSize: 14.sp),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.borderColor, thickness: 1)),
                          ],
                        ),
                        VSpace(30.h),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  controller.signInWithGoogle();
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: AppColors.borderColor),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        "$rootImageDir/google.png",
                                        height: 24.h,
                                        width: 24.w,
                                      ),
                                      HSpace(8.w),
                                      Text(
                                        storedLanguage['Google'] ?? 'Google',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            HSpace(16.w),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  controller.signInWithApple();
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: AppColors.borderColor),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        "$rootImageDir/apple.png",
                                        height: 24.h,
                                        width: 24.w,
                                        color: Get.isDarkMode ? AppColors.whiteColor : AppColors.blackColor,
                                      ),
                                      HSpace(8.w),
                                      Text(
                                        storedLanguage['Apple'] ?? 'Apple',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        VSpace(32.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              storedLanguage["Already have an account?"] ??
                                  "Already have an account? ",
                              style: t.displayMedium?.copyWith(
                                fontSize: 16.sp,
                                color: AppThemes.getParagraphColor(),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Get.offAllNamed(RoutesName.loginScreen);
                                controller.clearRegisterController();
                              },
                              child: Text(
                                storedLanguage["Log In"] ?? "Log In",
                                style: t.titleMedium?.copyWith(
                                  fontSize: 16.sp,
                                  color: AppColors.mainColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        VSpace(30.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
