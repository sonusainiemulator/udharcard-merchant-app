import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../../config/app_colors.dart';
import '../../../controllers/app_controller.dart';
import '../../../controllers/profile_controller.dart';
import '../../../data/models/profile_model.dart';
import '../../../themes/themes.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_custom_dropdown.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameCtrl;
  var selectedLanguageVal;

  static const List<String> businessCategories = [
    'Kirana & Grocery Store',
    'Dairy & Milk Products',
    'Medical & Pharmacy',
    'Clothing & Garments',
    'Electronics & Mobile Repair',
    'Hardware, Paint & Sanitary',
    'Vegetables & Fruits',
    'Restaurant & Sweet Shop',
    'Bakery & Confectionery',
    'Stationery & Book Depot',
    'Jewellery & Watch',
    'Automobile & Spare Parts',
    'General Store / Other',
  ];

  static const List<String> weeklyOffOptions = [
    'Open All Days',
    'Sunday Closed',
    'Monday Closed',
    'Tuesday Closed',
    'Wednesday Closed',
    'Thursday Closed',
    'Friday Closed',
    'Saturday Closed',
  ];

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    try {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        final parsed = DateFormat.jm().parseLoose(text);
        initial = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      }
    } catch (_) {}

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      controller.text = DateFormat('hh:mm a').format(dt);
      setState(() {});
    }
  }

  Widget _buildTimeField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required TextTheme t,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, t),
        VSpace(8.h),
        InkWell(
          onTap: () => _selectTime(context, controller),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: Get.isDarkMode
                  ? AppColors.darkBgColor
                  : AppColors.black10.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppThemes.getSliderInactiveColor(),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: AppColors.mainColor,
                  size: 20.sp,
                ),
                HSpace(10.w),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? "Select Time" : controller.text,
                    style: t.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppThemes.getBlack50Color(),
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    final profileController = Get.find<ProfileController>();
    final initialName = "${profileController.fNameEditingController.text} ${profileController.lNameEditingController.text}".trim();
    _fullNameCtrl = TextEditingController(text: initialName);
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    super.dispose();
  }

  void _syncNames(String val, ProfileController profileController) {
    final trimmed = val.trim();
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isEmpty || (parts.length == 1 && parts.first.isEmpty)) {
      profileController.fNameEditingController.text = '';
      profileController.lNameEditingController.text = '';
    } else if (parts.length == 1) {
      profileController.fNameEditingController.text = parts.first;
      profileController.lNameEditingController.text = parts.first;
    } else {
      profileController.fNameEditingController.text = parts.first;
      profileController.lNameEditingController.text = parts.sublist(1).join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    TextTheme t = Theme.of(context).textTheme;
    Get.find<ProfileController>().isLanguageSelected = false;
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        if (_fullNameCtrl.text.trim().isEmpty) {
          final currentName =
              "${profileController.fNameEditingController.text} ${profileController.lNameEditingController.text}"
                  .trim();
          if (currentName.isNotEmpty) {
            _fullNameCtrl.text = currentName;
          }
        }
        return GetBuilder<AppController>(
          builder: (appController) {
            var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
            return Scaffold(
              backgroundColor: AppThemes.getDarkBgColor(),
              appBar: CustomAppBar(
                isReverseIconBgColor: true,
                title: storedLanguage['Edit Profile'] ?? "Edit Profile",
              ),
              body: RefreshIndicator(
                color: AppColors.mainColor,
                onRefresh: () async {
                  await profileController.getProfile(
                    isFromRefreshIndicator: true,
                  );
                  final initialName = "${profileController.fNameEditingController.text} ${profileController.lNameEditingController.text}".trim();
                  _fullNameCtrl.text = initialName;
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile Photo Header ────────────────────────────
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppThemes.getFillColor(),
                          border: Border(
                            bottom: BorderSide(
                              color: Get.isDarkMode
                                  ? AppColors.black70
                                  : AppColors.borderColor.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 28.h),
                        child: Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (profileController.userPhoto != '') {
                                    Get.to(
                                      () => Scaffold(
                                        appBar: const CustomAppBar(title: ""),
                                        body: PhotoView(
                                          imageProvider: NetworkImage(
                                            profileController.userPhoto,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 100.h,
                                      width: 100.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.mainColor,
                                          width: 3.h,
                                        ),
                                        color: AppColors.imageBgColor,
                                        image: profileController.pickedImage != null
                                            ? DecorationImage(
                                                image: FileImage(
                                                  File(profileController.pickedImage!.path),
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : (profileController.isLoading ||
                                                    profileController.userPhoto == '' ||
                                                    profileController.userPhoto.endsWith('/default.png'))
                                                ? DecorationImage(
                                                    image: AssetImage(
                                                      "$rootImageDir/avatar.webp",
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                : DecorationImage(
                                                    image: CachedNetworkImageProvider(
                                                      profileController.userPhoto,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                      ),
                                      child: profileController.isUpdateProfile
                                          ? Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black.withValues(alpha: 0.45),
                                              ),
                                              child: Center(
                                                child: SizedBox(
                                                  height: 28.h,
                                                  width: 28.h,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    color: AppColors.mainColor,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () async {
                                          await showbottomsheet(
                                            context,
                                            storedLanguage,
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(8.h),
                                          decoration: BoxDecoration(
                                            color: AppColors.mainColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppThemes.getDarkBgColor(),
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.camera_alt_rounded,
                                            color: AppColors.blackColor,
                                            size: 16.h,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              VSpace(12.h),
                              Text(
                                profileController.isLoading
                                    ? ""
                                    : profileController.userName,
                                style: t.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17.sp,
                                ),
                              ),
                              VSpace(4.h),
                              Text(
                                profileController.userEmail,
                                style: t.bodySmall?.copyWith(
                                  color: AppThemes.getBlack50Color(),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Form Fields ─────────────────────────────────────
                      profileController.isLoading
                          ? Padding(
                              padding: EdgeInsets.only(top: 40.h),
                              child: Helpers.appLoader(),
                            )
                          : Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 20.h,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Store Status & Timings Card ─────────────────────────
                                  _buildSectionCard(
                                    title: "Shop Status & Timings",
                                    children: [
                                      // Online / Offline Status Toggle
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14.w,
                                          vertical: 12.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: profileController.isShopOnline
                                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                              : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: profileController.isShopOnline
                                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                                : const Color(0xFFEF4444).withValues(alpha: 0.4),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(8.h),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: profileController.isShopOnline
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFEF4444),
                                              ),
                                              child: Icon(
                                                profileController.isShopOnline
                                                    ? Icons.storefront_rounded
                                                    : Icons.store_mall_directory_outlined,
                                                color: Colors.white,
                                                size: 20.sp,
                                              ),
                                            ),
                                            HSpace(12.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    profileController.isShopOnline
                                                        ? "Store is OPEN (Online)"
                                                        : "Store is CLOSED (Offline)",
                                                    style: t.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14.sp,
                                                      color: profileController.isShopOnline
                                                          ? const Color(0xFF10B981)
                                                          : const Color(0xFFEF4444),
                                                    ),
                                                  ),
                                                  VSpace(2.h),
                                                  Text(
                                                    profileController.isShopOnline
                                                        ? "Accepting orders & customer payments"
                                                        : "Dukan filhal band hai",
                                                    style: t.bodySmall?.copyWith(
                                                      fontSize: 11.sp,
                                                      color: AppThemes.getBlack50Color(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Switch(
                                              value: profileController.isShopOnline,
                                              activeThumbColor: const Color(0xFF10B981),
                                              inactiveThumbColor: const Color(0xFFEF4444),
                                              onChanged: (val) {
                                                profileController.isShopOnline = val;
                                                profileController.update();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      VSpace(16.h),

                                      // Shop Timings (Opening & Closing)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTimeField(
                                              context: context,
                                              label: "Opening Time",
                                              controller: profileController.shopOpeningTimeEditingController,
                                              t: t,
                                            ),
                                          ),
                                          HSpace(12.w),
                                          Expanded(
                                            child: _buildTimeField(
                                              context: context,
                                              label: "Closing Time",
                                              controller: profileController.shopClosingTimeEditingController,
                                              t: t,
                                            ),
                                          ),
                                        ],
                                      ),
                                      VSpace(16.h),

                                      // Weekly Off / Closed Days
                                      _buildFieldLabel("Weekly Off / Holiday", t),
                                      VSpace(8.h),
                                      Container(
                                        height: 52.h,
                                        decoration: BoxDecoration(
                                          color: Get.isDarkMode
                                              ? AppColors.darkBgColor
                                              : AppColors.black10.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: AppThemes.getSliderInactiveColor(),
                                            width: 1,
                                          ),
                                        ),
                                        child: AppCustomDropDown(
                                          height: 50.h,
                                          width: double.infinity,
                                          items: weeklyOffOptions,
                                          selectedValue: weeklyOffOptions.contains(
                                                  profileController.shopClosedDaysEditingController.text.trim())
                                              ? profileController.shopClosedDaysEditingController.text.trim()
                                              : weeklyOffOptions.first,
                                          onChanged: (val) {
                                            if (val != null) {
                                              profileController.shopClosedDaysEditingController.text =
                                                  val.toString();
                                              profileController.update();
                                            }
                                          },
                                          hint: "Select Weekly Off",
                                          selectedStyle: t.displayMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  VSpace(16.h),

                                  // ── Shop & Business Details Card ─────────────────────────
                                  _buildSectionCard(
                                    title: "Shop & Business Details",
                                    children: [
                                      _buildFieldLabel("Shop / Store Name", t),
                                      VSpace(8.h),
                                      _buildTextField(
                                        controller: profileController.shopNameEditingController,
                                        hint: "e.g. Verma Kirana & General Store",
                                        prefixIcon: Icons.storefront_rounded,
                                        t: t,
                                      ),
                                      VSpace(16.h),
                                      _buildFieldLabel("Business Category", t),
                                      VSpace(8.h),
                                      Container(
                                        height: 52.h,
                                        decoration: BoxDecoration(
                                          color: Get.isDarkMode
                                              ? AppColors.darkBgColor
                                              : AppColors.black10.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: AppThemes.getSliderInactiveColor(),
                                            width: 1,
                                          ),
                                        ),
                                        child: AppCustomDropDown(
                                          height: 50.h,
                                          width: double.infinity,
                                          items: businessCategories,
                                          selectedValue: businessCategories.contains(
                                                  profileController.businessTypeEditingController.text.trim())
                                              ? profileController.businessTypeEditingController.text.trim()
                                              : null,
                                          onChanged: (val) {
                                            if (val != null) {
                                              profileController.businessTypeEditingController.text =
                                                  val.toString();
                                              profileController.update();
                                            }
                                          },
                                          hint: "Select Business Category",
                                          selectedStyle: t.displayMedium,
                                        ),
                                      ),
                                      VSpace(16.h),
                                      _buildFieldLabel("Shop Description / Tagline", t),
                                      VSpace(8.h),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Get.isDarkMode
                                              ? AppColors.darkBgColor
                                              : AppColors.black10.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: AppThemes.getSliderInactiveColor(),
                                            width: 1,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: profileController.shopDescEditingController,
                                          maxLines: 2,
                                          style: t.bodyMedium?.copyWith(fontSize: 14.sp),
                                          decoration: InputDecoration(
                                            hintText: "e.g. Best quality grocery items at wholesale prices in market.",
                                            hintStyle: t.bodySmall?.copyWith(
                                              color: AppColors.textFieldHintColor,
                                              fontSize: 13.sp,
                                            ),
                                            prefixIcon: Padding(
                                              padding: EdgeInsets.only(bottom: 20.h),
                                              child: Icon(
                                                Icons.description_outlined,
                                                color: AppColors.mainColor,
                                                size: 20.sp,
                                              ),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12.w,
                                              vertical: 12.h,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  VSpace(16.h),

                                  // ── Merchant Owner & Contact Details Card ────────────────
                                  _buildSectionCard(
                                    title: "Owner & Contact Info",
                                    children: [
                                      // Full Name
                                      _buildFieldLabel(
                                        storedLanguage['Full Name'] ?? "Owner / Merchant Name",
                                        t,
                                      ),
                                      VSpace(8.h),
                                      _buildTextField(
                                        controller: _fullNameCtrl,
                                        onChanged: (val) => _syncNames(val, profileController),
                                        hint: storedLanguage['Enter Full Name'] ?? "Enter Owner Full Name",
                                        prefixIcon: Icons.person_outline_rounded,
                                        t: t,
                                      ),
                                      VSpace(16.h),
                                      _buildFieldLabel(
                                        storedLanguage['Phone Number'] ?? "Primary Phone Number",
                                        t,
                                      ),
                                      VSpace(8.h),
                                      // India fixed phone field
                                      Container(
                                        height: 52.h,
                                        decoration: BoxDecoration(
                                          color: Get.isDarkMode
                                              ? AppColors.darkBgColor
                                              : AppColors.black10.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: AppThemes.getSliderInactiveColor(),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "🇮🇳",
                                                    style: TextStyle(fontSize: 20.sp),
                                                  ),
                                                  HSpace(6.w),
                                                  Text(
                                                    "+91",
                                                    style: t.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              height: 28.h,
                                              color: AppThemes.getSliderInactiveColor(),
                                            ),
                                            Expanded(
                                              child: TextField(
                                                controller: profileController.phoneNumberEditingController,
                                                keyboardType: TextInputType.phone,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                  LengthLimitingTextInputFormatter(10),
                                                ],
                                                style: t.bodyMedium?.copyWith(fontSize: 14.sp),
                                                decoration: InputDecoration(
                                                  hintText: storedLanguage['Enter Number'] ?? "Enter 10-digit number",
                                                  hintStyle: t.bodySmall?.copyWith(
                                                    color: AppColors.textFieldHintColor,
                                                    fontSize: 13.sp,
                                                  ),
                                                  border: InputBorder.none,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      VSpace(16.h),
                                      _buildFieldLabel("WhatsApp Number (For Customers)", t),
                                      VSpace(8.h),
                                      Container(
                                        height: 52.h,
                                        decoration: BoxDecoration(
                                          color: Get.isDarkMode
                                              ? AppColors.darkBgColor
                                              : AppColors.black10.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: AppThemes.getSliderInactiveColor(),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.chat_bubble_outline_rounded,
                                                    color: const Color(0xFF25D366),
                                                    size: 20.sp,
                                                  ),
                                                  HSpace(6.w),
                                                  Text(
                                                    "+91",
                                                    style: t.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              height: 28.h,
                                              color: AppThemes.getSliderInactiveColor(),
                                            ),
                                            Expanded(
                                              child: TextField(
                                                controller: profileController.whatsappEditingController,
                                                keyboardType: TextInputType.phone,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                  LengthLimitingTextInputFormatter(10),
                                                ],
                                                style: t.bodyMedium?.copyWith(fontSize: 14.sp),
                                                decoration: InputDecoration(
                                                  hintText: "10-digit WhatsApp number",
                                                  hintStyle: t.bodySmall?.copyWith(
                                                    color: AppColors.textFieldHintColor,
                                                    fontSize: 13.sp,
                                                  ),
                                                  border: InputBorder.none,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  VSpace(16.h),

                                  // ── Shop Address & Landmark Card ─────────────────────────
                                  _buildSectionCard(
                                    title: storedLanguage['Address Details'] ?? "Shop Address & Location",
                                    children: [
                                      _buildFieldLabel(
                                        storedLanguage['Address'] ?? "Shop Address (Street, Building No.)",
                                        t,
                                      ),
                                      VSpace(8.h),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Get.isDarkMode
                                              ? AppColors.darkBgColor
                                              : AppColors.black10.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: AppThemes.getSliderInactiveColor(),
                                            width: 1,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: profileController.addrEditingController,
                                          maxLines: 2,
                                          style: t.bodyMedium?.copyWith(fontSize: 14.sp),
                                          decoration: InputDecoration(
                                            hintText: storedLanguage['Enter Address'] ?? "Enter Shop Address",
                                            hintStyle: t.bodySmall?.copyWith(
                                              color: AppColors.textFieldHintColor,
                                              fontSize: 13.sp,
                                            ),
                                            prefixIcon: Padding(
                                              padding: EdgeInsets.only(bottom: 20.h),
                                              child: Icon(
                                                Icons.home_outlined,
                                                color: AppColors.mainColor,
                                                size: 20.sp,
                                              ),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12.w,
                                              vertical: 14.h,
                                            ),
                                          ),
                                        ),
                                      ),
                                      VSpace(16.h),
                                      _buildFieldLabel("Nearby Landmark", t),
                                      VSpace(8.h),
                                      _buildTextField(
                                        controller: profileController.landmarkEditingController,
                                        hint: "e.g. Near Shiv Mandir / Opp. SBI Bank",
                                        prefixIcon: Icons.near_me_outlined,
                                        t: t,
                                      ),
                                      VSpace(16.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildFieldLabel(storedLanguage['City'] ?? "City", t),
                                                VSpace(8.h),
                                                _buildTextField(
                                                  controller: profileController.cityEditingController,
                                                  hint: storedLanguage['Enter City'] ?? "City",
                                                  prefixIcon: Icons.location_city_outlined,
                                                  t: t,
                                                ),
                                              ],
                                            ),
                                          ),
                                          HSpace(12.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildFieldLabel(storedLanguage['State'] ?? "State", t),
                                                VSpace(8.h),
                                                _buildTextField(
                                                  controller: profileController.stateEditingController,
                                                  hint: storedLanguage['Enter State'] ?? "State",
                                                  prefixIcon: Icons.map_outlined,
                                                  t: t,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      VSpace(16.h),
                                      _buildFieldLabel("Postal / PIN Code", t),
                                      VSpace(8.h),
                                      _buildTextField(
                                        controller: profileController.zipCodeEditingController,
                                        hint: "6-digit PIN code",
                                        prefixIcon: Icons.pin_drop_outlined,
                                        t: t,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(6),
                                        ],
                                      ),
                                    ],
                                  ),
                                  VSpace(16.h),

                                  // ── Tax & Legal Identification (Optional) ───────────────
                                  _buildSectionCard(
                                    title: "Tax & Business Verification (Optional)",
                                    children: [
                                      _buildFieldLabel("GSTIN Number (Optional)", t),
                                      VSpace(8.h),
                                      _buildTextField(
                                        controller: profileController.gstEditingController,
                                        hint: "15-digit GSTIN (e.g. 07AAAAA0000A1Z5)",
                                        prefixIcon: Icons.receipt_long_outlined,
                                        t: t,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(15),
                                        ],
                                      ),
                                      VSpace(16.h),
                                      _buildFieldLabel("PAN Card Number (Optional)", t),
                                      VSpace(8.h),
                                      _buildTextField(
                                        controller: profileController.panEditingController,
                                        hint: "10-digit PAN (e.g. ABCDE1234F)",
                                        prefixIcon: Icons.badge_outlined,
                                        t: t,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                      ),
                                    ],
                                  ),
                                  VSpace(16.h),

                                  // ── Language Card ─────────────────────
                                  if (profileController.languageList.isNotEmpty)
                                    _buildSectionCard(
                                      title: storedLanguage['Preferences'] ?? "Preferences",
                                      children: [
                                        _buildFieldLabel(
                                          storedLanguage['Preferred Language'] ?? "Preferred Language",
                                          t,
                                        ),
                                        VSpace(8.h),
                                        Container(
                                          height: 52.h,
                                          decoration: BoxDecoration(
                                            color: Get.isDarkMode
                                                ? AppColors.darkBgColor
                                                : AppColors.black10.withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(12.r),
                                            border: Border.all(
                                              color: AppThemes.getSliderInactiveColor(),
                                              width: 1,
                                            ),
                                          ),
                                          child: AppCustomDropDown(
                                            height: 50.h,
                                            width: double.infinity,
                                            items: profileController.languageList
                                                .map((e) => e.name)
                                                .toList(),
                                            selectedValue:
                                                selectedLanguageVal ??
                                                profileController.selectedLanguage,
                                            onChanged: (value) async {
                                              selectedLanguageVal = value;
                                              Language selectedList =
                                                  await profileController.languageList
                                                      .firstWhere(
                                                        (e) => e.name.toString() == value.toString(),
                                                      );
                                              profileController.selectedLanguageId =
                                                  selectedList.id.toString();
                                              profileController.isLanguageSelected = true;
                                              profileController.update();
                                            },
                                            hint: storedLanguage['Select Language'] ?? "Select Language",
                                            selectedStyle: t.displayMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (profileController.languageList.isNotEmpty) VSpace(16.h),
                                  VSpace(8.h),

                                  // ── Update Button ─────────────────────
                                  Material(
                                    color: Colors.transparent,
                                    child: AppButton(
                                      isLoading: profileController.isUpdateProfile ? true : false,
                                      onTap: () async {
                                        try {
                                          Helpers.hideKeyboard();
                                          _syncNames(
                                            _fullNameCtrl.text,
                                            profileController,
                                          );
                                          // Set India phone code fixed
                                          profileController.phoneCode = '+91';
                                          profileController.countryCode = 'IN';
                                          profileController.countryName =
                                              'India';
                                          if (profileController
                                                  .isLanguageSelected ==
                                              true) {
                                            await appController
                                                .getLanguageListBuyId(
                                              id: profileController
                                                  .selectedLanguageId,
                                            );
                                            await profileController
                                                .validateEditProfile(context);
                                          } else {
                                            await profileController
                                                .validateEditProfile(context);
                                          }
                                        } catch (e) {
                                          Helpers.showSnackBar(msg: e.toString());
                                        }
                                      },
                                      text: storedLanguage['Update Profile'] ?? 'Update Profile',
                                    ),
                                  ),
                                  VSpace(40.h),
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

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: AppThemes.getFillColor(),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Get.isDarkMode
              ? AppColors.black70
              : AppColors.borderColor.withValues(alpha: 0.5),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.mainColor,
              letterSpacing: 0.8,
            ),
          ),
          VSpace(14.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, TextTheme t) {
    return Text(
      label,
      style: t.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12.sp,
        color: AppThemes.getBlack50Color(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    required TextTheme t,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? AppColors.darkBgColor
            : AppColors.black10.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppThemes.getSliderInactiveColor(),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: t.bodyMedium?.copyWith(fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: t.bodySmall?.copyWith(
            color: AppColors.textFieldHintColor,
            fontSize: 13.sp,
          ),
          prefixIcon: Icon(prefixIcon, color: AppColors.mainColor, size: 20.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
        ),
      ),
    );
  }

  Future<dynamic> showbottomsheet(BuildContext context, storedLanguage) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getDarkCardColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext context) {
        return GetBuilder<AppController>(
          builder: (_) {
            return GetBuilder<ProfileController>(
              builder: (profileController) {
                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: AppColors.black30,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        VSpace(16.h),
                        Text(
                          storedLanguage['Update Photo'] ?? "Update Photo",
                          style: context.t.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        VSpace(20.h),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  Get.back();
                                  profileController.pickImage(
                                    ImageSource.camera,
                                    context,
                                  );
                                },
                                child: Container(
                                  height: 80.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    color: AppColors.mainColor.withValues(alpha: 0.12),
                                    border: Border.all(
                                      color: AppColors.mainColor.withValues(alpha: 0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_rounded,
                                        size: 32.h,
                                        color: AppColors.mainColor,
                                      ),
                                      VSpace(6.h),
                                      Text(
                                        storedLanguage['Camera'] ?? 'Camera',
                                        style: context.t.bodySmall?.copyWith(
                                          color: AppColors.mainColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            HSpace(12.w),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  Get.back();
                                  profileController.pickImage(
                                    ImageSource.gallery,
                                    context,
                                  );
                                },
                                child: Container(
                                  height: 80.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    color: AppColors.mainColor.withValues(alpha: 0.12),
                                    border: Border.all(
                                      color: AppColors.mainColor.withValues(alpha: 0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.photo_library_rounded,
                                        size: 32.h,
                                        color: AppColors.mainColor,
                                      ),
                                      VSpace(6.h),
                                      Text(
                                        storedLanguage['Gallery'] ?? 'Gallery',
                                        style: context.t.bodySmall?.copyWith(
                                          color: AppColors.mainColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        VSpace(8.h),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
