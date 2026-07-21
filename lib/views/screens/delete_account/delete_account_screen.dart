import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../controllers/profile_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/spacing.dart';

class DeleteAccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextTheme t = Theme.of(context).textTheme;
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<ProfileController>(builder: (profileController) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Get.back();
          profileController.deleteEditingController.clear();
          profileController.deleteFieldColor = AppColors.sliderInActiveColor;
        },
        child: Scaffold(
          appBar: CustomAppBar(
            onBackPressed: () {
              Get.back();
              profileController.deleteEditingController.clear();
              profileController.deleteFieldColor = AppColors.sliderInActiveColor;
            },
            title: storedLanguage['Delete Account'] ?? 'Delete Account',
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: Dimensions.kDefaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 300.w,
                    height: 270.h,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            '$rootImageDir/delete_account_image.webp'),
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 15.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.redColor, width: .7),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.redColor.withValues(alpha: .8),
                          size: 28.h,
                        ),
                        HSpace(15.w),
                        Expanded(
                            child: RichText(
                                text: TextSpan(
                          children: [
                            TextSpan(
                                text: "Your account associated with",
                                style: t.bodySmall?.copyWith(
                                    height: 1.6.h,
                                    fontWeight: FontWeight.w400,
                                    color: Get.isDarkMode
                                        ? AppColors.black20
                                        : AppColors.blackColor
                                            .withValues(alpha: .9))),
                            TextSpan(
                                text: " ${HiveHelp.read(Keys.userEmail)}",
                                style: t.displayMedium?.copyWith(
                                  height: 1.6.h,
                                  fontWeight: FontWeight.w500,
                                )),
                            TextSpan(
                                text: " will be delete from both",
                                style: t.bodySmall?.copyWith(
                                    height: 1.6.h,
                                    fontWeight: FontWeight.w400,
                                    color: Get.isDarkMode
                                        ? AppColors.black20
                                        : AppColors.blackColor
                                            .withValues(alpha: .9))),
                            TextSpan(
                                text: " ${AppConstants.appName} App",
                                style: t.displayMedium?.copyWith(
                                  height: 1.6.h,
                                  fontWeight: FontWeight.w500,
                                )),
                            TextSpan(
                                text: " and",
                                style: t.bodySmall?.copyWith(
                                    height: 2.h,
                                    fontWeight: FontWeight.w400,
                                    color: Get.isDarkMode
                                        ? AppColors.black20
                                        : AppColors.blackColor
                                            .withValues(alpha: .9))),
                            TextSpan(
                                text: " Website.",
                                style: t.displayMedium?.copyWith(
                                  height: 1.6.h,
                                  fontWeight: FontWeight.w500,
                                )),
                          ],
                        ))),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Are you sure you want to delete your account?',
                    style: t.displayMedium?.copyWith(
                        color: AppColors.redColor.withValues(alpha: .8)),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Deleting your account will remove all your data permanently and this action cannot be undone.',
                    style: t.displayMedium
                        ?.copyWith(color: AppThemes.getParagraphColor()),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "To confirm this, enter your security pin",
                      style: t.bodySmall
                          ?.copyWith(color: AppThemes.getParagraphColor()),
                    ),
                  ),
                  VSpace(8.h),
                  Row(
                    children: [
                      Expanded(
                          flex: 5,
                          child: SizedBox(
                            height: 40.h,
                            child: CustomTextField(
                                borderRadius: BorderRadius.circular(8.r),
                                bgColor: Colors.transparent,
                                isBorderColor: true,
                                borderWidth: 1,
                                borderColor: profileController.deleteFieldColor ==
                                        AppColors.sliderInActiveColor
                                    ? Get.isDarkMode
                                        ? AppColors.black80
                                        : AppColors.sliderInActiveColor
                                    : profileController.deleteFieldColor,
                                hintext: "",
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                controller: profileController.deleteEditingController),
                          )),
                      HSpace(20.w),
                      Expanded(
                        flex: 4,
                        child: AppButton(
                          borderRadius: BorderRadius.circular(8.r),
                          isLoading: profileController.isDeleteAccount,
                          buttonHeight: 40.h,
                          text: 'Delete Account',
                          style: t.displayMedium
                              ?.copyWith(color: AppColors.whiteColor),
                          bgColor: AppColors.redColor.withValues(alpha: .8),
                          onTap: profileController.isDeleteAccount
                              ? null
                              : () async {
                                  if (profileController.deleteEditingController.text.isEmpty) {
                                    profileController.deleteFieldColor = AppColors.redColor
                                        .withValues(alpha: .8);

                                    profileController.update();
                                    Helpers.showSnackBar(
                                        msg: "Delete field is required.");
                                  } else if (profileController.deleteEditingController.text
                                      .isNotEmpty) {
                                    Helpers.hideKeyboard();
                                    if (HiveHelp.read(Keys.userId) == "3") {
                                      Helpers.showSnackBar(
                                          msg:
                                              "You are currently using a demo version. Feature exploration is enabled, but deletion is restricted.");
                                    } else {
                                      await profileController.deleteAccount(
                                          code:
                                              '${profileController.deleteEditingController.text}');
                                    }
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

void main() {
  runApp(MaterialApp(
    home: DeleteAccountScreen(),
  ));
}
