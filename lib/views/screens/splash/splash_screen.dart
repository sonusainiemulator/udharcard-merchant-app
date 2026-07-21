import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paysecure/controllers/app_controller.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:get/get.dart';
import 'package:paysecure/views/widgets/mediaquery_extension.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
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
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fadeAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(const Duration(seconds: 3), () {
      HiveHelp.read(Keys.token) != null
          ? Get.offAllNamed(RoutesName.bottomNavBar)
          : HiveHelp.read(Keys.isNewUser) != null
              ? Get.offAllNamed(RoutesName.loginScreen)
              : Get.offAllNamed(RoutesName.onbordingScreen);
    });
    AppController.to.getBasicCtrl();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: context.mQuery.width,
        height: context.mQuery.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff0D2247), // Deep navy
              Color(0xff1B3A6B), // Navy (brand primary)
              Color(0xff2E5FA3), // Medium blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SizedBox(
          width: context.mQuery.width,
          height: context.mQuery.height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Decorative background glow circles
              Positioned(
                top: -60.h,
                right: -60.w,
                child: Container(
                  width: 220.h,
                  height: 220.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffF5A623).withValues(alpha: .08),
                  ),
                ),
              ),
              Positioned(
                bottom: -40.h,
                left: -40.w,
                child: Container(
                  width: 180.h,
                  height: 180.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffF5A623).withValues(alpha: .06),
                  ),
                ),
              ),
              // Main content - Logo + text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo container
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Container(
                            width: 200.h,
                            height: 200.h,
                            padding: EdgeInsets.all(24.h),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.whiteColor.withValues(alpha: .12),
                              border: Border.all(
                                color: Color(0xffF5A623).withValues(alpha: .4),
                                width: 2.h,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xffF5A623).withValues(alpha: .2),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              "$rootImageDir/app_logo.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 32.h),
                  // Animated brand name
                  AnimatedTextKit(
                    animatedTexts: [
                      ColorizeAnimatedText(
                        'Udhar Card',
                        speed: Duration(milliseconds: 400),
                        textStyle: context.t.titleLarge!.copyWith(
                          fontSize: 38.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                        colors: [
                          Color(0xffF5A623),  // Gold
                          AppColors.whiteColor,
                          Color(0xffF5A623),  // Gold
                        ],
                      ),
                    ],
                    isRepeatingAnimation: false,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'MERCHANT',
                    style: context.t.titleMedium?.copyWith(
                      color: Color(0xffF5A623),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6.0,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Fast. Simple. Secure.',
                    style: context.t.bodyMedium?.copyWith(
                      color: AppColors.whiteColor.withValues(alpha: .7),
                      fontSize: 16.sp,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              // Bottom loading indicator
              Positioned(
                bottom: 60.h,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 32.h,
                    height: 32.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xffF5A623).withValues(alpha: .8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
