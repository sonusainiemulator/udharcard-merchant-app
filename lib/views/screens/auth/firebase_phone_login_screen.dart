import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/config/app_colors.dart';
import 'package:paysecure/config/dimensions.dart';
import 'package:paysecure/controllers/auth_controller.dart';
import 'package:paysecure/routes/routes_name.dart';
import 'package:paysecure/themes/themes.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:paysecure/views/widgets/app_button.dart';
import 'package:paysecure/views/widgets/custom_textfield.dart';
import 'package:paysecure/views/widgets/spacing.dart';

class FirebasePhoneLoginScreen extends StatefulWidget {
  const FirebasePhoneLoginScreen({super.key});

  @override
  State<FirebasePhoneLoginScreen> createState() => _FirebasePhoneLoginScreenState();
}

class _FirebasePhoneLoginScreenState extends State<FirebasePhoneLoginScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AuthController>().clearFirebaseOtpController();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    AuthController controller = Get.find<AuthController>();
    TextTheme t = Theme.of(context).textTheme;

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
                          storedLanguage['Phone Login'] ?? "Phone Login",
                          style: t.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 30.sp,
                          ),
                        ),
                        VSpace(12.h),
                        Text(
                          storedLanguage['Enter your phone number to continue'] ??
                              "Enter your phone number to continue",
                          style: t.displayMedium?.copyWith(
                            color: AppThemes.getParagraphColor(),
                          ),
                        ),
                        VSpace(100.h),
                        CustomTextField(
                          hintext: storedLanguage['Phone Number'] ??
                              "Phone Number",
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
                                    color: Get.isDarkMode ? AppColors.whiteColor : Colors.black87,
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
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          autofillHints: const [AutofillHints.telephoneNumber],
                          controller: controller.firebasePhoneController,
                          onChanged: (v) {
                            controller.firebasePhoneVal = v;
                            controller.update();
                          },
                        ),
                        GetBuilder<AuthController>(builder: (controller) => Column(children: [
                        VSpace(32.h),
                        Material(
                          color: Colors.transparent,
                          child: AppButton(
                            text: storedLanguage['Send OTP via SMS'] ?? "Send OTP via SMS",
                            isLoading: controller.isLoading,
                            bgColor: controller.firebasePhoneController.text.trim().isEmpty
                                ? AppThemes.getInactiveColor()
                                : AppColors.mainColor,
                            onTap: controller.firebasePhoneController.text.trim().isEmpty
                                ? null
                                : controller.isLoading
                                ? null
                                : () async {
                                    Helpers.hideKeyboard();
                                    await controller.sendFirebaseOtp(controller.firebasePhoneController.text.trim());
                                  },
                          ),
                        ),
                        VSpace(16.h),
                        Material(
                          color: Colors.transparent,
                          child: AppButton(
                            text: storedLanguage['Send OTP via WhatsApp (Coming Soon)'] ?? "Send OTP via WhatsApp (Coming Soon)",
                            isLoading: false,
                            bgColor: controller.firebasePhoneController.text.trim().isEmpty
                                ? AppThemes.getInactiveColor()
                                : const Color(0xFF25D366), // WhatsApp Green
                            onTap: controller.firebasePhoneController.text.trim().isEmpty
                                ? null
                                : () {
                                    Helpers.hideKeyboard();
                                    Helpers.showSnackBar(
                                      msg: "WhatsApp OTP is coming soon!",
                                    );
                                  },
                          ),
                        ),
                        ])),
                        VSpace(24.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                Get.back();
                                controller.clearFirebaseOtpController();
                              },
                              child: Text(
                                storedLanguage["Back to Login"] ?? "Back to Login",
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
  }
}
