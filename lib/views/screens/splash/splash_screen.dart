import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paysecure/controllers/app_controller.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/app_colors.dart';
import '../../../routes/routes_name.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../../utils/services/subscription_gate_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  AppController appController = Get.find<AppController>();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _taglineOpacityAnimation;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _taglineOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _loadAppVersion();

    Future.delayed(const Duration(seconds: 3), () {
      final token = HiveHelp.read(Keys.token);
      final isLoggedIn =
          (token != null && token.toString().isNotEmpty) ||
          FirebaseAuth.instance.currentUser != null;

      if (isLoggedIn) {
        final bool isAppLockEnabled =
            (HiveHelp.read(Keys.isAppLockEnabled) ?? false) == true;
        if (isAppLockEnabled) {
          Get.offAllNamed(RoutesName.appLockScreen);
          return;
        }

        if (!SubscriptionGateService.isPlanEnrollmentRequired()) {
          Get.offAllNamed(RoutesName.bottomNavBar);
          return;
        }

        final bool planSelected =
            (HiveHelp.read(Keys.subscriptionPlanSelected) ?? false) == true;
        if (planSelected) {
          Get.offAllNamed(RoutesName.bottomNavBar);
        } else {
          Get.offAllNamed(RoutesName.subscriptionPlansScreen);
        }
      } else if (HiveHelp.read(Keys.isNewUser) != null) {
        Get.offAllNamed(RoutesName.loginScreen);
      } else {
        // TEMP DISABLE INTRO ONBOARDING
        // Get.offAllNamed(RoutesName.onbordingScreen);
        Get.offAllNamed(RoutesName.loginScreen);
      }
    });
    AppController.to.getBasicCtrl();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = packageInfo.version);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Minimalist background
          Positioned.fill(
            child: Container(color: AppColors.whiteColor),
          ),
          
          // Main content
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Premium App Logo
                        ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: Container(
                            width: 100.w,
                            height: 100.w,
                            decoration: BoxDecoration(
                              color: AppColors.whiteColor,
                              borderRadius: BorderRadius.circular(28.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.blackColor.withValues(alpha: 0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Image.asset(
                                "$rootImageDir/app_logo.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 32.h),
                      
                      // App Name
                      Text(
                        'UdharCard',
                        style: context.t.titleLarge?.copyWith(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blackColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      
                      // Tagline
                      FadeTransition(
                        opacity: _taglineOpacityAnimation,
                        child: Text(
                          'Merchant Dashboard',
                          style: context.t.bodyMedium?.copyWith(
                            color: AppColors.black50,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          ),
          
          // Footer
          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Loading Indicator
                      SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.mainColor,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'Trust & Secure',
                        style: context.t.bodySmall?.copyWith(
                          color: AppColors.black50,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (_appVersion.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          'v$_appVersion',
                          style: context.t.bodySmall?.copyWith(
                            color: AppColors.black30,
                            fontSize: 12.sp,
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
