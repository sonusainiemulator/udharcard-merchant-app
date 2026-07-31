import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:paysecure/views/widgets/mediaquery_extension.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
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

// ignore: must_be_immutable
class EditProfileScreen extends StatelessWidget {
  EditProfileScreen({super.key});

  var selectedLanguageVal;

  @override
  Widget build(BuildContext context) {
    TextTheme t = Theme.of(context).textTheme;
    Get.find<ProfileController>().isLanguageSelected = false;
    return GetBuilder<ProfileController>(
      builder: (profileController) {
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
                                        image: profileController.isLoading ||
                                                profileController.userPhoto == ''
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
                                  // ── Name Card ─────────────────────────
                                  _buildSectionCard(
                                    title: "Personal Info",
                                    children: [
                                      // First Name
                                      _buildFieldLabel(
                                        storedLanguage['First Name'] ?? "First Name",
                                        t,
                                      ),
                                      VSpace(8.h),
                                      _buildTextField(
                                        controller: profileController.fNameEditingController,
                                        hint: storedLanguage['Enter First Name'] ?? "Enter First Name",
                                        prefixIcon: Icons.person_outline_rounded,
                                        t: t,
                                      ),
                                      VSpace(16.h),
                                      // Last Name
                                      _buildFieldLabel(
                                        storedLanguage['Last Name'] ?? "Last Name",
                                        t,
                                      ),
                                      VSpace(8.h),
                                      _buildTextField(
                                        controller: profileController.lNameEditingController,
                                        hint: storedLanguage['Enter Last Name'] ?? "Enter Last Name",
                                        prefixIcon: Icons.person_outline_rounded,
                                        t: t,
                                      ),
                                    ],
                                  ),
                                  VSpace(16.h),

                                  // ── Phone Card ────────────────────────
                                  _buildSectionCard(
                                    title: storedLanguage['Contact'] ?? "Contact",
                                    children: [
                                      _buildFieldLabel(
                                        storedLanguage['Phone Number'] ?? "Phone Number",
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
                                            // India fixed prefix
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

                                  // ── Address Card ──────────────────────
                                  _buildSectionCard(
                                    title: storedLanguage['Address Details'] ?? "Address Details",
                                    children: [
                                      _buildFieldLabel(
                                        storedLanguage['City'] ?? "City",
                                        t,
                                      ),
                                      VSpace(8.h),
                                      _buildTextField(
                                        controller: profileController.cityEditingController,
                                        hint: storedLanguage['Enter City'] ?? "Enter City",
                                        prefixIcon: Icons.location_city_outlined,
                                        t: t,
                                      ),
                                      VSpace(16.h),
                                      _buildFieldLabel(
                                        storedLanguage['State'] ?? "State",
                                        t,
                                      ),
                                      VSpace(8.h),
                                      _buildTextField(
                                        controller: profileController.stateEditingController,
                                        hint: storedLanguage['Enter State'] ?? "Enter State",
                                        prefixIcon: Icons.map_outlined,
                                        t: t,
                                      ),
                                      VSpace(16.h),
                                      _buildFieldLabel(
                                        storedLanguage['Address'] ?? "Address",
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
                                          maxLines: 3,
                                          style: t.bodyMedium?.copyWith(fontSize: 14.sp),
                                          decoration: InputDecoration(
                                            hintText: storedLanguage['Enter Address'] ?? "Enter Address",
                                            hintStyle: t.bodySmall?.copyWith(
                                              color: AppColors.textFieldHintColor,
                                              fontSize: 13.sp,
                                            ),
                                            prefixIcon: Padding(
                                              padding: EdgeInsets.only(bottom: 44.h),
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
                                    ],
                                  ),
                                  VSpace(24.h),

                                  // ── Update Button ─────────────────────
                                  Material(
                                    color: Colors.transparent,
                                    child: AppButton(
                                      isLoading: profileController.isUpdateProfile ? true : false,
                                      onTap: () async {
                                        try {
                                          Helpers.hideKeyboard();
                                          // Set India phone code fixed
                                          profileController.phoneCode = '+91';
                                          profileController.countryCode = 'IN';
                                          profileController.countryName = 'India';
                                          if (profileController.isLanguageSelected == true) {
                                            await appController.getLanguageListBuyId(
                                              id: profileController.selectedLanguageId,
                                            );
                                            await profileController.validateEditProfile(context);
                                          } else {
                                            await profileController.validateEditProfile(context);
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
