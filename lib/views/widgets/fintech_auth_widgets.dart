import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/app_colors.dart';
import '../../utils/app_constants.dart';

class FintechAuthPage extends StatelessWidget {
  const FintechAuthPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageColor =
        isDark ? const Color(0xFF101828) : const Color(0xFFF7F9FC);
    final cardColor = isDark ? const Color(0xFF1D2939) : Colors.white;
    final bodyColor =
        isDark ? const Color(0xFFD0D5DD) : const Color(0xFF667085);

    return Scaffold(
      backgroundColor: pageColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -92.h,
              right: -78.w,
              child: Container(
                height: 230.h,
                width: 230.h,
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withValues(alpha: .08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -100.h,
              left: -80.w,
              child: Container(
                height: 240.h,
                width: 240.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF12B76A).withValues(alpha: .06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 48.r,
                            width: 48.r,
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Image.asset('$rootImageDir/app_logo.png'),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'UdharCard',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF101828),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18.sp,
                                    letterSpacing: .5,
                                  ),
                                ),
                                Text(
                                  'Udhar Khatabook App',
                                  style: TextStyle(
                                    color: bodyColor,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 7.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAFBF2),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_user_rounded,
                                  color: const Color(0xFF067647),
                                  size: 15.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'SECURE',
                                  style: TextStyle(
                                    color: const Color(0xFF067647),
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 38.h),
                      Text(
                        eyebrow.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.mainColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        title,
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF101828),
                          fontSize: 30.sp,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: bodyColor,
                          fontSize: 14.sp,
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: 26.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(22.r),
                          border: Border.all(
                            color:
                                isDark
                                    ? const Color(0xFF344054)
                                    : const Color(0xFFEAECF0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? .12 : .05,
                              ),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      SizedBox(height: 22.h),
                      Center(
                        child: Text(
                          'Protected with bank-grade security',
                          style: TextStyle(color: bodyColor, fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Center(
                        child: Text(
                          'Made in India  •  Designed by Rakebig Services',
                          style: TextStyle(
                            color: bodyColor.withValues(alpha: .8),
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FintechTextField extends StatelessWidget {
  const FintechTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.prefix,
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
    this.onChanged,
    this.textInputAction,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final Widget? prefix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFFEAECF0) : const Color(0xFF344054),
            fontWeight: FontWeight.w700,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF101828),
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF98A2B3),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon:
                prefix == null
                    ? null
                    : Padding(
                      padding: EdgeInsets.only(left: 14.w, right: 10.w),
                      child: prefix,
                    ),
            prefixIconConstraints: BoxConstraints(
              minWidth: prefix == null ? 0 : 58.w,
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF101828) : const Color(0xFFF9FAFB),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.mainColor, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

class FintechPrimaryButton extends StatelessWidget {
  const FintechPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.mainColor,
          disabledBackgroundColor: const Color(0xFFAAB7CF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 20.r,
                  width: 20.r,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.sp,
                  ),
                ),
      ),
    );
  }
}

class FintechErrorMessage extends StatelessWidget {
  const FintechErrorMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: const Color(0xFFB42318),
            size: 19.sp,
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: const Color(0xFFB42318),
                fontSize: 12.sp,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
