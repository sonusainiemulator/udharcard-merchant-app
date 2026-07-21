import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class Dimensions {
  /// GET SCREEN HEIGHT AND WIDTH
  static double screenHeight = Get.height;
  static double screenWidth = Get.width;

  // APP DEFAULT BORDER RADIUS
  static BorderRadius kBorderRadius = BorderRadius.circular(8.r);

  /// APP DEFAULT HORIZONTAL PADDING
  static EdgeInsets kDefaultPadding = EdgeInsets.symmetric(horizontal: 24.w);

  /// APP BUTTON DEFAULT HEIGHT
  static double buttonHeight = 52.h;

  /// APP DEFAULT TEXTFIELD HEIGHT
  static double textFieldHeight = 50.h;

  /// APP THIN BORDER WIDTH
  static double appThinBorder = .12;
}
