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

  @override
  void initState() {
    super.initState();
    nameNode.addListener(() => setState(() {}));
    emailNode.addListener(() => setState(() {}));
    phoneNode.addListener(() => setState(() {}));
    shopNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameNode.dispose();
    emailNode.dispose();
    phoneNode.dispose();
    shopNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    AuthController controller = Get.find<AuthController>();
    TextTheme t = Theme.of(context).textTheme;
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
                          VSpace(24.h),
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
                                    height: 70.h,
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
                                        "MERCHANT REGISTRATION",
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
                          VSpace(24.h),
                          // Title & Subtitle
                          Text(
                            storedLanguage['Sign Up'] ?? "Create Account 🚀",
                            style: t.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 26.sp,
                            ),
                          ),
                          VSpace(6.h),
                          Text(
                            storedLanguage['Create a new account to continue!'] ??
                                "Register your shop to start digital ledger & collections",
                            style: t.displayMedium?.copyWith(
                              color: AppThemes.getParagraphColor(),
                              fontSize: 14.sp,
                            ),
                          ),
                          VSpace(24.h),

                          // Full Name
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
                          VSpace(16.h),

                          // Phone Number
                          CustomTextField(
                            hintext:
                                storedLanguage['Mobile Number'] ??
                                "Mobile Number",
                            isPrefixIcon: true,
                            prefixWidget: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "🇮🇳 +91",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                      color: isDark ? AppColors.whiteColor : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Container(
                                    width: 1.w,
                                    height: 24.h,
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                  SizedBox(width: 8.w),
                                ],
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            focusNode: phoneNode,
                            controller: controller.phoneEditingController,
                            onChanged: (v) {
                              controller.phoneVal = v;
                              controller.update();
                            },
                          ),
                          VSpace(16.h),

                          // Shop Name
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
                          VSpace(16.h),

                          // Email Address
                          CustomTextField(
                            hintext:
                                storedLanguage['Email Address (Optional)'] ??
                                "Email Address (Optional)",
                            isPrefixIcon: true,
                            prefixIcon: 'email',
                            focusNode: emailNode,
                            controller: controller.emailEditingController,
                            onChanged: (v) {
                              controller.emailVal = v;
                              controller.update();
                            },
                          ),
                          VSpace(24.h),

                          // Register & Get OTP Button
                          Material(
                            color: Colors.transparent,
                            child: AppButton(
                              text: storedLanguage['Register & Send OTP'] ??
                                  "Register & Send OTP",
                              isLoading: controller.isLoading,
                              bgColor: (controller.nameVal.isEmpty ||
                                      controller.phoneVal.isEmpty ||
                                      controller.shopNameVal.isEmpty)
                                  ? AppThemes.getInactiveColor()
                                  : AppColors.mainColor,
                              onTap: (controller.nameVal.isEmpty ||
                                      controller.phoneVal.isEmpty ||
                                      controller.shopNameVal.isEmpty)
                                  ? null
                                  : controller.isLoading
                                  ? null
                                  : () async {
                                      Helpers.hideKeyboard();
                                      controller.firebasePhoneController.text = controller.phoneVal;
                                      controller.firebasePhoneVal = controller.phoneVal;
                                      await controller.sendFirebaseOtp(controller.phoneVal);
                                    },
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
                                  storedLanguage['Or register with'] ??
                                      'Or register with',
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

                          // Google & Apple Buttons
                          Row(
                            children: [
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
                                      color: isDark
                                          ? AppColors.darkCardColor
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.borderColor
                                            : const Color(0xFFEAECF0),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GoogleBrandIcon(size: 20.sp),
                                        HSpace(8.w),
                                        Text(
                                          storedLanguage['Google'] ?? 'Google',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1D2939),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (GetPlatform.isIOS) ...[
                                HSpace(14.w),
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
                                        color: isDark
                                            ? AppColors.darkCardColor
                                            : const Color(0xFF111827),
                                        borderRadius: BorderRadius.circular(16.r),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.borderColor
                                              : const Color(0xFF111827),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
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
                            ],
                          ),
                          VSpace(24.h),

                          // Already have an account link
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Get.back();
                              },
                              borderRadius: BorderRadius.circular(12.r),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      storedLanguage["Already have an account?"] ??
                                          "Already have an account? ",
                                      style: t.displayMedium?.copyWith(
                                        fontSize: 15.sp,
                                        color: AppThemes.getParagraphColor(),
                                      ),
                                    ),
                                    HSpace(4.w),
                                    Text(
                                      storedLanguage["Log In"] ?? "Log In",
                                      style: t.titleMedium?.copyWith(
                                        fontSize: 15.sp,
                                        color: AppColors.mainColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
