import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/app_colors.dart';
import '../../../controllers/app_controller.dart';
import '../../../controllers/app_lock_controller.dart';
import '../../../controllers/profile_controller.dart';
import '../../../controllers/subscription_controller.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../controllers/verification_controller.dart';
import '../../../controllers/worklist_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/language_service.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../../utils/services/voice_soundbox_service.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/language_selection_sheet.dart';
import '../../widgets/spacing.dart';
import '../../widgets/text_theme_extension.dart';

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
  final ProfileController controller = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    if (controller.profileList.isEmpty) {
      controller.getProfile();
    }
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
    final TextTheme t = Theme.of(context).textTheme;

    return GetBuilder<AppController>(
      builder: (appController) {
        final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
        return GetBuilder<ProfileController>(
          builder: (profileController) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                if (widget.isIdentityVerification == true ||
                    widget.isAddressVerification == true) {
                  Get.offAllNamed(RoutesName.bottomNavBar);
                } else {
                  Get.back();
                }
              },
              child: Scaffold(
                backgroundColor: Get.isDarkMode
                    ? AppColors.darkBgColor
                    : const Color(0xFFF7F9FC),
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: Get.isDarkMode
                      ? AppColors.darkBgColor
                      : const Color(0xFFF7F9FC),
                  centerTitle: false,
                  automaticallyImplyLeading: false,
                  leading: widget.isFromHomePage == true
                      ? IconButton(
                          onPressed: () {
                            if (widget.isIdentityVerification == true ||
                                widget.isAddressVerification == true) {
                              Get.offAllNamed(RoutesName.bottomNavBar);
                            } else {
                              Get.back();
                            }
                          },
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20.sp,
                            color: Get.isDarkMode
                                ? AppColors.whiteColor
                                : AppColors.blackColor,
                          ),
                        )
                      : null,
                  title: Text(
                    storedLanguage['Profile'] ?? "Profile",
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: Get.isDarkMode
                          ? AppColors.whiteColor
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        height: 38.h,
                        width: 38.h,
                        decoration: BoxDecoration(
                          color: Get.isDarkMode
                              ? AppColors.darkCardColor
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Get.isDarkMode
                                ? AppColors.black70
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Icon(
                          Icons.settings_outlined,
                          size: 20.sp,
                          color: Get.isDarkMode
                              ? AppColors.whiteColor
                              : const Color(0xFF475569),
                        ),
                      ),
                      onPressed: () => _showQuickSettingsSheet(context, appController, storedLanguage),
                    ),
                    SizedBox(width: 12.w),
                  ],
                ),
                body: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    children: [
                      // ── Store Header Card ─────────────────────────────────
                      _buildStoreHeaderCard(context, profileController, t),
                      VSpace(16.h),

                      // ── 6-Item Clean White Menu Card ──────────────────────
                      _buildMenuCard(context, profileController, storedLanguage),
                      VSpace(20.h),

                      // ── Logout Pill Button ────────────────────────────────
                      _buildLogoutButton(context, t, storedLanguage),
                      VSpace(32.h),
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

  // ── Store Header Card ──────────────────────────────────────────────────────
  Widget _buildStoreHeaderCard(
    BuildContext context,
    ProfileController profileCtrl,
    TextTheme t,
  ) {
    final String currentShopName = profileCtrl.displayShopName.isNotEmpty
        ? profileCtrl.displayShopName
        : "Sharma General Store";
    final bool isOnline = profileCtrl.isShopOnline;
    final String timings = profileCtrl.shopTimingDisplay;

    final String city = profileCtrl.cityEditingController.text.trim();
    final String state = profileCtrl.stateEditingController.text.trim();
    final String location = (city.isNotEmpty && state.isNotEmpty)
        ? "$city, $state"
        : (city.isNotEmpty ? city : "Hisar, Haryana");

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Get.isDarkMode
              ? AppColors.black70
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () {
                  if (profileCtrl.userPhoto.isNotEmpty) {
                    Get.to(
                      () => Scaffold(
                        appBar: const CustomAppBar(title: ""),
                        body: PhotoView(
                          imageProvider: NetworkImage(profileCtrl.userPhoto),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  height: 54.h,
                  width: 54.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEBF3FF),
                    border: Border.all(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
                      width: 2,
                    ),
                    image: (profileCtrl.isLoading ||
                            profileCtrl.userPhoto.isEmpty ||
                            profileCtrl.userPhoto.endsWith('/default.png'))
                        ? null
                        : DecorationImage(
                            image: CachedNetworkImageProvider(profileCtrl.userPhoto),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: (profileCtrl.userPhoto.isEmpty ||
                          profileCtrl.userPhoto.endsWith('/default.png'))
                      ? Center(
                          child: Icon(
                            Icons.storefront_rounded,
                            size: 26.sp,
                            color: const Color(0xFF1A73E8),
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(width: 12.w),

              // Store name & Location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentShopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Get.isDarkMode
                            ? AppColors.whiteColor
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13.sp,
                          color: const Color(0xFF64748B),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Premium Pill
              GetBuilder<SubscriptionController>(
                init: SubscriptionController.to,
                builder: (subCtrl) {
                  final planName = subCtrl.currentPlanName.isNotEmpty
                      ? subCtrl.currentPlanName
                      : "Premium";
                  return InkWell(
                    onTap: () => Get.toNamed(RoutesName.subscriptionPlansScreen),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: const Color(0xFF34A853).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            size: 14.sp,
                            color: const Color(0xFF137333),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            planName,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF137333),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Online / Offline & Timings Strip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Get.isDarkMode
                  ? AppColors.darkBgColor
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: Get.isDarkMode
                    ? AppColors.black70
                    : const Color(0xFFEDF2F7),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 7.r,
                  height: 7.r,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  isOnline ? "Open" : "Closed",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 1,
                  height: 12.h,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    timings,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.75,
                  child: Switch.adaptive(
                    value: isOnline,
                    activeTrackColor: const Color(0xFF10B981),
                    onChanged: (val) => profileCtrl.toggleShopOnlineStatus(val),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 6-Item Clean White Menu Card ───────────────────────────────────────────
  Widget _buildMenuCard(
    BuildContext context,
    ProfileController profileController,
    Map<dynamic, dynamic> storedLanguage,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Get.isDarkMode ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Get.isDarkMode
              ? AppColors.black70
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Business Profile
          _buildMenuTile(
            icon: Icons.storefront_outlined,
            title: "Business Profile",
            subtitle: "Shop details, timings & UPI",
            isFirst: true,
            onTap: () => _showBusinessProfileSheet(context, profileController, storedLanguage),
          ),
          _buildMenuDivider(),

          // 2. Credit Settings
          _buildMenuTile(
            icon: Icons.credit_card_outlined,
            title: "Credit Settings",
            subtitle: "Plans, credit limits & work list",
            onTap: () => _showCreditSettingsSheet(context, storedLanguage),
          ),
          _buildMenuDivider(),

          // 3. Notifications
          _buildMenuTile(
            icon: Icons.notifications_none_rounded,
            title: "Notifications",
            subtitle: "Voice Soundbox, alerts & reminders",
            onTap: () => _showNotificationSettingsSheet(context),
          ),
          _buildMenuDivider(),

          // 4. Security
          _buildMenuTile(
            icon: Icons.security_outlined,
            title: "Security",
            subtitle: "App Lock, 2FA & biometric",
            onTap: () => _showSecuritySheet(context, storedLanguage),
          ),
          _buildMenuDivider(),

          // 5. Help & Support
          _buildMenuTile(
            icon: Icons.help_outline_rounded,
            title: "Help & Support",
            subtitle: "FAQs, WhatsApp & customer care",
            onTap: () => _showHelpSupportSheet(context),
          ),
          _buildMenuDivider(),

          // 6. About UdharCard
          _buildMenuTile(
            icon: Icons.info_outline_rounded,
            title: "About UdharCard",
            subtitle: "Version, cloud backup & terms",
            isLast: true,
            onTap: () => _showAboutSheet(context, storedLanguage),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(16.r) : Radius.zero,
          bottom: isLast ? Radius.circular(16.r) : Radius.zero,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                height: 40.h,
                width: 40.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEBF3FF),
                ),
                child: Icon(
                  icon,
                  size: 20.sp,
                  color: const Color(0xFF1A73E8),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w600,
                        color: Get.isDarkMode
                            ? AppColors.whiteColor
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20.sp,
                color: const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 70.w,
      endIndent: 16.w,
      color: Get.isDarkMode
          ? AppColors.black70
          : const Color(0xFFF1F5F9),
    );
  }

  // ── Logout Pill Button ────────────────────────────────────────────────────
  Widget _buildLogoutButton(
    BuildContext context,
    TextTheme t,
    Map<dynamic, dynamic> storedLanguage,
  ) {
    return InkWell(
      onTap: () => buildLogoutDialog(context, t, storedLanguage),
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        height: 48.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: const Color(0xFFEF4444),
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              storedLanguage['Log Out'] ?? "Logout",
              style: TextStyle(
                color: const Color(0xFFEF4444),
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Business Profile Sheet ─────────────────────────────────────────────
  void _showBusinessProfileSheet(
    BuildContext context,
    ProfileController profileController,
    Map<dynamic, dynamic> storedLanguage,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getDarkCardColor(),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.black30,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                VSpace(14.h),
                Text(
                  "Business Profile",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                VSpace(4.h),
                Text(
                  "Manage your shop details, operating hours, and payment IDs",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppThemes.getParagraphColor(),
                  ),
                ),
                VSpace(16.h),

                // Edit Profile & Timings
                _buildSheetActionTile(
                  icon: Icons.edit_note_rounded,
                  title: "Edit Store & Owner Details",
                  subtitle: "Name, address, shop timings & closed days",
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.toNamed(RoutesName.editProfileScreen);
                  },
                ),

                // Merchant UPI ID
                _buildSheetActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Merchant UPI Address",
                  subtitle: profileController.merchantUpiId != null &&
                          profileController.merchantUpiId!.isNotEmpty
                      ? profileController.merchantUpiId!
                      : "Add personal/shop UPI ID for customer payments",
                  onTap: () {
                    Navigator.pop(ctx);
                    _showUpiAddressBottomSheet(context, profileController);
                  },
                ),

                // Merchant QR
                _buildSheetActionTile(
                  icon: Icons.qr_code_scanner_rounded,
                  title: "Upload Merchant Payment QR",
                  subtitle: profileController.customQrCodePath != null
                      ? "Custom QR Code active"
                      : "Upload QR image for receiving payments",
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.toNamed(RoutesName.qrCodeScreen);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 2. Credit Settings Sheet ──────────────────────────────────────────────
  void _showCreditSettingsSheet(
    BuildContext context,
    Map<dynamic, dynamic> storedLanguage,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getDarkCardColor(),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.black30,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                VSpace(14.h),
                Text(
                  "Credit Settings & Data",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                VSpace(4.h),
                Text(
                  "Manage subscription plan, ledger exports and collection targets",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppThemes.getParagraphColor(),
                  ),
                ),
                VSpace(16.h),

                // Subscription Plans
                _buildSheetActionTile(
                  icon: Icons.workspace_premium_rounded,
                  title: "My Subscription Plans",
                  subtitle: "Upgrade or renew to unlock higher limits & features",
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.toNamed(RoutesName.subscriptionPlansScreen);
                  },
                ),

                // Today Work List
                GetBuilder<WorkListController>(
                  builder: (workListController) {
                    return _buildSheetActionTile(
                      icon: Icons.event_note_rounded,
                      title: "Today Work List",
                      subtitle: workListController.pendingBadgeText == null
                          ? "Plan today, tomorrow, and follow-ups"
                          : workListController.pendingSummaryText,
                      onTap: () {
                        Navigator.pop(ctx);
                        Get.toNamed(RoutesName.workListScreen);
                      },
                    );
                  },
                ),

                // Export Ledger Backup
                _buildSheetActionTile(
                  icon: Icons.upload_file_rounded,
                  title: "Export Ledger Backup",
                  subtitle: "Download customer ledger data file (JSON) to phone",
                  onTap: () {
                    Navigator.pop(ctx);
                    UdharController.to.exportLedgerBackup();
                  },
                ),

                // Restore Ledger Backup
                _buildSheetActionTile(
                  icon: Icons.download_for_offline_rounded,
                  title: "Restore Ledger Backup",
                  subtitle: "Restore your ledger records from a backup file",
                  onTap: () {
                    Navigator.pop(ctx);
                    UdharController.to.importLedgerBackup();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 3. Notification & Voice Soundbox Sheet ────────────────────────────────
  void _showNotificationSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getDarkCardColor(),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.black30,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                VSpace(14.h),
                Text(
                  "Notifications & Voice Alerts",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                VSpace(4.h),
                Text(
                  "Configure instant audio alerts and collection reminders",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppThemes.getParagraphColor(),
                  ),
                ),
                VSpace(16.h),

                // Voice Soundbox Toggle
                Obx(() {
                  final isEnabled = Get.isRegistered<VoiceSoundboxService>()
                      ? VoiceSoundboxService.to.isSoundboxEnabled.value
                      : true;
                  return Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Get.isDarkMode
                          ? AppColors.darkBgColor
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFF00A86B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 38.h,
                          width: 38.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00A86B).withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.volume_up_rounded,
                            color: Color(0xFF00A86B),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Voice Soundbox Payment Alerts",
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                "Speaks payments received aloud in Hindi/English",
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppThemes.getParagraphColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          activeTrackColor: const Color(0xFF00A86B),
                          value: isEnabled,
                          onChanged: (val) {
                            if (Get.isRegistered<VoiceSoundboxService>()) {
                              VoiceSoundboxService.to.toggleSoundbox(val);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }),
                VSpace(12.h),

                // Test Voice Soundbox Button
                InkWell(
                  onTap: () {
                    if (Get.isRegistered<VoiceSoundboxService>()) {
                      VoiceSoundboxService.to.announcePayment(
                        amount: 500.0,
                        customerName: "Ramesh Kumar",
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A86B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: const Color(0xFF00A86B).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_fill_rounded,
                          size: 18.sp,
                          color: const Color(0xFF00A86B),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "Test Voice Soundbox (₹500 Received)",
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00A86B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                VSpace(12.h),

                // Push Notifications Permission
                _buildSheetActionTile(
                  icon: Icons.notifications_active_outlined,
                  title: "Push Notification Permissions",
                  subtitle: "Enable lockscreen & payment sound notifications",
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.toNamed(RoutesName.notificationPermissionScreen);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 4. Security Sheet ─────────────────────────────────────────────────────
  void _showSecuritySheet(
    BuildContext context,
    Map<dynamic, dynamic> storedLanguage,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getDarkCardColor(),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.black30,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                VSpace(14.h),
                Text(
                  "Security & Privacy",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                VSpace(4.h),
                Text(
                  "Protect your business ledgers and customer transactions",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppThemes.getParagraphColor(),
                  ),
                ),
                VSpace(16.h),

                // App Lock Switch
                GetBuilder<AppLockController>(
                  builder: (appLockCtrl) {
                    return Obx(() {
                      return Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Get.isDarkMode
                              ? AppColors.darkBgColor
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: const Color(0xFF1A73E8).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 38.h,
                              width: 38.h,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFEBF3FF),
                              ),
                              child: Icon(
                                Icons.fingerprint_rounded,
                                color: const Color(0xFF1A73E8),
                                size: 22.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "App Lock & Biometric",
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    "Require fingerprint / PIN when opening app",
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppThemes.getParagraphColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              activeTrackColor: const Color(0xFF1A73E8),
                              value: appLockCtrl.isAppLockEnabled.value,
                              onChanged: (val) => appLockCtrl.toggleAppLock(val),
                            ),
                          ],
                        ),
                      );
                    });
                  },
                ),
                VSpace(12.h),

                // 2FA Security
                _buildSheetActionTile(
                  icon: Icons.lock_outline_rounded,
                  title: "Two-Factor Authentication (2FA)",
                  subtitle: "Add an extra layer of OTP security to logins",
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.find<VerificationController>().getTwoFa();
                    Get.toNamed(RoutesName.twoFaVerificationScreen);
                  },
                ),

                // Identity Verification
                _buildSheetActionTile(
                  icon: Icons.verified_user_outlined,
                  title: "Identity & KYC Verification",
                  subtitle: "Verify merchant documents for higher limits",
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.find<VerificationController>().getVerificationList();
                    Get.toNamed(RoutesName.verificationListScreen);
                  },
                ),

                // Delete Account
                _buildSheetActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: "Delete Account",
                  subtitle: "Permanently delete your merchant profile and data",
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.toNamed(RoutesName.deleteAccountScreen);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 5. Help & Support Sheet ───────────────────────────────────────────────
  void _showHelpSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getDarkCardColor(),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.black30,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                VSpace(14.h),
                Text(
                  "Help & Support",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                VSpace(4.h),
                Text(
                  "We're here to help your store thrive with UdharCard",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppThemes.getParagraphColor(),
                  ),
                ),
                VSpace(16.h),

                // WhatsApp Support
                _buildSheetActionTile(
                  icon: Icons.chat_rounded,
                  title: "WhatsApp Merchant Support",
                  subtitle: "Chat directly with our merchant support team",
                  onTap: () async {
                    Navigator.pop(ctx);
                    final Uri waUri = Uri.parse(
                      "https://wa.me/919999999999?text=Hi%20UdharCard%20Support,%20I%20need%20assistance.",
                    );
                    if (await canLaunchUrl(waUri)) {
                      await launchUrl(waUri, mode: LaunchMode.externalApplication);
                    } else {
                      Helpers.showSnackBar(msg: "Could not open WhatsApp");
                    }
                  },
                ),

                // Call Helpline
                _buildSheetActionTile(
                  icon: Icons.phone_in_talk_rounded,
                  title: "Merchant Helpline",
                  subtitle: "Speak to a customer representative (Mon - Sat, 9am - 8pm)",
                  onTap: () async {
                    Navigator.pop(ctx);
                    final Uri telUri = Uri.parse("tel:1800123456");
                    if (await canLaunchUrl(telUri)) {
                      await launchUrl(telUri);
                    }
                  },
                ),

                // FAQs
                _buildSheetActionTile(
                  icon: Icons.quiz_outlined,
                  title: "Frequently Asked Questions (FAQs)",
                  subtitle: "How to record udhar, soundbox setup, QR & cloud backup",
                  onTap: () {
                    Navigator.pop(ctx);
                    _showFaqDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 6. About UdharCard Sheet ──────────────────────────────────────────────
  void _showAboutSheet(
    BuildContext context,
    Map<dynamic, dynamic> storedLanguage,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getDarkCardColor(),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.black30,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                VSpace(14.h),
                Text(
                  "About UdharCard",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                VSpace(4.h),
                Text(
                  "Smart Digital Khata & Credit Platform for Indian Merchants",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppThemes.getParagraphColor(),
                  ),
                ),
                VSpace(16.h),

                // App Version Info
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? '1.0.47';
                    final buildNumber = snapshot.data?.buildNumber ?? '';
                    final versionStr = buildNumber.isNotEmpty
                        ? 'v$version ($buildNumber)'
                        : 'v$version';
                    return _buildSheetActionTile(
                      icon: Icons.verified_rounded,
                      title: "App Version",
                      subtitle: "UdharCard Merchant App $versionStr",
                      badge: versionStr,
                      onTap: () {},
                    );
                  },
                ),

                // Google Drive Backup
                _buildSheetActionTile(
                  icon: Icons.cloud_sync_rounded,
                  title: "Google Drive Cloud Backup",
                  subtitle: "Automatic backup sync for customers & ledgers",
                  badge: "Coming Soon",
                  onTap: () {
                    Navigator.pop(ctx);
                    _showGoogleDriveComingSoonSheet(context);
                  },
                ),

                // Made with Love
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Text(
                      "Made with ❤️ for Indian Merchants",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
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

  // ── Quick Settings Sheet (Theme & Language) ───────────────────────────────
  void _showQuickSettingsSheet(
    BuildContext context,
    AppController appController,
    Map<dynamic, dynamic> storedLanguage,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getDarkCardColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.black30,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                VSpace(14.h),
                Text(
                  "App Settings",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                VSpace(16.h),

                // Theme Mode
                Text(
                  storedLanguage['Theme Mode'] ?? "Theme Mode",
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                VSpace(8.h),
                Container(
                  height: 42.h,
                  padding: EdgeInsets.all(4.h),
                  decoration: BoxDecoration(
                    color: Get.isDarkMode
                        ? AppColors.darkBgColor
                        : const Color(0xFFF1F5F9),
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
                VSpace(18.h),

                // Language
                _buildSheetActionTile(
                  icon: Icons.translate_rounded,
                  title: storedLanguage['App Language'] ?? "App Language",
                  subtitle: LanguageService.isHindi ? "हिंदी (Hindi) 🇮🇳" : "English 🇬🇧",
                  onTap: () {
                    Navigator.pop(ctx);
                    LanguageSelectionSheet.show(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? AppColors.darkBgColor
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDestructive
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : (Get.isDarkMode ? AppColors.black70 : const Color(0xFFEDF2F7)),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
        leading: Container(
          height: 38.h,
          width: 38.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDestructive
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFEBF3FF),
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: isDestructive
                ? const Color(0xFFEF4444)
                : const Color(0xFF1A73E8),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDestructive
                      ? const Color(0xFFEF4444)
                      : (Get.isDarkMode ? AppColors.whiteColor : const Color(0xFF1E293B)),
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5.sp,
            color: const Color(0xFF64748B),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 18.sp,
          color: const Color(0xFF94A3B8),
        ),
      ),
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
                ? (Get.isDarkMode ? AppColors.darkCardColor : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
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
                  ? (Get.isDarkMode ? AppColors.whiteColor : Colors.black)
                  : AppColors.black50,
            ),
          ),
        ),
      ),
    );
  }

  // ── UPI Bottom Sheet ──────────────────────────────────────────────────────
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.h + MediaQuery.of(ctx).padding.bottom,
              left: 20.w,
              right: 20.w,
              top: 16.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.black30,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                VSpace(16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Merchant UPI Address",
                      style: ctx.t.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close, size: 20.sp),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                VSpace(10.h),
                Text(
                  "Add your UPI ID (e.g., shop@upi or 9876543210@paytm) so customers can send payments directly to your UPI handle.",
                  style: ctx.t.bodyMedium?.copyWith(
                    color: AppThemes.getParagraphColor(),
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                ),
                VSpace(18.h),
                TextField(
                  controller: upiCtrl,
                  style: ctx.t.bodyMedium?.copyWith(fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: "Enter UPI ID (e.g. name@upi)",
                    hintStyle: ctx.t.bodySmall?.copyWith(
                      color: AppColors.textFieldHintColor,
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.qr_code_2,
                      color: AppColors.mainColor,
                      size: 22.sp,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.mainColor,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AppThemes.getFillColor(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 14.h,
                    ),
                  ),
                ),
                VSpace(20.h),
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
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: () {
                            profileController.removeMerchantUpiId();
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            "Remove",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      HSpace(12.w),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () {
                          if (upiCtrl.text.trim().isEmpty) {
                            Helpers.showSnackBar(
                              msg: "Please enter a valid UPI ID",
                            );
                            return;
                          }
                          profileController.saveMerchantUpiId(
                            upiCtrl.text.trim(),
                          );
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          "Save UPI ID",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Google Drive Coming Soon Sheet ─────────────────────────────────────────
  void _showGoogleDriveComingSoonSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getDarkCardColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_sync_rounded,
                    size: 48.r,
                    color: const Color(0xFF1A73E8),
                  ),
                ),
                VSpace(16.h),
                Text(
                  "Google Drive Backup",
                  style: ctx.t.headlineMedium?.copyWith(
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
                  style: ctx.t.displayMedium?.copyWith(
                    color: AppThemes.getParagraphColor(),
                  ),
                ),
                VSpace(24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      "Got It",
                      style: TextStyle(
                        color: Colors.white,
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

  void _showFaqDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("FAQs & Guides"),
        content: const SingleChildScrollView(
          child: Text(
            "1. How to give Udhar?\nTap '+ New Udhar' on Home or Customers screen, enter amount & customer details.\n\n"
            "2. How to collect payment?\nOpen customer ledger, tap 'Collect', enter amount received.\n\n"
            "3. What is Voice Soundbox?\nWhen turned on, your phone speaks payment received aloud automatically!\n\n"
            "4. How to take backup?\nGo to Credit Settings -> Export Ledger Backup to save your data file.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // ── Logout Dialog ──────────────────────────────────────────────────────────
  Future<dynamic> buildLogoutDialog(
    BuildContext context,
    TextTheme t,
    Map<dynamic, dynamic> storedLanguage,
  ) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(
            storedLanguage['Log Out'] ?? "Log Out",
            style: t.bodyLarge?.copyWith(fontSize: 20.sp),
          ),
          content: Text(
            storedLanguage['Do you want to Log Out?'] ?? "Do you want to Log Out?",
            style: t.bodyMedium,
          ),
          actions: [
            MaterialButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
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
              child: Text(
                storedLanguage['Yes'] ?? "Yes",
                style: t.bodyLarge?.copyWith(color: AppColors.redColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
