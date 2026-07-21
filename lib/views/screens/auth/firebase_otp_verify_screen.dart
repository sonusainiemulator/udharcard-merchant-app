import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/config/app_colors.dart';
import 'package:paysecure/config/dimensions.dart';
import 'package:paysecure/controllers/auth_controller.dart';
import 'package:paysecure/themes/themes.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:paysecure/views/widgets/app_button.dart';
import 'package:paysecure/views/widgets/custom_textfield.dart';
import 'package:paysecure/views/widgets/spacing.dart';

class FirebaseOtpVerifyScreen extends StatefulWidget {
  const FirebaseOtpVerifyScreen({super.key});

  @override
  State<FirebaseOtpVerifyScreen> createState() => _FirebaseOtpVerifyScreenState();
}

class _FirebaseOtpVerifyScreenState extends State<FirebaseOtpVerifyScreen> {
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
                          storedLanguage['Verify OTP'] ?? "Verify OTP",
                          style: t.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 30.sp,
                          ),
                        ),
                        VSpace(12.h),
                        Text(
                          storedLanguage['Enter the 6-digit code sent to your phone'] ??
                              "Enter the 6-digit code sent to your phone",
                          style: t.displayMedium?.copyWith(
                            color: AppThemes.getParagraphColor(),
                          ),
                        ),
                        VSpace(100.h),
                        CustomTextField(
                          hintext: storedLanguage['OTP Code'] ?? "OTP Code",
                          isPrefixIcon: true,
                          prefixIcon: 'lock',
                          keyboardType: TextInputType.number,
                          controller: controller.firebaseOtpController,
                          onChanged: (v) {
                            controller.firebaseOtpVal = v;
                            controller.update();
                          },
                        ),
                        VSpace(48.h),
                        Material(
                          color: Colors.transparent,
                          child: AppButton(
                            text: storedLanguage['Verify'] ?? "Verify",
                            isLoading: controller.isLoading,
                            bgColor: controller.firebaseOtpVal.isEmpty
                                ? AppThemes.getInactiveColor()
                                : AppColors.mainColor,
                            onTap: controller.firebaseOtpVal.isEmpty
                                ? null
                                : controller.isLoading
                                ? null
                                : () async {
                                    Helpers.hideKeyboard();
                                    await controller.verifyFirebaseOtp();
                                  },
                          ),
                        ),
                        VSpace(24.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                Get.back();
                              },
                              child: Text(
                                storedLanguage["Back"] ?? "Back",
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
