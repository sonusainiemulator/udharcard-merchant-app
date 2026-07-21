import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_code_picker/country_code_picker.dart';
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
import '../../widgets/custom_textfield.dart';
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
                  child: Padding(
                    padding: Dimensions.kDefaultPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: Dimensions.screenHeight * .05),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              if (Get.find<ProfileController>().userPhoto !=
                                  '') {
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
                                  color:
                                      Get.isDarkMode
                                          ? AppColors.darkCardColor
                                          : AppColors.mainColor,
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
                                            Get.find<ProfileController>()
                                                .userPhoto,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                              ),
                              alignment: Alignment.bottomRight,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    bottom: -9.h,
                                    right: -8.w,
                                    child: InkResponse(
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
                                        ),
                                        child: Icon(
                                          Icons.camera_alt_outlined,
                                          color: AppColors.blackColor,
                                          size: 20.h,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        profileController.isLoading
                            ? Helpers.appLoader()
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VSpace(40.h),
                                Text(
                                  storedLanguage['First Name'] ?? "First Name",
                                  style: t.displayMedium,
                                ),
                                VSpace(10.h),
                                CustomTextField(
                                  isBorderColor: true,
                                  hintext:
                                      storedLanguage['Enter First Name'] ??
                                      "Enter First Name",
                                  controller:
                                      profileController.fNameEditingController,
                                  contentPadding: EdgeInsets.only(left: 20.w),
                                ),
                                VSpace(24.h),
                                Text(
                                  storedLanguage['Last Name'] ?? "Last Name",
                                  style: t.displayMedium,
                                ),
                                VSpace(10.h),
                                CustomTextField(
                                  isBorderColor: true,
                                  hintext:
                                      storedLanguage['Enter Last Name'] ??
                                      "Enter Last Name",
                                  controller:
                                      profileController.lNameEditingController,
                                  contentPadding: EdgeInsets.only(left: 20.w),
                                ),
                                VSpace(24.h),
                                Text(
                                  storedLanguage['Username'] ?? "Username",
                                  style: t.displayMedium,
                                ),
                                VSpace(10.h),
                                CustomTextField(
                                  isBorderColor: true,
                                  hintext:
                                      storedLanguage['Username'] ?? "Username",
                                  controller:
                                      profileController
                                          .userNameEditingController,
                                  contentPadding: EdgeInsets.only(left: 20.w),
                                ),
                                VSpace(24.h),
                                Text(
                                  storedLanguage['Phone Number'] ??
                                      "Phone Number",
                                  style: t.displayMedium,
                                ),
                                VSpace(10.h),
                                Row(
                                  children: [
                                    Container(
                                      height: Dimensions.textFieldHeight,
                                      decoration: BoxDecoration(
                                        borderRadius: Dimensions.kBorderRadius,
                                        border: Border.all(
                                          color:
                                              AppThemes.getSliderInactiveColor(),
                                          width: 1,
                                        ),
                                      ),
                                      child: CountryCodePicker(
                                        padding: EdgeInsets.zero,
                                        dialogBackgroundColor:
                                            AppThemes.getDarkCardColor(),
                                        dialogTextStyle: t.bodyMedium?.copyWith(
                                          fontSize: 16.sp,
                                        ),
                                        flagWidth: 29.w,
                                        textStyle: t.displayMedium,
                                        onChanged: (CountryCode countryCode) {
                                          profileController.countryCode =
                                              countryCode.code!;
                                          profileController.phoneCode =
                                              countryCode.dialCode!;
                                          profileController.countryName =
                                              countryCode.name!;
                                        },
                                        initialSelection:
                                            '${profileController.countryCode}',
                                        showCountryOnly: false,
                                        showOnlyCountryWhenClosed: false,
                                        alignLeft: false,
                                      ),
                                    ),
                                    HSpace(16.w),
                                    Expanded(
                                      child: CustomTextField(
                                        isBorderColor: true,
                                        hintext:
                                            storedLanguage['Enter Number'] ??
                                            "Enter Number",
                                        controller:
                                            profileController
                                                .phoneNumberEditingController,
                                        contentPadding: EdgeInsets.only(
                                          left: 20.w,
                                        ),
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                VSpace(24.h),
                                if (profileController.languageList.isNotEmpty)
                                  Text(
                                    storedLanguage['Preferred Language'] ??
                                        "Preferred Language",
                                    style: t.displayMedium,
                                  ),
                                if (profileController.languageList.isNotEmpty)
                                  VSpace(10.h),
                                if (profileController.languageList.isNotEmpty)
                                  Container(
                                    height: 50.h,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            AppThemes.getSliderInactiveColor(),
                                      ),
                                      borderRadius: Dimensions.kBorderRadius,
                                    ),
                                    child: AppCustomDropDown(
                                      height: 46.h,
                                      width: double.infinity,
                                      items:
                                          profileController.languageList
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
                                                  (e) =>
                                                      e.name.toString() ==
                                                      value.toString(),
                                                );
                                        profileController.selectedLanguageId =
                                            selectedList.id.toString();
                                        profileController.isLanguageSelected =
                                            true;
                                        profileController.update();
                                      },
                                      hint:
                                          storedLanguage['Select Language'] ??
                                          "Select Language",
                                      selectedStyle: t.displayMedium,
                                    ),
                                  ),
                                VSpace(24.h),
                                Text(
                                  storedLanguage['City'] ?? "City",
                                  style: t.displayMedium,
                                ),
                                VSpace(10.h),
                                CustomTextField(
                                  isBorderColor: true,
                                  hintext:
                                      storedLanguage['Enter City'] ??
                                      "Enter City",
                                  controller:
                                      profileController.cityEditingController,
                                  contentPadding: EdgeInsets.only(left: 20.w),
                                ),
                                VSpace(24.h),
                                Text(
                                  storedLanguage['State'] ?? "State",
                                  style: t.displayMedium,
                                ),
                                VSpace(10.h),
                                CustomTextField(
                                  isBorderColor: true,
                                  hintext:
                                      storedLanguage['Enter State'] ??
                                      "Enter State",
                                  controller:
                                      profileController.stateEditingController,
                                  contentPadding: EdgeInsets.only(left: 20.w),
                                ),
                                VSpace(24.h),
                                Text(
                                  storedLanguage['Address'] ?? "Address",
                                  style: t.displayMedium,
                                ),
                                VSpace(10.h),
                                CustomTextField(
                                  contentPadding: EdgeInsets.only(
                                    left: 20.w,
                                    bottom: 0.h,
                                    top: 10.h,
                                  ),
                                  alignment: Alignment.topLeft,
                                  isBorderColor: true,
                                  isPrefixIcon: false,
                                  controller:
                                      profileController.addrEditingController,
                                  hintext:
                                      storedLanguage['Enter Address'] ??
                                      "Enter Address",
                                ),
                                VSpace(24.h),
                                Material(
                                  color: Colors.transparent,
                                  child: AppButton(
                                    isLoading:
                                        profileController.isUpdateProfile
                                            ? true
                                            : false,
                                    onTap: () async {
                                      try {
                                        Helpers.hideKeyboard();
                                        if (profileController
                                                .isLanguageSelected ==
                                            true) {
                                          await appController
                                              .getLanguageListBuyId(
                                                id:
                                                    profileController
                                                        .selectedLanguageId,
                                              );
                                          await profileController
                                              .validateEditProfile(context);
                                        } else if (profileController
                                                .isLanguageSelected ==
                                            false) {
                                          await profileController
                                              .validateEditProfile(context);
                                        }
                                      } catch (e) {
                                        Helpers.showSnackBar(msg: e.toString());
                                      }
                                    },
                                    text:
                                        storedLanguage['Update Profile'] ??
                                        'Update Profile',
                                  ),
                                ),
                                VSpace(65.h),
                              ],
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<dynamic> showbottomsheet(BuildContext context, storedLanguage) {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return GetBuilder<AppController>(
          builder: (_) {
            return GetBuilder<ProfileController>(
              builder: (profileController) {
                return SizedBox(
                  height: context.mQuery.height * 0.2,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 10.h),
                      GestureDetector(
                        onTap: () async {
                          Get.back();
                          profileController.pickImage(
                            ImageSource.camera,
                            context,
                          );
                        },
                        child: Container(
                          height: 80.h,
                          width: 150.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppThemes.getDarkBgColor(),
                            border: Border.all(
                              color: AppColors.mainColor,
                              width: .2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 35.h,
                                color:
                                    Get.isDarkMode
                                        ? AppColors.whiteColor
                                        : AppColors.black50,
                              ),
                              Text(
                                storedLanguage['Pick from Camera'] ??
                                    'Pick from Camera',
                                style: context.t.bodySmall?.copyWith(
                                  color: AppThemes.getIconBlackColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: () async {
                          Get.back();
                          profileController.pickImage(
                            ImageSource.gallery,
                            context,
                          );
                        },
                        child: Container(
                          height: 80.h,
                          width: 150.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppThemes.getDarkBgColor(),
                            border: Border.all(
                              color: AppColors.mainColor,
                              width: .2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera,
                                size: 35.h,
                                color:
                                    Get.isDarkMode
                                        ? AppColors.whiteColor
                                        : AppColors.black50,
                              ),
                              Text(
                                storedLanguage['Pick from Gallery'] ??
                                    'Pick from Gallery',
                                style: context.t.bodySmall?.copyWith(
                                  color: AppThemes.getIconBlackColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
