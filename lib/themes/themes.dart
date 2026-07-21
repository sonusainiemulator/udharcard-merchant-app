import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../config/app_colors.dart';
import '../config/dimensions.dart';
import '../config/styles.dart' show Styles;

class AppThemes {
  //---------------CUSTOM THEME COLOR IN LIGHT AND DARK MODE---------//
  static getIconBlackColor() {
    return Get.isDarkMode ? AppColors.whiteColor : AppColors.blackColor;
  }

  static getHintColor() {
    return Get.isDarkMode ? AppColors.whiteColor : AppColors.textFieldHintColor;
  }

  static getGreyColor() {
    return Get.isDarkMode ? AppColors.whiteColor : AppColors.greyColor;
  }

  static getDarkCardColor() {
    return Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor;
  }

  static getDarkBgColor() {
    return Get.isDarkMode ? AppColors.darkBgColor : AppColors.whiteColor;
  }

  static getBlack10Color() {
    return Get.isDarkMode ? AppColors.darkCardColor : AppColors.black10;
  }

  static getBlack20Color() {
    return Get.isDarkMode ? AppColors.black20 : AppColors.black20;
  }

  static getBlack30Color() {
    return Get.isDarkMode ? AppColors.black20 : AppColors.black30;
  }

  static getBlack50Color() {
    return Get.isDarkMode ? AppColors.black30 : AppColors.black50;
  }

  static getFillColor() {
    return Get.isDarkMode ? AppColors.darkCardColor : AppColors.fillColorColor;
  }

  static getInactiveColor() {
    return Get.isDarkMode
        ? AppColors.darkCardColor
        : AppColors.textFieldHintColor;
  }

  static getSliderInactiveColor() {
    return Get.isDarkMode ? AppColors.black80 : AppColors.sliderInActiveColor;
  }

  static getParagraphColor() {
    return Get.isDarkMode ? AppColors.black30 : AppColors.paragraphColor;
  }

  static borderColor() {
    return Get.isDarkMode ? Colors.transparent : Colors.transparent;
  }

  //---------------------------------//
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.scaffoldColor,
    drawerTheme: const DrawerThemeData(backgroundColor: AppColors.whiteColor),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: AppColors.whiteColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.blackColor,
      titleTextStyle: Styles.bodyLarge.copyWith(
        fontSize: 20.sp,
        color: AppColors.blackColor,
      ),
    ),
    iconTheme: IconThemeData(color: AppColors.blackColor),
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.whiteColor),
    textTheme: TextTheme(
      displayMedium: Styles.baseStyle.copyWith(fontSize: 18.sp),
      titleSmall: Styles.smallTitle.copyWith(fontSize: 20.sp),
      titleMedium: Styles.mediumTitle.copyWith(fontSize: 22.sp),
      titleLarge: Styles.largeTitle.copyWith(fontSize: 24.sp),
      bodyLarge: Styles.bodyLarge.copyWith(fontSize: 18.sp),
      bodyMedium: Styles.bodyMedium.copyWith(fontSize: 16.sp),
      bodySmall: Styles.bodySmall.copyWith(fontSize: 14.sp),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: AppColors.mainColor.withValues(alpha: .4),
      cursorColor: AppColors.mainColor.withValues(alpha: .7),
      selectionHandleColor: AppColors.mainColor.withValues(alpha: 0.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: Styles.baseStyle.copyWith(color: AppColors.textFieldHintColor),
      filled: true,
      fillColor: AppColors.whiteColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(10.r),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.mainColor, width: 1.2),
        borderRadius: BorderRadius.circular(10.r),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: AppColors.redColor,
        ), // Error border color
        borderRadius: BorderRadius.circular(10.r), // Border radius
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: AppColors.redColor,
        ), // Error border color
        borderRadius: BorderRadius.circular(10.r),
      ),
    ),
    useMaterial3: true,
    dialogTheme: DialogThemeData(backgroundColor: AppColors.whiteColor),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBgColor,
    drawerTheme: const DrawerThemeData(backgroundColor: AppColors.darkBgColor),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: AppColors.darkBgColor,
      elevation: 0,
    ),
    iconTheme: const IconThemeData(color: AppColors.whiteColor),
    colorScheme: const ColorScheme.dark(primary: AppColors.darkCardColor),
    textTheme: TextTheme(
      displayMedium: Styles.baseStyle.copyWith(
        color: AppColors.whiteColor,
        fontSize: 18.sp,
      ),
      titleSmall: Styles.smallTitle.copyWith(
        color: AppColors.whiteColor,
        fontSize: 24.sp,
      ),
      titleMedium: Styles.mediumTitle.copyWith(
        color: AppColors.whiteColor,
        fontSize: 26.sp,
      ),
      titleLarge: Styles.largeTitle.copyWith(
        color: AppColors.whiteColor,
        fontSize: 30.sp,
      ),
      bodyLarge: Styles.bodyLarge.copyWith(
        color: AppColors.whiteColor,
        fontSize: 22.sp,
      ),
      bodyMedium: Styles.bodyMedium.copyWith(
        color: AppColors.whiteColor,
        fontSize: 18.sp,
      ),
      bodySmall: Styles.bodySmall.copyWith(
        color: AppColors.whiteColor,
        fontSize: 16.sp,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: AppColors.mainColor.withValues(alpha: .4),
      cursorColor: AppColors.mainColor.withValues(alpha: .7),
      selectionHandleColor: AppColors.mainColor.withValues(alpha: 0.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: Styles.baseStyle.copyWith(color: AppColors.textFieldHintColor),
      filled: true,
      fillColor: AppColors.darkCardColor,
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: AppColors.redColor,
        ), // Error border color
        borderRadius: Dimensions.kBorderRadius, // Border radius
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: AppColors.redColor,
        ), // Error border color
        borderRadius: Dimensions.kBorderRadius,
      ),
    ),
    useMaterial3: true,
    dialogTheme: DialogThemeData(backgroundColor: AppColors.darkCardColor),
  );
}
