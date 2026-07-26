import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../config/app_colors.dart';
import 'spacing.dart';

class AuthFooterBranding extends StatelessWidget {
  const AuthFooterBranding({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Get.isDarkMode;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardColor.withValues(alpha: 0.6)
            : AppColors.mainColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppColors.borderColor.withValues(alpha: 0.2)
              : AppColors.mainColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6.w,
            runSpacing: 4.h,
            children: [
              // 100% Secure Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 16.sp,
                    color: const Color(0xFF10B981),
                  ),
                  HSpace(4.w),
                  Text(
                    "100% Secure & Trusted",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  "•",
                  style: TextStyle(
                    color: AppColors.mainColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Made in India
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("🇮🇳", style: TextStyle(fontSize: 14.sp)),
                  HSpace(4.w),
                  Text(
                    "Made in India",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          VSpace(6.h),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 14.sp,
                color: AppColors.mainColor,
              ),
              HSpace(4.w),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark ? Colors.white54 : AppColors.black50,
                  ),
                  children: [
                    const TextSpan(text: "Designed by "),
                    TextSpan(
                      text: "Rakebig Services",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
