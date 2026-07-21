import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../config/app_colors.dart';
import '../../config/styles.dart';
import '../../controllers/verification_controller.dart';
import '../../themes/themes.dart';
import '../../utils/services/helpers.dart';
import 'app_button.dart';

Future verificationBottomSheet({bool? isMailVerification = true}) {
  var verificationController = Get.find<VerificationController>();
  return Get.bottomSheet(
    Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        height: 350.h,
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: AppThemes.getDarkBgColor(),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 32.h),
              Text("Enter 6 Digits Code",
                  style: Styles.bodyLarge.copyWith(
                    color: AppThemes.getIconBlackColor(),
                  )),
              SizedBox(height: 20.h),
              Text(
                  isMailVerification == true
                      ? "Enter the 6 digits code that you received on your email."
                      : "Enter the 6 digits code that you received on your phone number.",
                  textAlign: TextAlign.center,
                  style: Styles.baseStyle.copyWith(
                    color:
                        Get.isDarkMode ? AppColors.black50 : AppColors.black60,
                  )),
              SizedBox(height: 40.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildTextField(
                      controller: verificationController.field1,
                      onChanged: (v) {
                        if (v.length == 1) {
                          FocusManager.instance.primaryFocus?.nextFocus();
                        }
                      }),
                  buildTextField(
                      controller: verificationController.field2,
                      onChanged: (v) {
                        if (v.length == 1) {
                          FocusManager.instance.primaryFocus?.nextFocus();
                        }
                      }),
                  buildTextField(
                      controller: verificationController.field3,
                      onChanged: (v) {
                        if (v.length == 1) {
                          FocusManager.instance.primaryFocus?.nextFocus();
                        }
                      }),
                  buildTextField(
                      controller: verificationController.field4,
                      onChanged: (v) {
                        if (v.length == 1) {
                          FocusManager.instance.primaryFocus?.nextFocus();
                        }
                      }),
                  buildTextField(
                      controller: verificationController.field5,
                      onChanged: (v) {
                        if (v.length == 1) {
                          FocusManager.instance.primaryFocus?.nextFocus();
                        }
                      }),
                  buildTextField(
                      controller: verificationController.field6,
                      onChanged: (v) {
                        if (v.length == 1) {
                          Helpers.hideKeyboard();
                        }
                      }),
                ],
              ),
              SizedBox(height: 16.h),
              GetBuilder<VerificationController>(builder: (_) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Didn’t receive any code? ",
                        style: Styles.baseStyle
                            .copyWith(color: AppColors.black50)),
                    InkWell(
                      onTap: verificationController.isResending
                          ? null
                          : () {
                              if (isMailVerification == true) {
                                verificationController.resendCode(
                                    type: 'email');
                              } else {
                                verificationController.resendCode(type: 'sms');
                              }
                            },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 3.h),
                        child: Text(
                            verificationController.isResending
                                ? "Resending..."
                                : "Resend Code",
                            style: Styles.baseStyle.copyWith(
                                decoration: TextDecoration.underline,
                                color: Get.isDarkMode
                                    ? AppColors.whiteColor
                                    : AppColors.blackColor)),
                      ),
                    ),
                  ],
                );
              }),
              SizedBox(height: 20.h),
              GetBuilder<VerificationController>(builder: (_) {
                return Material(
                  color: Colors.transparent,
                  child: AppButton(
                    buttonWidth: double.maxFinite,
                    onTap: verificationController.isVerifying
                        ? null
                        : () async {
                            if (verificationController.field1.text.isEmpty ||
                                verificationController.field2.text.isEmpty ||
                                verificationController.field3.text.isEmpty ||
                                verificationController.field4.text.isEmpty ||
                                verificationController.field5.text.isEmpty ||
                                verificationController.field6.text.isEmpty) {
                              Helpers.showSnackBar(
                                  msg: "Please enter 6 digits code");
                            } else {
                              if (isMailVerification == true) {
                                await verificationController.mailVerify(
                                    code: verificationController.field1.text
                                            .toString() +
                                        verificationController.field2.text
                                            .toString() +
                                        verificationController.field3.text
                                            .toString() +
                                        verificationController.field4.text
                                            .toString() +
                                        verificationController.field5.text
                                            .toString() +
                                        verificationController.field6.text
                                            .toString());
                                verificationController.field1.clear();
                                verificationController.field2.clear();
                                verificationController.field3.clear();
                                verificationController.field4.clear();
                                verificationController.field5.clear();
                                verificationController.field6.clear();
                              } else {
                                await verificationController.smsVerify(
                                    code: verificationController.field1.text
                                            .toString() +
                                        verificationController.field2.text
                                            .toString() +
                                        verificationController.field3.text
                                            .toString() +
                                        verificationController.field4.text
                                            .toString() +
                                        verificationController.field5.text
                                            .toString() +
                                        verificationController.field6.text
                                            .toString());
                                verificationController.field1.clear();
                                verificationController.field2.clear();
                                verificationController.field3.clear();
                                verificationController.field4.clear();
                                verificationController.field5.clear();
                                verificationController.field6.clear();
                              }
                            }
                          },
                    text: verificationController.isVerifying
                        ? "Processing..."
                        : "Continue",
                    bgColor: AppColors.mainColor,
                  ),
                );
              }),
            ],
          ),
        )),
    enableDrag: false,
  );
}

Widget buildTextField(
    {required TextEditingController controller,
    void Function(String)? onChanged}) {
  return Container(
    width: 36.h,
    height: 36.h,
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      textAlign: TextAlign.center,
      style: Styles.baseStyle.copyWith(
          color: Get.isDarkMode ? AppColors.whiteColor : AppColors.blackColor),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(1),
      ],
      decoration: InputDecoration(
        isDense: true,
        isCollapsed: true,
        fillColor: AppThemes.getFillColor(),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.mainColor, width: .2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent, width: .2),
        ),
      ),
    ),
  );
}
