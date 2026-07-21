import 'package:flutter/widgets.dart' show FontWeight, TextStyle;
import 'app_colors.dart' show AppColors;

class Styles {
  static const String appFontFamily = 'Afacad';
  static const String secondaryFontFamily = 'Unbounded';

  static TextStyle baseStyle = TextStyle(
    color: AppColors.blackColor,
    fontSize: 18,
    fontFamily: appFontFamily,
    fontWeight: FontWeight.w400,
  );
  static TextStyle largeTitle = TextStyle(
    color: AppColors.blackColor,
    fontSize: 28,
    fontFamily: appFontFamily,
    fontWeight: FontWeight.w500,
  );
  static TextStyle mediumTitle = TextStyle(
    color: AppColors.blackColor,
    fontSize: 26,
    fontFamily: appFontFamily,
    fontWeight: FontWeight.w600,
  );
  static TextStyle smallTitle = TextStyle(
    color: AppColors.blackColor,
    fontSize: 24,
    fontFamily: appFontFamily,
    fontWeight: FontWeight.w500,
  );
  static TextStyle bodyLarge = TextStyle(
    color: AppColors.blackColor,
    fontSize: 20,
    fontFamily: appFontFamily,
    fontWeight: FontWeight.w600,
  );
  static TextStyle bodyMedium = TextStyle(
    color: AppColors.blackColor,
    fontSize: 18,
    fontFamily: appFontFamily,
    fontWeight: FontWeight.w500,
  );
  static TextStyle bodySmall = TextStyle(
    color: AppColors.paragraphColor,
    fontSize: 14,
    fontFamily: appFontFamily,
    fontWeight: FontWeight.w400,
  );
  static TextStyle bodyExtraSmall = TextStyle(color: AppColors.redColor)
    ..copyWith(color: AppColors.redColor)
    ..copyWith(color: AppColors.whiteColor);
}
