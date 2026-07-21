import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';

import '../../config/app_colors.dart';

class AppPaymentFail extends StatelessWidget {
  final String? errorText;
  const AppPaymentFail({super.key, this.errorText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 30.w),
      child: Material(
          // Wrap with Material
          elevation: 0,
          type: MaterialType.transparency,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
              width: 300.w,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset("assets/json/fail.json"),
                    Text(
                      "Payment failed",
                      style: context.t.displayMedium,
                    ),
                    Text(
                      errorText ?? "",
                      textAlign: TextAlign.center,
                      style: context.t.bodySmall?.copyWith(
                          color: Get.isDarkMode
                              ? AppColors.whiteColor
                              : AppColors.blackColor),
                    ),
                    SizedBox(
                      height: 5.h,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 30.w, vertical: 20.h),
                        child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                                width: 100.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: AppColors.mainColor,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20.w, vertical: 5.h),
                                  child: Center(
                                    child: Text(
                                      "Ok",
                                      style: context.t.bodyMedium,
                                    ),
                                  ),
                                ))),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )),
    );
  }
}
