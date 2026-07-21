import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../config/dimensions.dart';
import '../../config/app_colors.dart';
import '../../themes/themes.dart';

appDialog({
  required BuildContext context,
  Widget? title,
  Widget? content,
  EdgeInsets? insetPadding,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        insetPadding: insetPadding ?? EdgeInsets.symmetric(horizontal: 50.w),
        backgroundColor: AppThemes.getDarkBgColor(),
        shape: RoundedRectangleBorder(borderRadius: Dimensions.kBorderRadius),
        surfaceTintColor: AppColors.whiteColor,
        title: title ?? const SizedBox(),  
        content: content ?? const SizedBox(),
      );
    },
  );
}
