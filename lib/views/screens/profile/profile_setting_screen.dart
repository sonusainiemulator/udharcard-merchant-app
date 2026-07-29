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
import '../../../controllers/udhar_controller.dart';
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
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    children: [
                      // ── Profile Hero Header ────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: AppThemes.getFillColor(),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Get.isDarkMode ? AppColors.black70 : AppColors.borderColor.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
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
                              child: Stack(
                                children: [
                                  Container(
                                    height: 90.h,
                                    width: 90.h,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.mainColor,
                                        width: 3.h,
                                      ),
                                      color: AppColors.imageBgColor,
                                      image: Get.find<ProfileController>().isLoading ||
                                              Get.find<ProfileController>().userPhoto == ''
                                          ? DecorationImage(
                                              image: AssetImage("$rootImageDir/avatar.webp"),
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
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(4.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.mainColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 16.sp,
                                        color: AppColors.blackColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            VSpace(12.h),
                            Text(
                              Get.find<ProfileController>().isLoading
                                  ? ""
                                  : Get.find<ProfileController>().userName,
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.sp,
                              ),
                            ),
                            VSpace(4.h),
                            Text(
                              Get.find<ProfileController>().isLoading
                                  ? ""
                                  : (Get.find<ProfileController>().join_date != "null" &&
                                          Get.find<ProfileController>().join_date.isNotEmpty)
                                      ? "Member since ${DateFormat('MMM yyyy').format(DateTime.parse(Get.find<ProfileController>().join_date))}"
                                      : "Active Merchant Account",
                              style: t.bodySmall?.copyWith(
                                color: AppThemes.getBlack50Color(),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      VSpace(16.h),

                      // ── Appearance / Theme Switcher Card ───────────────────
                      Container(
                        padding: EdgeInsets.all(16.h),
                        decoration: BoxDecoration(
                          color: AppThemes.getFillColor(),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Get.isDarkMode ? AppColors.black70 : AppColors.borderColor.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.brightness_6_outlined, size: 18.sp, color: AppColors.mainColor),
                                HSpace(8.w),
                                Text(
                                  storedLanguage['Theme Mode'] ?? "Theme Mode",
                                  style: t.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                            VSpace(12.h),
                            Container(
                              height: 42.h,
                              padding: EdgeInsets.all(4.h),
                              decoration: BoxDecoration(
                                color: Get.isDarkMode ? AppColors.darkBgColor : AppColors.black10.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  _buildSegmentTab(
                                    label: storedLanguage['Auto'] ?? "Auto",
                                    isSelected: appController.selectedIndex == 0,
                                    onTap: () {
                                      appController.selectedIndex = 0;
                                      appController.onChanged(null);
                                      appController.update();
                                    },
                                  ),
                                  _buildSegmentTab(
                                    label: storedLanguage['Dark'] ?? "Dark",
                                    isSelected: appController.selectedIndex == 1,
                                    onTap: () {
                                      appController.selectedIndex = 1;
                                      appController.onChanged(true);
                                      appController.update();
                                    },
                                  ),
                                  _buildSegmentTab(
                                    label: storedLanguage['Light'] ?? "Light",
                                    isSelected: appController.selectedIndex == 2,
                                    onTap: () {
                                      appController.selectedIndex = 2;
                                      appController.onChanged(false);
                                      appController.update();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      VSpace(16.h),

                      // ── Section 1: Store & Payments ───────────────────────
                      _buildGroupedSection(
                        title: storedLanguage['Store & Payments'] ?? "Store & Payments",
                        items: [
                          _ProfileMenuItem(
                            title: storedLanguage['Edit Profile'] ?? "Edit Profile",
                            iconData: Icons.person_outline_rounded,
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
                            iconData: Icons.qr_code_scanner_rounded,
                            subtitle: profileController.customQrCodePath != null
                                ? "Merchant QR Uploaded"
                                : "Upload store QR image",
                            onTap: () => Get.toNamed(RoutesName.qrCodeScreen),
                          ),
                        ],
                        t: t,
                      ),
                      VSpace(16.h),

                      // ── Section 2: Data & Backup ──────────────────────────
                      _buildGroupedSection(
                        title: storedLanguage['Data & Backup'] ?? "Data & Backup",
                        items: [
                          _ProfileMenuItem(
                            title: storedLanguage['Export Ledger Backup'] ?? "Export Ledger Backup",
                            iconData: Icons.upload_file_rounded,
                            subtitle: "Save JSON backup to phone/share",
                            onTap: () => UdharController.to.exportLedgerBackup(),
                          ),
                          _ProfileMenuItem(
                            title: storedLanguage['Restore Backup'] ?? "Restore Backup",
                            iconData: Icons.download_for_offline_rounded,
                            subtitle: "Restore customer ledgers from backup file",
                            onTap: () => UdharController.to.importLedgerBackup(),
                          ),
                          _ProfileMenuItem(
                            title: storedLanguage['Google Drive Backup'] ?? "Google Drive Backup",
                            iconData: Icons.cloud_sync_rounded,
                            badgeText: "Coming Soon",
                            onTap: () => _showGoogleDriveComingSoonSheet(context),
                          ),
                        ],
                        t: t,
                      ),
                      VSpace(16.h),

                      // ── Section 3: Security & Preferences ───────────────
                      _buildGroupedSection(
                        title: storedLanguage['Security & Preferences'] ?? "Security & Preferences",
                        items: [
                          _ProfileMenuItem(
                            title: storedLanguage['Notification'] ?? "Notification",
                            iconData: Icons.notifications_none_rounded,
                            onTap: () => Get.toNamed(RoutesName.notificationPermissionScreen),
                          ),
                          _ProfileMenuItem(
                            title: storedLanguage['Identity Verification'] ?? "Identity Verification",
                            iconData: Icons.verified_user_outlined,
                            onTap: () {
                              Get.find<VerificationController>().getVerificationList();
                              Get.toNamed(RoutesName.verificationListScreen);
                            },
                          ),
                          _ProfileMenuItem(
                            title: storedLanguage['2FA Security'] ?? "2FA Security",
                            iconData: Icons.security_outlined,
                            onTap: () {
                              Get.find<VerificationController>().getTwoFa();
                              Get.toNamed(RoutesName.twoFaVerificationScreen);
                            },
                          ),
                          _ProfileMenuItem(
                            title: storedLanguage['Delete Account'] ?? "Delete Account",
                            iconData: Icons.delete_outline_rounded,
                            onTap: () => Get.toNamed(RoutesName.deleteAccountScreen),
                          ),
                        ],
                        t: t,
                      ),
                      VSpace(16.h),

                      // ── Section 4: Log Out ─────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: AppThemes.getFillColor(),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.redColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => buildLogoutDialog(context, t, storedLanguage),
                          leading: Container(
                            height: 36.h,
                            width: 36.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.redColor.withValues(alpha: 0.1),
                            ),
                            child: Icon(Icons.logout_rounded, color: AppColors.redColor, size: 20.sp),
                          ),
                          title: Text(
                            storedLanguage['Log Out'] ?? "Log Out",
                            style: t.bodyMedium?.copyWith(
                              color: AppColors.redColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      VSpace(30.h),
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

  Widget _buildSegmentTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? (Get.isDarkMode ? AppColors.whiteColor : AppColors.blackColor)
                  : AppColors.black50,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedSection({
    required String title,
    required List<_ProfileMenuItem> items,
    required TextTheme t,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemes.getFillColor(),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Get.isDarkMode ? AppColors.black70 : AppColors.borderColor.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 14.h, bottom: 6.h),
            child: Text(
              title.toUpperCase(),
              style: t.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11.sp,
                color: AppColors.mainColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 52.w,
              endIndent: 16.w,
              color: Get.isDarkMode ? AppColors.black70 : AppColors.borderColor.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                onTap: item.onTap,
                leading: Container(
                  height: 36.h,
                  width: 36.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mainColor.withValues(alpha: 0.12),
                  ),
                  child: item.iconData != null
                      ? Icon(item.iconData, size: 20.sp, color: AppColors.blackColor)
                      : (item.imageAsset != null
                          ? Center(
                              child: Image.asset(
                                item.imageAsset!,
                                height: 18.sp,
                                width: 18.sp,
                                color: AppColors.blackColor,
                              ),
                            )
                          : Icon(Icons.tune, size: 20.sp, color: AppColors.blackColor)),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: t.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    if (item.badgeText != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.amber.shade700, width: 0.8),
                        ),
                        child: Text(
                          item.badgeText!,
                          style: TextStyle(
                            fontSize: 9.sp,
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
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20.sp,
                  color: AppColors.black30,
                ),
              );
            },
          ),
        ],
      ),
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
