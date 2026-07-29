import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../routes/routes_name.dart';
import '../../widgets/fintech_ui_kit.dart';
import 'onbording_data.dart';

class OnbordingScreen extends StatefulWidget {
  const OnbordingScreen({super.key});

  @override
  State<OnbordingScreen> createState() => _OnbordingScreenState();
}

class _OnbordingScreenState extends State<OnbordingScreen> {
  final PageController controller = PageController();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101828) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Logo & Skip Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 36.r,
                        width: 36.r,
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset('$rootImageDir/app_logo.png'),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'UDHCARD',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white : const Color(0xFF101828),
                        ),
                      ),
                    ],
                  ),
                  if (currentIndex < onBordingDataList.length - 1)
                    TextButton(
                      onPressed: () {
                        controller.animateToPage(
                          onBordingDataList.length - 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        storedLanguage['Skip'] ?? "Skip",
                        style: TextStyle(
                          color: AppColors.mainColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Page View Content
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: onBordingDataList.length,
                onPageChanged: (i) {
                  setState(() {
                    currentIndex = i;
                  });
                },
                itemBuilder: (context, i) {
                  final data = onBordingDataList[i];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration card wrapper
                        Container(
                          height: 300.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1D2939) : Colors.white,
                            borderRadius: BorderRadius.circular(28.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.r),
                              child: Image.asset(
                                data.imagePath,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 36.h),

                        // Title
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF101828),
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Description
                        Text(
                          data.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Controls
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onBordingDataList.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        height: 6.h,
                        width: currentIndex == index ? 24.w : 6.w,
                        decoration: BoxDecoration(
                          color: currentIndex == index
                              ? AppColors.mainColor
                              : (isDark ? const Color(0xFF344054) : const Color(0xFFEAECF0)),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // Action Button
                  FintechUI.primaryButton(
                    text: currentIndex == onBordingDataList.length - 1
                        ? (storedLanguage['Get Started'] ?? "Get Started")
                        : (storedLanguage['Next'] ?? "Next"),
                    onPressed: () {
                      if (currentIndex == onBordingDataList.length - 1) {
                        HiveHelp.write(Keys.isNewUser, false);
                        Get.offAllNamed(RoutesName.loginScreen);
                      } else {
                        controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
