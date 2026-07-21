import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../utils/services/helpers.dart';

class AppButton extends StatelessWidget {
  final void Function()? onTap;
  final String? text;
  final TextStyle? style;
  final double? buttonWidth;
  final double? buttonHeight;
  final double? maxWidth;
  final double? maxHeight;
  final Color? bgColor;
  final BorderRadius? borderRadius;
  final bool? isLoading;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;
  final bool? isIcon;
  final Widget? iconWidget;
  final double? loaderSize;

  const AppButton({
    super.key,
    this.onTap,
    this.text,
    this.style,
    this.buttonWidth,
    this.buttonHeight,
    this.maxWidth,
    this.maxHeight,
    this.bgColor,
    this.isLoading = false,
    this.borderRadius,
    this.padding,
    this.border,
    this.isIcon = false,
    this.iconWidget,
    this.loaderSize,
  });

  @override
  Widget build(BuildContext context) {
    TextTheme t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius ?? Dimensions.kBorderRadius,
      child: Container(
        constraints: BoxConstraints(
          minWidth: buttonWidth ?? double.maxFinite,
          minHeight: buttonHeight ?? 48.h,
          maxWidth: maxWidth ?? double.maxFinite,
          maxHeight: maxHeight ?? 48.h,
        ),
        child: Ink(
          width: buttonWidth ?? double.maxFinite,
          height: buttonHeight ?? 48.h,
          padding: padding,
          decoration: BoxDecoration(
            border: border,
            color: bgColor == null ? AppColors.mainColor : this.bgColor,
            borderRadius: borderRadius ?? BorderRadius.circular(12.r),
          ),
          child: Center(
            child:
                isLoading == true
                    ? SizedBox(
                      height: loaderSize,
                      width: loaderSize,
                      child: Helpers.appLoader(color: AppColors.whiteColor),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isIcon == true) iconWidget ?? SizedBox(),
                        Text(
                          text ?? "Continue",
                          style:
                              style ??
                              t.bodyLarge?.copyWith(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.whiteColor,
                              ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
