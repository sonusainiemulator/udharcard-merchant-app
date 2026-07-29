import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/config/app_colors.dart';
import 'package:paysecure/controllers/auth_controller.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:paysecure/views/widgets/fintech_auth_widgets.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AuthController controller = Get.find<AuthController>();
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GetBuilder<AuthController>(
      builder: (_) {
        final isFilled = controller.otpVal1.isNotEmpty &&
            controller.otpVal2.isNotEmpty &&
            controller.otpVal3.isNotEmpty &&
            controller.otpVal4.isNotEmpty &&
            controller.otpVal5.isNotEmpty;

        return FintechAuthPage(
          eyebrow: 'Security Check',
          title: storedLanguage['Verify Email'] ?? 'Verify Email',
          subtitle:
              storedLanguage['Enter the 5 digits code that you received on your email'] ??
              'Enter the 5-digit security code sent to your email address.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 5-Digit PIN Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final controllers = [
                    controller.otpEditingController1,
                    controller.otpEditingController2,
                    controller.otpEditingController3,
                    controller.otpEditingController4,
                    controller.otpEditingController5,
                  ];
                  return Container(
                    height: 54.h,
                    width: 50.w,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF101828) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: controllers[index].text.isNotEmpty
                            ? AppColors.mainColor
                            : const Color(0xFFD0D5DD),
                        width: controllers[index].text.isNotEmpty ? 1.6 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: TextField(
                        controller: controllers[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF101828),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) {
                          if (index == 0) controller.otpVal1 = v;
                          if (index == 1) controller.otpVal2 = v;
                          if (index == 2) controller.otpVal3 = v;
                          if (index == 3) controller.otpVal4 = v;
                          if (index == 4) controller.otpVal5 = v;

                          if (v.length == 1 && index < 4) {
                            FocusScope.of(context).nextFocus();
                          } else if (v.isEmpty && index > 0) {
                            FocusScope.of(context).previousFocus();
                          } else if (v.length == 1 && index == 4) {
                            Helpers.hideKeyboard();
                          }
                          controller.update();
                        },
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 24.h),

              // Resend Code Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    storedLanguage['Don\'t receive any code?'] ??
                        "Didn't receive code?",
                    style: TextStyle(
                      color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  if (controller.isStartTimer)
                    Text(
                      "${controller.counter}s",
                      style: TextStyle(
                        color: AppColors.mainColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () async {
                        controller.startTimer();
                        await controller.forgotPass(isFromOtpPage: true);
                      },
                      child: Text(
                        storedLanguage['Resend Code'] ?? "Resend Code",
                        style: TextStyle(
                          color: AppColors.mainColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20.h),

              // Error banner if any
              if (controller.loginErrorMessage != null)
                FintechErrorMessage(
                  message: controller.loginErrorMessage!,
                ),

              // Primary Action
              FintechPrimaryButton(
                label: storedLanguage['Continue'] ?? "Continue",
                isLoading: controller.isLoading,
                onPressed: isFilled
                    ? () async {
                        Helpers.hideKeyboard();
                        await controller.geCode();
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
