import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../config/app_colors.dart';
import '../../themes/themes.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;
  final bool obscureText;
  final String? hinText;
  final String? labelText;
  final FocusNode? focusNode;
  final Color? hintColor;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign? textAlign;
  final Function(String)? onChanged;
  final MaxLengthEnforcement maxLengthEnforcement;
  final EdgeInsetsGeometry? contentPadding;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? minLines;
  final int? maxLines;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final InputBorder? errorBorder;
  final InputBorder? border;
  final InputBorder? focusedErrorBorder;
  final String? errorText;
  final Color? fillColor;
  final InputBorder? focusedBorder;

  const AppTextField({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.obscureText = false,
    this.focusNode,
    this.hintColor,
    this.hinText,
    this.labelText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.textAlign,
    this.onChanged,
    this.maxLengthEnforcement = MaxLengthEnforcement.enforced,
    this.contentPadding,
    this.validator,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.minLines,
    this.maxLines,
    this.style,
    this.hintStyle,
    this.border,
    this.errorBorder,
    this.focusedErrorBorder,
    this.errorText,
    this.fillColor,
    this.focusedBorder,
  });

  @override
  Widget build(BuildContext context) {
    TextTheme t = Theme.of(context).textTheme;
    return TextFormField(
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode,
      controller: controller,
      autofocus: autofocus,
      minLines: minLines ?? 1,
      maxLines: maxLines ?? 1,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLengthEnforcement: maxLengthEnforcement,
      style: style ?? t.displayMedium,
      keyboardType: keyboardType,
      textAlign: textAlign ?? TextAlign.start,
      cursorColor: AppColors.mainColor,
      decoration: InputDecoration(
        enabledBorder: border,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: focusedErrorBorder,
        errorText: errorText,
        errorStyle: t.bodySmall?.copyWith(
          color: AppColors.redColor,
          fontSize: 12.sp,
        ),
        border: border,
        prefixIcon: prefixIcon,
     
        suffixIcon: suffixIcon,
        prefixIconConstraints: BoxConstraints(minWidth: 18.h, minHeight: 18.h),
        suffixIconConstraints: BoxConstraints(minWidth: 18.h, minHeight: 18.h),
        labelText: labelText,
        labelStyle: t.bodyMedium?.copyWith(
          color: AppThemes.getGreyColor(),
        ),
        // isDense: true,
        contentPadding:
            contentPadding ?? EdgeInsets.only(left: 10.w, bottom: 0),
        filled: true,
        fillColor: fillColor ?? Colors.transparent,
        hintText: hinText ?? "",
        hintStyle: hintStyle ??
            t.displayMedium?.copyWith(
              color: hintColor ?? AppColors.textFieldHintColor,
            ),
      ),
    );
  }
}
