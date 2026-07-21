import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';

import '../../config/app_colors.dart';
import '../../themes/themes.dart';

class AppPaymentSuccess extends StatelessWidget {
  const AppPaymentSuccess({super.key});

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
              color: AppThemes.getDarkCardColor(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset("assets/json/success.json"),
                    Text(
                      "Payment success",
                      style: context.t.bodyMedium,
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
                                  color: AppColors.greenColor,
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
