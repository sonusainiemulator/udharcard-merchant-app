import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../widgets/app_textfield.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AuthController controller = Get.find<AuthController>();
    TextTheme t = Theme.of(context).textTheme;
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<AuthController>(builder: (_) {
      return Scaffold(
          appBar: CustomAppBar(
            title: storedLanguage['Verify Email'] ?? 'Veify Email',
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
                        "$rootImageDir/email_verify_header.png",
                        height: 200.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  VSpace(60.h),
                  Center(
                    child: Text(
                      'Enter the 5 digits code that you\nreceived on your email',
                      textAlign: TextAlign.center,
                      style: t.displayMedium?.copyWith(
                          color: AppThemes.getParagraphColor(), height: 1.75),
                    ),
                  ),
                  VSpace(48.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 48.h,
                          width: 48.h,
                          padding: EdgeInsets.only(top: 3.h),
                          decoration: BoxDecoration(
                            color: AppThemes.getFillColor(),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.mainColor, width: 4.h),
                            ),
                          ),
                          child: Center(
                            child: AppTextField(
                              controller: controller.otpEditingController1,
                              onChanged: (v) {
                                controller.otpVal1 = v;
                                if (v.length == 1) {
                                  FocusManager.instance.primaryFocus
                                      ?.nextFocus();
                                }
                              },
                              keyboardType: TextInputType.number,
                              contentPadding: EdgeInsets.zero,
                              textAlign: TextAlign.center,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          height: 48.h,
                          width: 48.h,
                          padding: EdgeInsets.only(top: 3.h),
                          decoration: BoxDecoration(
                            color: AppThemes.getFillColor(),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.mainColor, width: 4.h),
                            ),
                          ),
                          child: Center(
                            child: AppTextField(
                              controller: controller.otpEditingController2,
                              onChanged: (v) {
                                controller.otpVal2 = v;
                                if (v.length == 1) {
                                  FocusManager.instance.primaryFocus
                                      ?.nextFocus();
                                }
                                controller.update();
                              },
                              keyboardType: TextInputType.number,
                              contentPadding: EdgeInsets.zero,
                              textAlign: TextAlign.center,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          height: 48.h,
                          width: 48.h,
                          padding: EdgeInsets.only(top: 3.h),
                          decoration: BoxDecoration(
                            color: AppThemes.getFillColor(),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.mainColor, width: 4.h),
                            ),
                          ),
                          child: Center(
                            child: AppTextField(
                              controller: controller.otpEditingController3,
                              onChanged: (v) {
                                controller.otpVal3 = v;
                                if (v.length == 1) {
                                  FocusManager.instance.primaryFocus
                                      ?.nextFocus();
                                }
                                controller.update();
                              },
                              keyboardType: TextInputType.number,
                              contentPadding: EdgeInsets.zero,
                              textAlign: TextAlign.center,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          height: 48.h,
                          width: 48.h,
                          padding: EdgeInsets.only(top: 3.h),
                          decoration: BoxDecoration(
                            color: AppThemes.getFillColor(),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.mainColor, width: 4.h),
                            ),
                          ),
                          child: Center(
                            child: AppTextField(
                              controller: controller.otpEditingController4,
                              onChanged: (v) {
                                controller.otpVal4 = v;
                                if (v.length == 1) {
                                  FocusManager.instance.primaryFocus
                                      ?.nextFocus();
                                }
                                controller.update();
                              },
                              keyboardType: TextInputType.number,
                              contentPadding: EdgeInsets.zero,
                              textAlign: TextAlign.center,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          height: 48.h,
                          width: 48.h,
                          padding: EdgeInsets.only(top: 3.h),
                          decoration: BoxDecoration(
                            color: AppThemes.getFillColor(),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.mainColor, width: 4.h),
                            ),
                          ),
                          child: Center(
                            child: AppTextField(
                              controller: controller.otpEditingController5,
                              onChanged: (v) {
                                controller.otpVal5 = v;
                                if (v.length == 1) {
                                  Helpers.hideKeyboard();
                                }
                                controller.update();
                              },
                              keyboardType: TextInputType.number,
                              contentPadding: EdgeInsets.zero,
                              textAlign: TextAlign.center,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  VSpace(40.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        storedLanguage['Don\'t receive any code?'] ??
                            "Don’t receive any code?",
                        style: t.displayMedium
                            ?.copyWith(color: AppThemes.getParagraphColor()),
                      ),
                      controller.isStartTimer
                          ? HSpace(10.w)
                          : TextButton(
                              onPressed: () async {
                                controller.startTimer();
                                await controller.forgotPass(
                                    isFromOtpPage: true);
                              },
                              child: Text(
                                storedLanguage['Resend Code'] ?? "Resend Code",
                                style: t.bodyMedium,
                              ),
                            ),
                      controller.isStartTimer == false
                          ? const SizedBox()
                          : Text("${controller.counter}s",
                              style: t.displayMedium
                                  ?.copyWith(color: AppColors.mainColor)),
                    ],
                  ),
                  VSpace(40.h),
                  AppButton(
                    text: storedLanguage['Continue'] ?? "Continue",
                    isLoading: controller.isLoading ? true : false,
                    bgColor: controller.otpVal1.isEmpty ||
                            controller.otpVal2.isEmpty ||
                            controller.otpVal3.isEmpty ||
                            controller.otpVal4.isEmpty ||
                            controller.otpVal5.isEmpty
                        ? AppThemes.getInactiveColor()
                        : AppColors.mainColor,
                    onTap: controller.otpVal1.isEmpty ||
                            controller.otpVal2.isEmpty ||
                            controller.otpVal3.isEmpty ||
                            controller.otpVal4.isEmpty ||
                            controller.otpVal5.isEmpty
                        ? null
                        : controller.isLoading
                            ? null
                            : () async {
                                Helpers.hideKeyboard();
                                await controller.geCode();
                              },
                  ),
                ],
              ),
            ),
          ));
    });
  }
}
