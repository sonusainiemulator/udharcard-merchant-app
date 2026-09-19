import 'package:flutter/widgets.dart' show FontWeight, TextStyle;
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart' show AppColors;

class Styles {
  static String get appFontFamily => GoogleFonts.inter().fontFamily ?? 'Inter';
  static const String secondaryFontFamily = 'Unbounded';

  static TextStyle baseStyle = GoogleFonts.inter(
    color: AppColors.blackColor,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );
  static TextStyle largeTitle = GoogleFonts.inter(
    color: AppColors.blackColor,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static TextStyle mediumTitle = GoogleFonts.inter(
    color: AppColors.blackColor,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );
  static TextStyle smallTitle = GoogleFonts.inter(
    color: AppColors.blackColor,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static TextStyle bodyLarge = GoogleFonts.inter(
    color: AppColors.blackColor,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static TextStyle bodyMedium = GoogleFonts.inter(
    color: AppColors.blackColor,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static TextStyle bodySmall = GoogleFonts.inter(
    color: AppColors.paragraphColor,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static TextStyle bodyExtraSmall = GoogleFonts.inter(
    color: AppColors.whiteColor,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}
