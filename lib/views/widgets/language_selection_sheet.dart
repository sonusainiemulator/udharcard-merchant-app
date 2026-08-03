import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../config/app_colors.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../utils/services/helpers.dart';
import '../../utils/services/language_service.dart';

class LanguageSelectionSheet extends StatefulWidget {
  const LanguageSelectionSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const LanguageSelectionSheet(),
    );
  }

  @override
  State<LanguageSelectionSheet> createState() =>
      _LanguageSelectionSheetState();
}

class _LanguageSelectionSheetState extends State<LanguageSelectionSheet> {
  String _selectedLang = LanguageService.currentLanguageCode;

  Future<void> _applyLanguage(String langCode) async {
    setState(() {
      _selectedLang = langCode;
    });
    await LanguageService.changeLanguage(langCode);

    if (Get.isRegistered<AppController>()) {
      Get.find<AppController>().update();
    }
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().update();
    }

    Get.back();
    Helpers.showToast(
      msg: langCode == 'hi'
          ? 'ऐप की भाषा बदलकर हिंदी कर दी गई है 🇮🇳'
          : 'App language changed to English 🇬🇧',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 16.h,
        bottom: 24.h + bottomInset + safeBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 18.h),

          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.translate_rounded,
                  color: AppColors.mainColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageService.isHindi
                          ? "ऐप की भाषा चुनें"
                          : "Select App Language",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      LanguageService.isHindi
                          ? "अपनी पसंद की भाषा में ऐप चलाएं"
                          : "Choose your preferred language for UdharCard",
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // English Option Card
          _buildLanguageTile(
            langCode: 'en',
            title: 'English',
            subtitle: 'Default (English)',
            flag: '🇬🇧',
            isDark: isDark,
          ),

          SizedBox(height: 12.h),

          // Hindi Option Card
          _buildLanguageTile(
            langCode: 'hi',
            title: 'हिंदी (Hindi)',
            subtitle: 'व्यापार खाताबुक हिंदी में चलाएं',
            flag: '🇮🇳',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile({
    required String langCode,
    required String title,
    required String subtitle,
    required String flag,
    required bool isDark,
  }) {
    final isSelected = _selectedLang == langCode;

    return InkWell(
      onTap: () => _applyLanguage(langCode),
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.mainColor.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? AppColors.mainColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: TextStyle(fontSize: 28.sp)),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: AppColors.mainColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
