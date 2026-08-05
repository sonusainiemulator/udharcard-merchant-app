import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/config/app_colors.dart';
import 'package:paysecure/config/dimensions.dart';
import 'package:paysecure/controllers/app_lock_controller.dart';
import 'package:paysecure/themes/themes.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:paysecure/views/widgets/app_button.dart';
import 'package:paysecure/views/widgets/spacing.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLockController.to.unlockApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Padding(
            padding: Dimensions.kDefaultPadding,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(),
                  Container(
                    height: 110.h,
                    width: 110.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mainColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppColors.mainColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 64.sp,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ),
                  VSpace(28.h),
                  Text(
                    AppConstants.appName,
                    style: context.t.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  VSpace(8.h),
                  Text(
                    storedLanguage['App Locked'] ?? 'App Locked',
                    style: context.t.displayMedium?.copyWith(
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  VSpace(12.h),
                  Text(
                    storedLanguage['Use your fingerprint, PIN, or pattern lock to proceed'] ??
                        'Use your fingerprint, PIN, or pattern lock to proceed',
                    style: context.t.bodyMedium?.copyWith(
                      color: AppThemes.getParagraphColor(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Spacer(),
                  Obx(() {
                    return AppButton(
                      text: AppLockController.to.isAuthenticating.value
                          ? (storedLanguage['Authenticating...'] ?? 'Authenticating...')
                          : (storedLanguage['Unlock Now'] ?? 'Unlock Now'),
                      onTap: () {
                        AppLockController.to.unlockApp();
                      },
                    );
                  }),
                  VSpace(30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
