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

    _controller.forward();
    _loadAppVersion();

    Future.delayed(const Duration(seconds: 3), () {
      final token = HiveHelp.read(Keys.token);
      final isLoggedIn =
          (token != null && token.toString().isNotEmpty) ||
          FirebaseAuth.instance.currentUser != null;

      if (isLoggedIn) {
        Get.offAllNamed(RoutesName.bottomNavBar);
      } else if (HiveHelp.read(Keys.isNewUser) != null) {
        Get.offAllNamed(RoutesName.loginScreen);
      } else {
        Get.offAllNamed(RoutesName.onbordingScreen);
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Premium App Logo
                      Container(
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
                      SizedBox(height: 32.h),
                      
                      // App Name
                      Text(
                        'UDHCARD',
                        style: context.t.titleLarge?.copyWith(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blackColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      
                      // Tagline
                      Text(
                        'Merchant Dashboard',
                        style: context.t.bodyMedium?.copyWith(
                          color: AppColors.black50,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Footer
          Positioned(
            bottom: 40.h,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
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
