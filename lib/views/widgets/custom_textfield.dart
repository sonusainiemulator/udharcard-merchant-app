import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../themes/themes.dart';
import '../../utils/app_constants.dart';
import 'app_textfield.dart';

class CustomTextField extends StatelessWidget {
  final String hintext;
  final double? textfieldHieght;
  final TextEditingController controller;
  final Color? bgColor;
  final Color? suffixIconColor;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines;
  final int? maxLines;
  final EdgeInsetsGeometry? contentPadding;
  final String? prefixIcon;
  final String? suffixIcon;
  final Widget? suffix;
  final dynamic Function(String)? onChanged;
  final void Function()? onPreffixPressed;
  final void Function()? onSuffixPressed;
  final AlignmentGeometry? alignment;
  final bool? obsCureText;
  final bool? isPrefixIcon;
  final bool? isSuffixIcon;
  final bool? isSuffixBgColor;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextStyle? hintStyle;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final InputBorder? focusedBorder;
  final String? errorText;
  final bool? isBorderColor;
  final Color? borderColor;
  final Color? fillColor;
  final bool? isReverseColor;
  final double? borderWidth;
  final double? suffixIconSize;
  final BorderRadius? borderRadius;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  const CustomTextField({
    super.key,
    required this.hintext,
    required this.controller,
    this.bgColor,
    this.textfieldHieght = 50,
    this.isSuffixBgColor = false,
    this.isSuffixIcon = false,
    this.isPrefixIcon = false,
    this.alignment,
    this.borderRadius,
    this.suffixIconColor,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.minLines,
    this.maxLines,
    this.contentPadding,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.onChanged,
    this.onPreffixPressed,
    this.onSuffixPressed,
    this.obsCureText = false,
    this.validator,
    this.focusNode,
    this.hintStyle,
    this.errorBorder,
    this.focusedErrorBorder,
    this.focusedBorder,
    this.errorText,
    this.isBorderColor = true,
    this.borderColor,
    this.fillColor,
    this.onFieldSubmitted,
    this.isReverseColor = false,
    this.borderWidth,
    this.suffixIconSize,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    if (textfieldHieght == null) {
      return textfield();
    }
    return SizedBox(height: textfieldHieght?.h, child: textfield());
  }

  AppTextField textfield() {
    return AppTextField(
      onFieldSubmitted: onFieldSubmitted,
      errorText: errorText,
      errorBorder: errorBorder,
      autofillHints: autofillHints,
      focusedErrorBorder: focusedErrorBorder,
      controller: controller,
      obscureText: obsCureText ?? false,
      hintStyle: hintStyle,
      minLines: minLines ?? 1,
      maxLines: maxLines ?? 1,
      hinText: hintext,
      onChanged: onChanged,
      fillColor:
          isBorderColor == false
              ? isReverseColor == true
                  ? AppThemes.getDarkBgColor()
                  : fillColor ?? AppThemes.getDarkCardColor()
              : fillColor ?? AppColors.whiteColor,
      border: OutlineInputBorder(
        borderRadius: borderRadius ?? Dimensions.kBorderRadius,
        borderSide: BorderSide(
          width: borderWidth ?? 1,
          color:
              isBorderColor == true
                  ? borderColor ?? AppThemes.getSliderInactiveColor()
                  : Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius ?? Dimensions.kBorderRadius,
        borderSide: BorderSide(
          color:
              isBorderColor == true
                  ? borderColor ?? AppColors.mainColor
                  : Colors.transparent,
        ),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      contentPadding: contentPadding ?? EdgeInsets.only(left: 15.w),
      validator: validator,
      focusNode: focusNode,
      prefixIcon:
          prefixIcon != null
              ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: InkResponse(
                  onTap: onPreffixPressed,
                  child: Image.asset(
                    "$rootImageDir/$prefixIcon.png",
                    height: 16.h,
                    width: 16.h,
                    color:
                        Get.isDarkMode
                            ? AppColors.whiteColor
                            : AppColors.textFieldHintColor,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              )
              : null,
      suffixIcon:
          suffix == null
              ? suffixIcon != null
                  ? IconButton(
                    onPressed: onSuffixPressed,
                    icon: Image.asset(
                      "$rootImageDir/$suffixIcon.png",
                      height: suffixIconSize ?? 22.h,
                      width: suffixIconSize ?? 22.h,
                      color:
                          suffixIconColor ??
                          (Get.isDarkMode
                              ? AppColors.whiteColor
                              : AppColors.textFieldHintColor),
                      fit: BoxFit.cover,
                    ),
                  )
                  : SizedBox(width: 0, height: 0)
              : this.suffix,
    );
  }
}
