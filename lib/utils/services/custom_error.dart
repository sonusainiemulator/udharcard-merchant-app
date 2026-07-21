import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../config/app_colors.dart';
import '../../config/styles.dart';
import '../../themes/themes.dart';
import '../../views/widgets/custom_appbar.dart';
import '../app_constants.dart';

class CustomError extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CustomError({
    Key? key,
    required this.errorDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Error 404'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              Get.isDarkMode
                  ? '$rootImageDir/404.png'
                  : '$rootImageDir/404_dark.png',
              height: 400.h,
              width: double.maxFinite,
              fit: BoxFit.cover,
            ),
            if (!Get.isDarkMode) const SizedBox(height: 20),
            SelectableText(
              kDebugMode
                  ? errorDetails.summary.toString()
                  : 'Oups! Something went wrong!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: kDebugMode
                      ? AppColors.redColor
                      : AppThemes.getIconBlackColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 22.h,
                  fontFamily: Styles.appFontFamily),
            ),
            const SizedBox(height: 12),
            SelectableText(
              kDebugMode
                  ? 'https://docs.flutter.dev/testing/errors'
                  : "We encountered an error and we've notified our engineering team about it. Sorry for the inconvenience caused.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Get.isDarkMode
                      ? AppColors.textFieldHintColor
                      : AppColors.blackColor,
                  fontSize: 14.h,
                  fontFamily: Styles.appFontFamily),
            ),
          ],
        ),
      ),
    );
  }
}
