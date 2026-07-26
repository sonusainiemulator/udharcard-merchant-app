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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  FocusNode node = FocusNode();
  @override
  void initState() {
    node.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    AuthController controller = Get.find<AuthController>();
    TextTheme t = Theme.of(context).textTheme;
    //--------------REMEMBER ME----------------
    if (HiveHelp.read(Keys.userName) != null &&
        HiveHelp.read(Keys.userPass) != null &&
        HiveHelp.read(Keys.isRemember) != null) {
      if (HiveHelp.read(Keys.isRemember) == true) {
        controller.userNameEditingController.text = HiveHelp.read(
          Keys.userName,
        );
        controller.signInPassEditingController.text = HiveHelp.read(
          Keys.userPass,
        );
        controller.userNameVal = HiveHelp.read(Keys.userName);
        controller.singInPassVal = HiveHelp.read(Keys.userPass);
      }
    }
    if (HiveHelp.read(Keys.isRemember) != null) {
      controller.isRemember = HiveHelp.read(Keys.isRemember);
    }
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
                        VSpace(80.h),
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
                        VSpace(40.h),
                        Text(
                          storedLanguage['Log In'] ?? "Log In",
                          style: t.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 30.sp,
                          ),
                        ),
                        VSpace(12.h),
                        Text(
                          storedLanguage['Hello there, log in to continue!'] ??
                              "Hello there, log in to continue!",
                          style: t.displayMedium?.copyWith(
                            color: AppThemes.getParagraphColor(),
                          ),
                        ),
                        VSpace(100.h),
                        CustomTextField(
                          hintext:
                              storedLanguage['Username or Email'] ??
                              "Username or Email",
                          isPrefixIcon: true,
                          prefixIcon: 'person',
                          autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber, AutofillHints.username],
                          controller: controller.userNameEditingController,
                          onChanged: (v) {
                            controller.userNameVal = v;
                            controller.update();
                          },
                        ),
                        VSpace(32.h),
                        CustomTextField(
                          hintext: storedLanguage['Password'] ?? "Password",
                          isPrefixIcon: true,
                          isSuffixIcon: true,
                          obsCureText: controller.isNewPassShow ? true : false,
                          prefixIcon: 'lock',
                          suffixIcon:
                              controller.isNewPassShow ? 'hide' : 'show',
                          controller: controller.signInPassEditingController,
                          onChanged: (v) {
                            controller.singInPassVal = v;
                            controller.update();
                          },
                          onSuffixPressed: () {
                            controller.isNewPassShow =
                                !controller.isNewPassShow;
                            controller.update();
                          },
                        ),
                        VSpace(24.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Transform.scale(
                                  scale: .82,
                                  child: Checkbox(
                                    checkColor: AppColors.blackColor,
                                    activeColor: AppColors.mainColor,
                                    visualDensity: const VisualDensity(
                                      horizontal:
                                          -4.0, // Adjust the horizontal padding
                                      vertical:
                                          -4.0, // Adjust the vertical padding
                                    ),
                                    side: BorderSide(
                                      color: AppThemes.getHintColor(),
                                    ),
                                    value: controller.isRemember,
                                    onChanged: (v) {
                                      controller.isRemember = v!;
                                      HiveHelp.write(Keys.isRemember, v);
                                      controller.update();
                                    },
                                  ),
                                ),
                                HSpace(5.w),
                                Text(
                                  storedLanguage['Remember me'] ??
                                      "Remember me",
                                  style: t.bodySmall?.copyWith(
                                    fontSize: 16.sp,
                                    color:
                                        Get.isDarkMode
                                            ? AppColors.whiteColor
                                            : AppColors.black30,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                Get.toNamed(RoutesName.forgotPassScreen);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                child: Text(
                                  storedLanguage['Forgot Your Password?'] ??
                                      "Forgot Your Password?",
                                  style: t.displayMedium?.copyWith(
                                    fontSize: 18.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (controller.loginErrorMessage != null) ...[
                          VSpace(20.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: AppColors.redColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColors.redColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.redColor,
                                  size: 20.sp,
                                ),
                                HSpace(10.w),
                                Expanded(
                                  child: Text(
                                    controller.loginErrorMessage!,
                                    style: t.bodyMedium?.copyWith(
                                      color: AppColors.redColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        VSpace(48.h),
                        Material(
                          color: Colors.transparent,
                          child: AppButton(
                            text: storedLanguage['Log In'] ?? "Log In",
                            isLoading: controller.isLoading ? true : false,
                            bgColor:
                                controller.userNameVal.isEmpty ||
                                        controller.singInPassVal.isEmpty
                                    ? AppThemes.getInactiveColor()
                                    : AppColors.mainColor,
                            onTap:
                                controller.userNameVal.isEmpty ||
                                        controller.singInPassVal.isEmpty
                                    ? null
                                    : controller.isLoading
                                    ? null
                                    : () async {
                                      Helpers.hideKeyboard();
                                      await controller.login();
                                    },
                          ),
                        ),
                        VSpace(24.h),
                        Material(
                          color: Colors.transparent,
                          child: AppButton(
                            text: storedLanguage['Login with Phone / WhatsApp'] ?? "Login with Phone / WhatsApp",
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
                              storedLanguage["Don't have an account?"] ??
                                  "Don't have an account? ",
                              style: t.displayMedium?.copyWith(
                                fontSize: 16.sp,
                                color: AppThemes.getParagraphColor(),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Get.toNamed(RoutesName.registerScreen);
                                controller.clearSignInController();
                              },
                              child: Text(
                                storedLanguage["Create account"] ?? "Create account",
                                style: t.titleMedium?.copyWith(
                                  fontSize: 16.sp,
                                  color: AppColors.mainColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
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
