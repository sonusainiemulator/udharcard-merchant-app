import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:get/get.dart';
import 'package:paysecure/views/widgets/mediaquery_extension.dart';
import '../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../routes/routes_name.dart';
import '../../widgets/app_button.dart';
import '../../widgets/spacing.dart';
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
    TextTheme t = Theme.of(context).textTheme;
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: onBordingDataList.length,
              onPageChanged: (i) {
                setState(() {
                  currentIndex = i;
                });
              },
              itemBuilder: (context, i) {
                return Stack(
                  children: [
                    Positioned(
                      top: 100.h,
                      left: 0,
                      child: Image.asset(
                        "$rootImageDir/onbording_frame_left.png",
                      ),
                    ),
                    Positioned(
                      top: context.mQuery.height * .5,
                      right: 0,
                      child: Image.asset(
                        "$rootImageDir/onbording_frame_right.png",
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (i == 0)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: 70.h,
                              left: 24.w,
                              right: 24.w,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 56.w,
                                      height: 197.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                        color:
                                            Get.isDarkMode
                                                ? AppColors.whiteColor
                                                    .withValues(alpha: .04)
                                                : Color(0xffEAEAEA),
                                        border: Border.all(
                                          color:
                                              Get.isDarkMode
                                                  ? AppColors.whiteColor
                                                      .withValues(alpha: .11)
                                                  : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Container(
                                          width: 56.w,
                                          height: 104.h,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              4.r,
                                            ),
                                            color:
                                                Get.isDarkMode
                                                    ? AppColors.whiteColor
                                                        .withValues(alpha: .04)
                                                    : Color(0xffEAEAEA),
                                            border: Border.all(
                                              color:
                                                  Get.isDarkMode
                                                      ? AppColors.whiteColor
                                                          .withValues(
                                                            alpha: .11,
                                                          )
                                                      : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 56.w,
                                      height: 153.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                        color:
                                            Get.isDarkMode
                                                ? AppColors.whiteColor
                                                    .withValues(alpha: .04)
                                                : Color(0xffEAEAEA),
                                        border: Border.all(
                                          color:
                                              Get.isDarkMode
                                                  ? AppColors.whiteColor
                                                      .withValues(alpha: .11)
                                                  : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 56.w,
                                      height: 243.h,
                                      padding: EdgeInsets.only(
                                        left: 10.w,
                                        right: 10.w,
                                        top: 10.h,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                        color: AppColors.mainColor,
                                      ),
                                      alignment: Alignment.topCenter,
                                      child: Image.asset(
                                        "$rootImageDir/arrow_top.png",
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Container(
                                      width: 56.w,
                                      height: 197.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                        color:
                                            Get.isDarkMode
                                                ? AppColors.whiteColor
                                                    .withValues(alpha: .04)
                                                : Color(0xffEAEAEA),
                                        border: Border.all(
                                          color:
                                              Get.isDarkMode
                                                  ? AppColors.whiteColor
                                                      .withValues(alpha: .11)
                                                  : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  left: 77.w,
                                  top: 24.h,
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 20.h),
                                    child: Container(
                                      height: 46.h,
                                      width: 131.w,
                                      decoration: BoxDecoration(
                                        color:
                                            !Get.isDarkMode
                                                ? AppColors.fillColorColor
                                                : AppColors.whiteColor
                                                    .withValues(alpha: .07),
                                        borderRadius: BorderRadius.circular(
                                          36.r,
                                        ),
                                        border: Border.all(
                                          color:
                                              !Get.isDarkMode
                                                  ? AppColors
                                                      .sliderInActiveColor
                                                  : AppColors.whiteColor
                                                      .withValues(alpha: .11),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            height: 30.h,
                                            width: 30.h,
                                            padding: EdgeInsets.all(7.h),
                                            decoration: BoxDecoration(
                                              color: AppColors.mainColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Image.asset(
                                              '$rootImageDir/cash-in.png',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const HSpace(8),
                                          Text(
                                            "Payout",
                                            style: t.displayMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (i == 1)
                          Padding(
                            padding: Dimensions.kDefaultPadding,
                            child: Center(
                              child: Image.asset(
                                onBordingDataList[i].imagePath,
                                height: i == 0 ? 390.h : 340.h,
                                width: i == 0 ? 390.h : 340.h,
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                          ),
                        if (i == 2)
                          Column(
                            children: [
                              SizedBox(
                                width: 380.w,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 300.h,
                                      height: 300.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Positioned(
                                      top: -100.h,
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Image.asset(
                                        onBordingDataList[i].imagePath,
                                        height: 300.h,
                                        width: 300.h,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 10.h,
                                      left: 70.w,
                                      child: Container(
                                        width: 35.h,
                                        height: 35.h,
                                        decoration: BoxDecoration(
                                          color: AppColors.mainColor,
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(18.r),
                                            bottomRight: Radius.circular(2.r),
                                            topLeft: Radius.circular(2.5.r),
                                            topRight: Radius.circular(2.5.r),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        VSpace(59.h),
                        Padding(
                          padding: Dimensions.kDefaultPadding,
                          child: Text(
                            onBordingDataList[i].title,
                            textAlign: TextAlign.center,
                            style: t.titleLarge?.copyWith(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        VSpace(12.h),
                        Padding(
                          padding: Dimensions.kDefaultPadding,
                          child: Text(
                            onBordingDataList[i].description,
                            textAlign: TextAlign.center,
                            style: t.displayMedium?.copyWith(
                              height: 1.5,
                              fontSize: 18.sp,
                            ),
                          ),
                        ),
                        VSpace(44.h),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: EdgeInsets.only(bottom: 80.h),
          padding: Dimensions.kDefaultPadding,
          child: Row(
            mainAxisAlignment:
                (currentIndex == onBordingDataList.length - 1)
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
            children: [
              currentIndex == onBordingDataList.length - 1
                  ? const SizedBox(height: 1, width: 1)
                  : InkWell(
                    onTap: () {
                      controller.animateToPage(
                        onBordingDataList.length,
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutQuint,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Text(
                        storedLanguage['Skip'] ?? "Skip",
                        style: t.displayMedium?.copyWith(fontSize: 20.sp),
                      ),
                    ),
                  ),
              if (currentIndex != onBordingDataList.length - 1)
                Row(
                  children: [
                    Container(
                      height: 2.h,
                      width: 32.w,
                      color:
                          currentIndex == 0
                              ? AppColors.mainColor
                              : AppColors.sliderInActiveColor,
                    ),
                    HSpace(12.w),
                    Container(
                      height: 2.h,
                      width: 32.w,
                      color:
                          currentIndex == 1
                              ? AppColors.mainColor
                              : AppColors.sliderInActiveColor,
                    ),
                    HSpace(12.w),
                    Container(
                      height: 2.h,
                      width: 32.w,
                      color:
                          currentIndex == 2
                              ? AppColors.mainColor
                              : AppColors.sliderInActiveColor,
                    ),
                  ],
                ),
              (currentIndex == onBordingDataList.length - 1)
                  ? AppButton(
                    text:
                        (currentIndex == onBordingDataList.length - 1)
                            ? storedLanguage['Get Started'] ?? "Get Started"
                            : storedLanguage['Next'] ?? "Next",
                    onTap: () {
                      (currentIndex == (onBordingDataList.length - 1))
                          ? Get.offAllNamed(RoutesName.loginScreen)
                          : controller.nextPage(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOutQuint,
                          );
                      if ((currentIndex == (onBordingDataList.length - 1))) {
                        HiveHelp.write(Keys.isNewUser, false);
                      }
                    },
                    buttonWidth:
                        (currentIndex == onBordingDataList.length - 1)
                            ? 142.h
                            : 100.h,
                    buttonHeight:
                        (currentIndex == onBordingDataList.length - 1)
                            ? 42.h
                            : 36.h,
                    style: t.displayMedium?.copyWith(
                      color: AppColors.blackColor,
                      fontSize: 18.sp,
                    ),
                  )
                  : InkResponse(
                    onTap: () {
                      controller.nextPage(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutQuint,
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          "$rootImageDir/next_shape.png",
                          color: AppColors.mainColor,
                          width: 46.w,
                          height: 42.h,
                          fit: BoxFit.cover,
                        ),
                        Image.asset(
                          "$rootImageDir/double_arrow.png",
                          height: 22.h,
                          width: 22.h,
                          color: AppColors.blackColor,
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
