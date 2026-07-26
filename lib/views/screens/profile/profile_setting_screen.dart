import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:paysecure/config/dimensions.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../../config/app_colors.dart';
import '../../../controllers/app_controller.dart';
import '../../../controllers/profile_controller.dart';
import '../../../controllers/verification_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../themes/themes.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';

class ProfileSettingScreen extends StatefulWidget {
  final bool? isFromHomePage;
  final bool? isIdentityVerification;
  final bool? isAddressVerification;
  const ProfileSettingScreen({
    super.key,
    this.isFromHomePage = false,
    this.isIdentityVerification = false,
    this.isAddressVerification = false,
  });

  @override
  State<ProfileSettingScreen> createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends State<ProfileSettingScreen> {
  var controller = Get.put(ProfileController());
  @override
  void initState() {
    if (controller.profileList.isEmpty) {
      controller.getProfile();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (HiveHelp.read(Keys.isDark) == null) {
      Get.find<AppController>().selectedIndex = 0;
    } else if (HiveHelp.read(Keys.isDark) == true) {
      Get.find<AppController>().selectedIndex = 1;
    } else if (HiveHelp.read(Keys.isDark) == false) {
      Get.find<AppController>().selectedIndex = 2;
    }
    TextTheme t = Theme.of(context).textTheme;
    return GetBuilder<AppController>(
      builder: (appController) {
        var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
        return GetBuilder<ProfileController>(
          builder: (profileController) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) {
                  return;
                }
                if (widget.isIdentityVerification == true ||
                    widget.isAddressVerification == true) {
                  Get.offAllNamed(RoutesName.bottomNavBar);
                } else {
                  Get.back();
                }
              },
              child: Scaffold(
                appBar: CustomAppBar(
                  title:
                      storedLanguage['Profile Settings'] ?? "Profile Settings",
                  toolberHeight: 100.h,
                  prefferSized: 100.h,
                  leading:
                      widget.isFromHomePage == true
                          ? IconButton(
                            onPressed: () {
                              if (widget.isIdentityVerification == true ||
                                  widget.isAddressVerification == true) {
                                Get.offAllNamed(RoutesName.bottomNavBar);
                              } else {
                                Get.back();
                              }
                            },
                            icon: Image.asset(
                              "$rootImageDir/back.png",
                              height: 22.h,
                              width: 22.h,
                              color:
                                  Get.isDarkMode
                                      ? AppColors.whiteColor
                                      : AppColors.blackColor,
                              fit: BoxFit.fitHeight,
                            ),
                          )
                          : const SizedBox(),
                ),
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      // HEADER PORTION
                      GestureDetector(
                        onTap: () {
                          if (Get.find<ProfileController>().userPhoto != '') {
                            Get.to(
                              () => Scaffold(
                                appBar: const CustomAppBar(title: ""),
                                body: PhotoView(
                                  imageProvider: NetworkImage(
                                    Get.find<ProfileController>().userPhoto,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 110.h,
                          width: 110.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(
                              color: AppColors.mainColor,
                              width: 4.h,
                            ),
                            color: AppColors.imageBgColor,
                            image:
                                Get.find<ProfileController>().isLoading ||
                                        Get.find<ProfileController>()
                                                .userPhoto ==
                                            ''
                                    ? DecorationImage(
                                      image: AssetImage(
                                        "$rootImageDir/avatar.webp",
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                    : DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        Get.find<ProfileController>().userPhoto,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                          ),
                        ),
                      ),
                      VSpace(12.h),
                      Text(
                        Get.find<ProfileController>().isLoading
                            ? ""
                            : Get.find<ProfileController>().userName,
                        style: t.bodyLarge,
                      ),
                      VSpace(5.h),
                      Text(
                        Get.find<ProfileController>().isLoading
                            ? ""
                            : storedLanguage['Joined At'] ??
                                "Joined At " +
                                            Get.find<ProfileController>()
                                                .join_date ==
                                        "null" ||
                                    Get.find<ProfileController>().join_date ==
                                        ""
                            ? ""
                            : DateFormat('d MMMM y').format(
                              DateTime.parse(
                                Get.find<ProfileController>().join_date,
                              ),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(
                          color: AppThemes.getBlack50Color(),
                        ),
                      ),

                      VSpace(35.h),

                      // FOOTER PORTION
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 32.h,
                          horizontal: 20.w,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12.h,
                                  height: 12.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.mainColor,
                                      width: 2.h,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 2.h,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors
                                              .mainColor, // E5F788 with 100% opacity
                                          AppColors.mainColor.withValues(
                                            alpha: 0,
                                          ), // E5F788 with 0% opacity
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  storedLanguage['Theme Mode'] ?? "Theme Mode",
                                  style: context.t.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 2.h,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.mainColor.withValues(
                                            alpha: 0,
                                          ), // E5F788 with 0% opacity
                                          AppColors
                                              .mainColor, // E5F788 with 100% opacity
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 12.h,
                                  height: 12.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.mainColor,
                                      width: 2.h,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            VSpace(16.h),
                            Container(
                              height: 48.h,
                              width: double.maxFinite,
                              padding: EdgeInsets.all(6.h),
                              decoration: BoxDecoration(
                                color: AppThemes.getFillColor(),
                                borderRadius: Dimensions.kBorderRadius,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: Dimensions.kBorderRadius,
                                      onTap: () {
                                        appController.selectedIndex = 0;
                                        appController.onChanged(null);
                                        appController.update();
                                      },
                                      child: Ink(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 6.h,
                                          horizontal: 35.w,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              appController.selectedIndex == 0
                                                  ? Get.isDarkMode
                                                      ? AppColors.darkBgColor
                                                      : AppColors.whiteColor
                                                  : Colors.transparent,
                                          borderRadius:
                                              Dimensions.kBorderRadius,
                                        ),
                                        child: Text(
                                          storedLanguage['Auto'] ?? "Auto",
                                          style: context.t.bodyMedium?.copyWith(
                                            fontSize: 14.sp,
                                            color:
                                                appController.selectedIndex == 0
                                                    ? AppColors.blackColor
                                                    : Get.isDarkMode
                                                    ? AppColors.whiteColor
                                                    : AppColors.blackColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: Dimensions.kBorderRadius,
                                      onTap: () {
                                        appController.selectedIndex = 1;
                                        appController.onChanged(true);
                                        appController.update();
                                      },
                                      child: Ink(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 6.h,
                                          horizontal: 35.w,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              appController.selectedIndex == 1
                                                  ? Get.isDarkMode
                                                      ? AppColors.darkBgColor
                                                      : AppColors.whiteColor
                                                  : Colors.transparent,
                                          borderRadius:
                                              Dimensions.kBorderRadius,
                                        ),
                                        child: Text(
                                          storedLanguage['On'] ?? "On",
                                          style: context.t.bodyMedium?.copyWith(
                                            fontSize: 14.sp,
                                            color:
                                                appController.selectedIndex == 1
                                                    ? AppColors.whiteColor
                                                    : Get.isDarkMode
                                                    ? AppColors.whiteColor
                                                    : AppColors.blackColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: Dimensions.kBorderRadius,
                                      onTap: () {
                                        appController.selectedIndex = 2;
                                        appController.onChanged(false);
                                        appController.update();
                                      },
                                      child: Ink(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 6.h,
                                          horizontal: 35.w,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              appController.selectedIndex == 2
                                                  ? AppColors.whiteColor
                                                  : Colors.transparent,
                                          borderRadius:
                                              Dimensions.kBorderRadius,
                                        ),
                                        child: Text(
                                          storedLanguage['Off'] ?? "Off",
                                          style: context.t.bodyMedium?.copyWith(
                                            fontSize: 14.sp,
                                            color:
                                                appController.selectedIndex == 2
                                                    ? AppColors.blackColor
                                                    : Get.isDarkMode
                                                    ? AppColors.whiteColor
                                                    : AppColors.blackColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            VSpace(40.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 20.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppThemes.getFillColor(),
                                borderRadius: Dimensions.kBorderRadius,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    storedLanguage['Profile Settings'] ??
                                        "Profile Settings",
                                    style: t.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20.sp,
                                    ),
                                  ),
                                  VSpace(25.h),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: 8,
                                    itemBuilder: (context, i) {
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              Dimensions.kBorderRadius,
                                        ),
                                        onTap: () {
                                          if (i == 0) {
                                            Get.toNamed(
                                              RoutesName.editProfileScreen,
                                            );
                                          } else if (i == 1) {
                                            Get.toNamed(
                                              RoutesName
                                                  .notificationPermissionScreen,
                                            );
                                          } else if (i == 2) {
                                            Get.toNamed(
                                              RoutesName.changePasswordScreen,
                                            );
                                          } else if (i == 3) {
                                            Get.toNamed(
                                              RoutesName.qrCodeScreen,
                                            );
                                          } else if (i == 4) {
                                            Get.find<VerificationController>()
                                                .getVerificationList();
                                            Get.toNamed(
                                              RoutesName.verificationListScreen,
                                            );
                                          } else if (i == 5) {
                                            Get.find<VerificationController>()
                                                .getTwoFa();
                                            Get.toNamed(
                                              RoutesName
                                                  .twoFaVerificationScreen,
                                            );
                                          } else if (i == 6) {
                                            Get.toNamed(
                                              RoutesName.deleteAccountScreen,
                                            );
                                          } else {
                                            buildLogoutDialog(
                                              context,
                                              t,
                                              storedLanguage,
                                            );
                                          }
                                        },
                                        leading: Container(
                                          height: i == 2 ? 38.h : 36.h,
                                          width: i == 2 ? 38.h : 36.h,
                                          padding: EdgeInsets.all(10.h),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18.r,
                                            ),
                                            color: AppThemes.getDarkBgColor(),
                                          ),
                                          child:
                                              i == 0
                                                  ? Image.asset(
                                                    "$rootImageDir/profile_edit.png",
                                                    color:
                                                        AppThemes.getIconBlackColor(),
                                                  )
                                                  : i == 1
                                                  ? Image.asset(
                                                    "$rootImageDir/notification.png",
                                                    color:
                                                        AppThemes.getIconBlackColor(),
                                                  )
                                                  : i == 2
                                                  ? Image.asset(
                                                    "$rootImageDir/lock_main.png",
                                                    color:
                                                        AppThemes.getIconBlackColor(),
                                                  )
                                                  : i == 3
                                                  ? Image.asset(
                                                    "$rootImageDir/qr_payment.png",
                                                    color:
                                                        AppThemes.getIconBlackColor(),
                                                  )
                                                  : i == 4
                                                  ? Image.asset(
                                                    "$rootImageDir/verification.png",
                                                    color:
                                                        AppThemes.getIconBlackColor(),
                                                  )
                                                  : i == 5
                                                  ? Image.asset(
                                                    "$rootImageDir/2fa.png",
                                                    color:
                                                        AppThemes.getIconBlackColor(),
                                                  )
                                                  : i == 6
                                                  ? Image.asset(
                                                    "$rootImageDir/delete_account.png",
                                                    color:
                                                        AppThemes.getIconBlackColor(),
                                                  )
                                                  : Image.asset(
                                                    "$rootImageDir/log_out.png",
                                                    color:
                                                        AppThemes.getIconBlackColor(),
                                                  ),
                                        ),
                                        title: Text(
                                          i == 0
                                              ? storedLanguage['Edit Profile'] ??
                                                  "Edit Profile"
                                              : i == 1
                                              ? storedLanguage['Notification'] ??
                                                  "Notification"
                                              : i == 2
                                              ? storedLanguage['Change Password'] ??
                                                  "Change Password"
                                              : i == 3
                                              ? storedLanguage['QR Code'] ??
                                                  "QR Code"
                                              : i == 4
                                              ? storedLanguage['Identity Verification'] ??
                                                  "Identity Verification"
                                              : i == 5
                                              ? storedLanguage['2FA Security'] ??
                                                  "2FA Security"
                                              : i == 6
                                              ? storedLanguage['Delete Account'] ??
                                                  "Delete Account"
                                              : storedLanguage['Log Out'] ??
                                                  "Log Out",
                                          style: t.displayMedium,
                                        ),
                                        trailing:
                                            i == 7
                                                ? const SizedBox.shrink()
                                                : Container(
                                                  height: 36.h,
                                                  width: 36.h,
                                                  padding: EdgeInsets.all(10.h),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6.r,
                                                        ),
                                                    color:
                                                        AppThemes.getDarkBgColor(),
                                                  ),
                                                  child: Icon(
                                                    Icons.arrow_forward_ios,
                                                    size: 16.h,
                                                  ),
                                                ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<dynamic> buildLogoutDialog(
    BuildContext context,
    TextTheme t,
    storedLanguage,
  ) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            storedLanguage['Log Out'] ?? "Log Out",
            style: t.bodyLarge?.copyWith(fontSize: 20.sp),
          ),
          content: Text(
            storedLanguage['Do you want to Log Out?'] ??
                "Do you want to Log Out?",
            style: t.bodyMedium,
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(storedLanguage['No'] ?? "No", style: t.bodyLarge),
            ),
            MaterialButton(
              onPressed: () async {
                HiveHelp.remove(Keys.token);
                HiveHelp.remove(Keys.isRemember);
                HiveHelp.remove(Keys.isLoggedIn);
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (_) {}
                Get.offAllNamed(RoutesName.loginScreen);
              },
              child: Text(storedLanguage['Yes'] ?? "Yes", style: t.bodyLarge),
            ),
          ],
        );
      },
    );
  }
}
