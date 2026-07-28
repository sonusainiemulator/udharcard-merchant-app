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
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                                  _buildProfileSettingsList(
                                    context,
                                    t,
                                    storedLanguage,
                                    profileController,
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

  Widget _buildProfileSettingsList(
    BuildContext context,
    TextTheme t,
    dynamic storedLanguage,
    ProfileController profileController,
  ) {
    final List<_ProfileMenuItem> items = [
      _ProfileMenuItem(
        title: storedLanguage['Edit Profile'] ?? "Edit Profile",
        imageAsset: "$rootImageDir/profile_edit.png",
        onTap: () => Get.toNamed(RoutesName.editProfileScreen),
      ),
      _ProfileMenuItem(
        title: storedLanguage['Merchant UPI Address'] ?? "Merchant UPI Address",
        iconData: Icons.account_balance_wallet_outlined,
        subtitle: profileController.merchantUpiId != null &&
                profileController.merchantUpiId!.isNotEmpty
            ? profileController.merchantUpiId
            : "Add personal/shop UPI ID",
        onTap: () => _showUpiAddressBottomSheet(context, profileController),
      ),
      _ProfileMenuItem(
        title: storedLanguage['Upload QR Code'] ?? "Upload QR Code",
        imageAsset: "$rootImageDir/qr_payment.png",
        subtitle: profileController.customQrCodePath != null
            ? "Merchant QR Uploaded"
            : "Upload store QR image",
        onTap: () => Get.toNamed(RoutesName.qrCodeScreen),
      ),
      _ProfileMenuItem(
        title: storedLanguage['Google Drive Backup'] ?? "Google Drive Backup",
        iconData: Icons.cloud_sync_rounded,
        badgeText: "Coming Soon",
        onTap: () => _showGoogleDriveComingSoonSheet(context),
      ),
      _ProfileMenuItem(
        title: storedLanguage['Notification'] ?? "Notification",
        imageAsset: "$rootImageDir/notification.png",
        onTap: () => Get.toNamed(RoutesName.notificationPermissionScreen),
      ),
      _ProfileMenuItem(
        title: storedLanguage['Identity Verification'] ?? "Identity Verification",
        imageAsset: "$rootImageDir/verification.png",
        onTap: () {
          Get.find<VerificationController>().getVerificationList();
          Get.toNamed(RoutesName.verificationListScreen);
        },
      ),
      _ProfileMenuItem(
        title: storedLanguage['2FA Security'] ?? "2FA Security",
        imageAsset: "$rootImageDir/2fa.png",
        onTap: () {
          Get.find<VerificationController>().getTwoFa();
          Get.toNamed(RoutesName.twoFaVerificationScreen);
        },
      ),
      _ProfileMenuItem(
        title: storedLanguage['Delete Account'] ?? "Delete Account",
        imageAsset: "$rootImageDir/delete_account.png",
        onTap: () => Get.toNamed(RoutesName.deleteAccountScreen),
      ),
      _ProfileMenuItem(
        title: storedLanguage['Log Out'] ?? "Log Out",
        imageAsset: "$rootImageDir/log_out.png",
        isLogout: true,
        onTap: () => buildLogoutDialog(context, t, storedLanguage),
      ),
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => VSpace(4.h),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: Dimensions.kBorderRadius,
          ),
          onTap: item.onTap,
          leading: Container(
            height: 38.h,
            width: 38.h,
            padding: EdgeInsets.all(9.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              color: AppThemes.getDarkBgColor(),
            ),
            child: item.iconData != null
                ? Icon(
                    item.iconData,
                    size: 20.h,
                    color: AppThemes.getIconBlackColor(),
                  )
                : Image.asset(
                    item.imageAsset!,
                    color: AppThemes.getIconBlackColor(),
                  ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: t.displayMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (item.badgeText != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.amber.shade700, width: 1.w),
                  ),
                  child: Text(
                    item.badgeText!,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: item.subtitle != null
              ? Text(
                  item.subtitle!,
                  style: t.bodySmall?.copyWith(
                    color: AppThemes.getBlack50Color(),
                    fontSize: 11.sp,
                  ),
                )
              : null,
          trailing: item.isLogout
              ? const SizedBox.shrink()
              : Container(
                  height: 32.h,
                  width: 32.h,
                  padding: EdgeInsets.all(8.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.r),
                    color: AppThemes.getDarkBgColor(),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14.h,
                  ),
                ),
        );
      },
    );
  }

  void _showUpiAddressBottomSheet(
    BuildContext context,
    ProfileController profileController,
  ) {
    final TextEditingController upiCtrl = TextEditingController(
      text: profileController.merchantUpiId ?? '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemes.getDarkCardColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
            left: 20.w,
            right: 20.w,
            top: 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Merchant UPI Address",
                    style: context.t.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              VSpace(10.h),
              Text(
                "Add your UPI ID (e.g., shop@upi or 9876543210@paytm) so customers can send payments directly to your UPI handle.",
                style: context.t.displaySmall?.copyWith(
                  color: AppThemes.getParagraphColor(),
                ),
              ),
              VSpace(20.h),
              TextField(
                controller: upiCtrl,
                style: context.t.displayMedium,
                decoration: InputDecoration(
                  hintText: "Enter UPI ID (e.g. name@upi)",
                  prefixIcon: Icon(Icons.qr_code, color: AppColors.mainColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: AppThemes.getFillColor(),
                ),
              ),
              VSpace(24.h),
              Row(
                children: [
                  if (profileController.merchantUpiId != null &&
                      profileController.merchantUpiId!.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        onPressed: () {
                          profileController.removeMerchantUpiId();
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Remove",
                          style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
                        ),
                      ),
                    ),
                    HSpace(12.w),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () {
                        if (upiCtrl.text.trim().isEmpty) {
                          Helpers.showSnackBar(msg: "Please enter a valid UPI ID");
                          return;
                        }
                        profileController.saveMerchantUpiId(upiCtrl.text.trim());
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Save UPI ID",
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              VSpace(10.h),
            ],
          ),
        );
      },
    );
  }

  void _showGoogleDriveComingSoonSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getDarkCardColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_sync_rounded,
                    size: 48.r,
                    color: AppColors.mainColor,
                  ),
                ),
                VSpace(16.h),
                Text(
                  "Google Drive Backup",
                  style: context.t.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                VSpace(8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Text(
                    "Coming Soon",
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                VSpace(16.h),
                Text(
                  "Automated Google Drive cloud backup for your shop ledgers and customer transaction history will be available in the upcoming release!",
                  textAlign: TextAlign.center,
                  style: context.t.displayMedium?.copyWith(
                    color: AppThemes.getParagraphColor(),
                  ),
                ),
                VSpace(24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Got It",
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

class _ProfileMenuItem {
  final String title;
  final String? imageAsset;
  final IconData? iconData;
  final String? subtitle;
  final String? badgeText;
  final bool isLogout;
  final VoidCallback onTap;

  _ProfileMenuItem({
    required this.title,
    this.imageAsset,
    this.iconData,
    this.subtitle,
    this.badgeText,
    this.isLogout = false,
    required this.onTap,
  });
}
