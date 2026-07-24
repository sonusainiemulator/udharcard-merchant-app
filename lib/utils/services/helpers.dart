import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../config/dimensions.dart';
import '../../config/styles.dart';
import '../../themes/themes.dart';
import '../../views/widgets/spacing.dart';
import '../app_constants.dart';

class Helpers {
  static showToast(
      {Color? bgColor,
      Color? textColor,
      String? msg,
      ToastGravity? gravity = ToastGravity.CENTER}) {
    return Fluttertoast.showToast(
      msg: msg ?? 'Field must not be empty!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity ?? ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: bgColor ?? Colors.red,
      textColor: textColor ?? Colors.white,
      fontSize: 16.sp,
    );
  }

  /// hide keyboard automatically when click anywhere in screen
  static hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  static notFound({double? top, String? text}) => Center(
        child: Column(
          children: [
            Container(
              margin:
                  EdgeInsets.only(top: top ?? Dimensions.screenHeight * .25),
              height: 200.h,
              width: 200.h,
              child: Image.asset(
                Get.isDarkMode
                    ? "$rootImageDir/not_found_dark.png"
                    : "$rootImageDir/not_found.png",
                fit: BoxFit.cover,
              ),
            ),
            VSpace(20.h),
            Text(text ?? "No data found",
                style: Styles.baseStyle
                    .copyWith(color: AppThemes.getIconBlackColor())),
          ],
        ),
      );

  /// SHOW VALIDATION ERROR DIALOG
  static showSnackBar({
    String msg = "Field must not be empty!",
    String title = "Error!",
    int? durationTime = 3,
    Widget? icon,
    Widget? titleText,
    Widget? messageText,
    Color? textColor,
    Color? bgColor,
    SnackPosition? snackPosition = SnackPosition.TOP,
  }) {
    if (!Get.isSnackbarOpen)
      Get.snackbar(
        title,
        titleText: titleText,
        msg,
        snackPosition: snackPosition,
        messageText: messageText,
        colorText: textColor ?? AppColors.whiteColor,
        backgroundColor: bgColor == null
            ? title == 'Failed' ||
                    title == 'Error!' ||
                    title == 'Error' ||
                    title == 'error'
                ? AppColors.redColor
                : AppColors.greenColor
            : bgColor,
        margin: EdgeInsets.all(10),
        borderRadius: 8,
        shouldIconPulse: true,
        icon: Icon(
            title == 'Failed' ||
                    title == 'Error!' ||
                    title == 'Error' ||
                    title == 'error'
                ? Icons.cancel
                : Icons.check,
            color: Colors.white),
        barBlur: 10,
        duration: Duration(seconds: durationTime!),
      );
  }

  static appLoader({Color? color}) => Center(
      child: CircularProgressIndicator(color: color ?? AppColors.mainColor));

  static String numberFormatWithAsFixed2(
      [String? currencySymbol, String? amount]) {
    if (amount == null || amount.isEmpty) return "";

    try {
      double parsedAmount = double.parse(amount);
      if (parsedAmount == parsedAmount.toInt()) {
        return NumberFormat('#,##0').format(parsedAmount);
      } else {
        return NumberFormat.currency(symbol: currencySymbol)
            .format(parsedAmount);
      }
    } catch (e) {
      return "";
    }
  }

  static String formatDateAndTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final DateTime date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateStr; // Return raw string if parsing fails
    }
  }
}

extension StringExtension on String {
  String toCapital() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
