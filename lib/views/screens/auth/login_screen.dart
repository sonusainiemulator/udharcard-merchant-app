import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/views/widgets/auth_footer_branding.dart';
import 'package:paysecure/views/widgets/brand_icons.dart';
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

    bool isDark = Get.isDarkMode;

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
                    color: AppColors.mainColor.withValues(alpha: .08),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VSpace(30.h),
                          // Big Prominent Logo & Merchant Badge Header
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCardColor
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.mainColor.withValues(alpha: 0.15),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    "$rootImageDir/app_logo.png",
                                    height: 75.h,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                VSpace(12.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.mainColor,
                                        AppColors.mainColor.withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.mainColor.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.storefront_rounded,
                                        color: Colors.white,
                                        size: 15.sp,
                                      ),
                                      HSpace(6.w),
                                      Text(
                                        "MERCHANT PORTAL",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.sp,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          VSpace(28.h),
                          // Title & Subtitle
                          Text(
                            storedLanguage['Log In'] ?? "Log In 👋",
                            style: t.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 28.sp,
                            ),
                          ),
                          VSpace(6.h),
                          Text(
                            storedLanguage['Hello there, log in to continue!'] ??
                                "Log in to manage your shop ledger & transactions",
                            style: t.displayMedium?.copyWith(
                              color: AppThemes.getParagraphColor(),
                              fontSize: 14.sp,
                            ),
                          ),
                          VSpace(24.h),

                          // Username / Email Input
                          CustomTextField(
                            hintext:
                                storedLanguage['Username or Email'] ??
                                "Username or Email",
                            isPrefixIcon: true,
                            prefixIcon: 'person',
                            autofillHints: const [
                              AutofillHints.email,
                              AutofillHints.telephoneNumber,
                              AutofillHints.username,
                            ],
                            controller: controller.userNameEditingController,
                            onChanged: (v) {
                              controller.userNameVal = v;
                              controller.update();
                            },
                          ),
                          VSpace(16.h),

                          // Password Input
                          CustomTextField(
                            hintext: storedLanguage['Password'] ?? "Password",
                            isPrefixIcon: true,
                            isSuffixIcon: true,
                            obsCureText: controller.isNewPassShow,
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
                          VSpace(14.h),

                          // Remember Me & Forgot Password Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.85,
                                    child: Checkbox(
                                      checkColor: AppColors.blackColor,
                                      activeColor: AppColors.mainColor,
                                      visualDensity: VisualDensity.compact,
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
                                  Text(
                                    storedLanguage['Remember me'] ??
                                        "Remember me",
                                    style: t.bodySmall?.copyWith(
                                      fontSize: 14.sp,
                                      color:
                                          isDark
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
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4.h),
                                  child: Text(
                                    storedLanguage['Forgot Your Password?'] ??
                                        "Forgot Password?",
                                    style: t.displayMedium?.copyWith(
                                      fontSize: 14.sp,
                                      color: AppColors.mainColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Error Message Banner
                          if (controller.loginErrorMessage != null) ...[
                            VSpace(14.h),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
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
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          VSpace(24.h),
                          // Primary Login Button
                          Material(
                            color: Colors.transparent,
                            child: AppButton(
                              text: storedLanguage['Log In'] ?? "Log In",
                              isLoading: controller.isLoading,
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
                          VSpace(14.h),

                          // Premium WhatsApp & Phone OTP Login Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Get.toNamed(
                                  RoutesName.firebasePhoneLoginScreen,
                                );
                                controller.clearFirebaseOtpController();
                              },
                              borderRadius: BorderRadius.circular(14.r),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF25D366),
                                      Color(0xFF128C7E),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF25D366,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    WhatsAppBrandIcon(
                                      color: Colors.white,
                                      size: 20.sp,
                                    ),
                                    HSpace(10.w),
                                    Text(
                                      storedLanguage[
                                            'Login with Phone / WhatsApp'
                                          ] ??
                                          "Login with Phone / WhatsApp OTP",
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          VSpace(24.h),

                          // Social Login Divider
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: AppColors.borderColor,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Text(
                                  storedLanguage['Or connect with'] ??
                                      'Or connect with',
                                  style: t.bodySmall?.copyWith(
                                    color: AppColors.black50,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  color: AppColors.borderColor,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          VSpace(20.h),

                          // Premium Google & Apple Buttons
                          Row(
                            children: [
                              // Google Button
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    controller.signInWithGoogle();
                                  },
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 14.h,
                                      horizontal: 12.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? AppColors.darkCardColor
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color:
                                            isDark
                                                ? AppColors.borderColor
                                                : const Color(0xFFEAECF0),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        GoogleBrandIcon(size: 20.sp),
                                        HSpace(8.w),
                                        Text(
                                          storedLanguage['Google'] ?? 'Google',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1D2939),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              HSpace(14.w),
                              // Apple Button
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    controller.signInWithApple();
                                  },
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 14.h,
                                      horizontal: 12.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? AppColors.darkCardColor
                                              : const Color(0xFF111827),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color:
                                            isDark
                                                ? AppColors.borderColor
                                                : const Color(0xFF111827),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AppleBrandIcon(
                                          size: 22.sp,
                                          color: Colors.white,
                                        ),
                                        HSpace(8.w),
                                        Text(
                                          storedLanguage['Apple'] ?? 'Apple',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          VSpace(24.h),

                          // Don't have an account link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                storedLanguage["Don't have an account?"] ??
                                    "Don't have an account? ",
                                style: t.displayMedium?.copyWith(
                                  fontSize: 14.sp,
                                  color: AppThemes.getParagraphColor(),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Get.toNamed(RoutesName.registerScreen);
                                  controller.clearSignInController();
                                },
                                child: Text(
                                  storedLanguage["Create account"] ??
                                      "Create account",
                                  style: t.titleMedium?.copyWith(
                                    fontSize: 14.sp,
                                    color: AppColors.mainColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          VSpace(24.h),

                          // Footer Branding
                          const AuthFooterBranding(),
                          VSpace(20.h),
                        ],
                      ),
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

