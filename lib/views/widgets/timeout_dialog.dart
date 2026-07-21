import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../config/app_colors.dart';
import '../../themes/themes.dart';
import '../../utils/app_constants.dart';
import 'spacing.dart';

class Timeout extends StatelessWidget {
  const Timeout({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 30.w),
      child: Material(
          elevation: 0,
          type: MaterialType.transparency,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
              width: 300.w,
              decoration: BoxDecoration(
                color: AppThemes.getDarkCardColor(),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "$rootImageDir/timeout.png",
                      height: 80.h,
                      width: 80.h,
                      fit: BoxFit.cover,
                    ),
                    VSpace(10.h),
                    Text(
                      "Your session has timed out!",
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
                                  color: AppColors.mainColor,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20.w, vertical: 5.h),
                                  child: Center(
                                    child: Text(
                                      "Ok",
                                      style: context.t.bodyMedium?.copyWith(
                                          color: AppColors.blackColor),
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
