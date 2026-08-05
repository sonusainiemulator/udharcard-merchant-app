import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:paysecure/config/dimensions.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/views/widgets/app_button.dart';
import 'package:paysecure/views/widgets/custom_appbar.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../../config/app_colors.dart';
import '../../../../themes/themes.dart';
import '../../../../utils/services/localstorage/hive.dart';
import '../../../../utils/services/localstorage/keys.dart';
import '../../../controllers/merchant_setting_controller.dart';
import '../../../routes/routes_name.dart';
import '../../widgets/app_custom_dropdown.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/spacing.dart';

import 'package:package_info_plus/package_info_plus.dart';

class MerchantSettingScreen extends StatelessWidget {
  final bool? isFromDrawerSection;
  const MerchantSettingScreen({super.key, this.isFromDrawerSection = false});

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<MerchantSettingController>(
      builder: (merchantSettingController) {
        return Scaffold(
          appBar: CustomAppBar(
            title: storedLanguage['Merchant Setting'] ?? "Merchant Setting",
          ),
          body: RefreshIndicator(
            color: AppColors.mainColor,
            onRefresh: () async {
              await merchantSettingController.getMerchantSetting();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: Dimensions.kDefaultPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VSpace(40.h),
                    InkWell(
                      onTap: () => Get.toNamed(RoutesName.udharReportsScreen),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Get.isDarkMode ? const Color(0xFF121A2A) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Get.isDarkMode ? const Color(0xFF23304A) : const Color(0xFFBFDBFE),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: AppColors.mainColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(Icons.analytics_rounded, color: AppColors.mainColor, size: 22.sp),
                            ),
                            HSpace(12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reports Dashboard',
                                    style: context.t.displayMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  VSpace(4.h),
                                  Text(
                                    'Open PDF ledger statements and CSV outstanding exports.',
                                    style: context.t.bodySmall?.copyWith(
                                      color: AppColors.black60,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.mainColor),
                          ],
                        ),
                      ),
                    ),
                    VSpace(16.h),
                    // App Information & Version Display Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Get.isDarkMode ? const Color(0xFF121A2A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Get.isDarkMode ? const Color(0xFF23304A) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: AppColors.mainColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(Icons.info_outline_rounded, color: AppColors.mainColor, size: 22.sp),
                          ),
                          HSpace(12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  storedLanguage['App Version'] ?? 'App Version',
                                  style: context.t.displayMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                VSpace(4.h),
                                Text(
                                  'UdharCard Merchant App',
                                  style: context.t.bodySmall?.copyWith(
                                    color: AppColors.black60,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (context, snapshot) {
                              final version = snapshot.data?.version ?? '1.0.47';
                              final buildNumber = snapshot.data?.buildNumber ?? '';
                              final versionStr = buildNumber.isNotEmpty ? 'v$version ($buildNumber)' : 'v$version';
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: AppColors.mainColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  versionStr,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.mainColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    VSpace(24.h),
                    Text(
                      storedLanguage['Charge Applied To'] ??
                          "Charge Applied To",
                      style: context.t.displayMedium,
                    ),
                    VSpace(10.h),
                    Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        borderRadius: Dimensions.kBorderRadius,
                        border: Border.all(
                          color: AppThemes.getSliderInactiveColor(),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppCustomDropDown(
                              paddingLeft: 20.w,
                              height: 50.h,
                              width: double.infinity,
                              items: ['Myself', 'Sender'],
                              selectedValue:
                                  merchantSettingController.chargeApplyTo,
                              onChanged: (v) {
                                merchantSettingController.chargeApplyTo = v;
                                merchantSettingController.update();
                              },
                              hint:
                                  storedLanguage['Charge Applied To'] ??
                                  "Charge Applied To",
                              hintStyle: context.t.bodySmall?.copyWith(
                                color: AppColors.textFieldHintColor,
                                fontWeight: FontWeight.w400,
                                fontSize: 18.sp,
                              ),
                              selectedStyle: context.t.displayMedium,
                              bgColor: AppThemes.getFillColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    VSpace(24.h),
                    Text(
                      storedLanguage['Auto Settlement'] ?? "Auto Settlement",
                      style: context.t.displayMedium,
                    ),
                    VSpace(10.h),
                    Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        borderRadius: Dimensions.kBorderRadius,
                        border: Border.all(
                          color: AppThemes.getSliderInactiveColor(),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppCustomDropDown(
                              paddingLeft: 20.w,
                              height: 50.h,
                              width: double.infinity,
                              items: ['On', 'Off'],
                              selectedValue:
                                  merchantSettingController.autoWithdraw,
                              onChanged: (v) {
                                merchantSettingController.autoWithdraw = v;
                                merchantSettingController.update();
                              },
                              hint:
                                  storedLanguage['Auto Settlement'] ??
                                  "Auto Settlement",
                              hintStyle: context.t.bodySmall?.copyWith(
                                color: AppColors.textFieldHintColor,
                                fontWeight: FontWeight.w400,
                                fontSize: 18.sp,
                              ),
                              selectedStyle: context.t.displayMedium,
                              bgColor: AppThemes.getFillColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    VSpace(24.h),
                    Text(
                      storedLanguage['Settlement Frequency'] ??
                          "Settlement Frequency",
                      style: context.t.displayMedium,
                    ),
                    VSpace(10.h),
                    Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        borderRadius: Dimensions.kBorderRadius,
                        border: Border.all(
                          color: AppThemes.getSliderInactiveColor(),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppCustomDropDown(
                              paddingLeft: 20.w,
                              height: 50.h,
                              width: double.infinity,
                              items: ['Weekly', 'Monthly'],
                              selectedValue:
                                  merchantSettingController.withdrawFrequency,
                              onChanged: (v) {
                                merchantSettingController.withdrawFrequency = v;
                                merchantSettingController.update();
                              },
                              hint:
                                  storedLanguage['Settlement Frequency'] ??
                                  "Settlement Frequency",
                              hintStyle: context.t.bodySmall?.copyWith(
                                color: AppColors.textFieldHintColor,
                                fontWeight: FontWeight.w400,
                                fontSize: 18.sp,
                              ),
                              selectedStyle: context.t.displayMedium,
                              bgColor: AppThemes.getFillColor(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    VSpace(24.h),
                    Text(
                      storedLanguage['Settlement Amount (Select the currency)'] ??
                          'Settlement Amount (Select the currency)',
                      style: context.t.displayMedium,
                    ),
                    VSpace(10.h),
                    Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        borderRadius: Dimensions.kBorderRadius,
                        border: Border.all(
                          color: AppThemes.getSliderInactiveColor(),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              isBorderColor: false,
                              isSuffixIcon: false,
                              contentPadding: EdgeInsets.only(left: 20.w),
                              hintext:
                                  storedLanguage['Settlement Amount (Select the currency)'] ??
                                  'Settlement Amount (Select the currency)',
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              controller:
                                  merchantSettingController.amountController,
                              onChanged: (v) async {},
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: AppThemes.getSliderInactiveColor(),
                                  width: 1,
                                ),
                              ),
                            ),
                            width: 180.w,
                            child: Row(
                              children: [
                                Expanded(
                                  child: AppCustomDropDown(
                                    paddingLeft: 20.w,
                                    height: 50.h,
                                    width: double.infinity,
                                    items:
                                        merchantSettingController.currencyList,
                                    selectedValue:
                                        merchantSettingController
                                            .selectedCurrency,
                                    onChanged: (v) {
                                      merchantSettingController
                                          .selectedCurrency = v;
                                      merchantSettingController.update();
                                    },
                                    hint:
                                        storedLanguage['Currency'] ??
                                        "Currency",
                                    hintStyle: context.t.bodySmall?.copyWith(
                                      color: AppColors.textFieldHintColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 18.sp,
                                    ),
                                    selectedStyle: context.t.displayMedium,
                                    bgColor: AppThemes.getFillColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    VSpace(24.h),
                    Text(
                      storedLanguage['Last Auto Settlement At'] ??
                          'Last Auto Settlement At',
                      style: context.t.displayMedium,
                    ),
                    VSpace(10.h),
                    IgnorePointer(
                      ignoring: true,
                      child: CustomTextField(
                        isBorderColor: true,
                        isSuffixIcon: false,
                        contentPadding: EdgeInsets.only(left: 20.w),
                        hintext:
                          storedLanguage['Last Auto Settlement At'] ??
                          'Last Auto Settlement At',
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        controller: merchantSettingController.withdrawAt,
                        onChanged: (v) async {},
                      ),
                    ),
                    VSpace(30.h),
                    if (merchantSettingController
                        .withdrawInformationList
                        .isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: AppThemes.getFillColor(),
                          borderRadius: Dimensions.kBorderRadius,
                        ),
                        child: Column(
                          children: [
                            VSpace(20.h),
                            Text(
                              "Auto Settlement Information",
                              style: context.t.bodyMedium,
                            ),

                            Divider(
                              color:
                                  Get.isDarkMode
                                      ? AppColors.darkCardColorDeep
                                      : AppColors.black10,
                            ),

                            Padding(
                              padding: EdgeInsets.only(
                                left: 16.w,
                                right: 16.w,
                                bottom: 20.h,
                                top: 10.h,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount:
                                    merchantSettingController
                                        .withdrawInformationList
                                        .length,
                                itemBuilder: (context, index) {
                                  final dynamicField =
                                      merchantSettingController
                                          .withdrawInformationList[index];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (dynamicField.type == "file")
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  merchantSettingController
                                                      .toCapital(
                                                        dynamicField.fieldName,
                                                      ),

                                                  style:
                                                      context.t.displayMedium,
                                                ),
                                                dynamicField.validation ==
                                                        'required'
                                                    ? const SizedBox()
                                                    : Text(
                                                      " (Optional)",
                                                      style:
                                                          context
                                                              .t
                                                              .displayMedium,
                                                    ),
                                              ],
                                            ),
                                            SizedBox(height: 8.h),
                                            Container(
                                              height: 50.h,
                                              width: double.maxFinite,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8.w,
                                                vertical: 10.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    Get.isDarkMode
                                                        ? AppColors
                                                            .darkCardColorDeep
                                                        : AppColors.whiteColor,
                                                borderRadius:
                                                    Dimensions.kBorderRadius,
                                                border: Border.all(
                                                  color:
                                                      AppThemes.getSliderInactiveColor(),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  HSpace(12.w),
                                                  Text(
                                                    merchantSettingController
                                                                .imagePickerResults[dynamicField
                                                                .fieldName] !=
                                                            null
                                                        ? "1 File selected"
                                                        : "No File selected",
                                                    style: context.t.bodySmall?.copyWith(
                                                      color:
                                                          merchantSettingController
                                                                      .imagePickerResults[dynamicField
                                                                      .fieldName] !=
                                                                  null
                                                              ? AppColors
                                                                  .greenColor
                                                              : AppColors
                                                                  .black60,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        Helpers.hideKeyboard();

                                                        await merchantSettingController
                                                            .pickFile(
                                                              dynamicField
                                                                  .fieldName,
                                                            );
                                                      },
                                                      borderRadius:
                                                          Dimensions
                                                              .kBorderRadius,
                                                      child: Ink(
                                                        width: 113.w,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              AppColors
                                                                  .mainColor,
                                                          borderRadius:
                                                              Dimensions
                                                                  .kBorderRadius /
                                                              2,
                                                          border: Border.all(
                                                            color:
                                                                AppColors
                                                                    .mainColor,
                                                            width: .2,
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            'Choose File',
                                                            style: context
                                                                .t
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color:
                                                                      AppColors
                                                                          .blackColor,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 16.h),
                                          ],
                                        ),
                                      if (dynamicField.type == "text")
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  merchantSettingController
                                                      .toCapital(
                                                        dynamicField.fieldName,
                                                      ),
                                                  style:
                                                      context.t.displayMedium,
                                                ),
                                                dynamicField.validation ==
                                                        'required'
                                                    ? const SizedBox()
                                                    : Text(
                                                      " (Optional)",
                                                      style:
                                                          context
                                                              .t
                                                              .displayMedium,
                                                    ),
                                              ],
                                            ),
                                            SizedBox(height: 8.h),
                                            TextFormField(
                                              validator: (value) {
                                                // Perform validation based on the 'validation' property
                                                if (dynamicField.validation ==
                                                        "required" &&
                                                    value!.isEmpty) {
                                                  return "Field is required";
                                                }
                                                return null;
                                              },
                                              onChanged: (v) {
                                                merchantSettingController
                                                    .textEditingControllerMap[dynamicField
                                                        .fieldName]!
                                                    .text = v;
                                              },
                                              controller:
                                                  merchantSettingController
                                                      .textEditingControllerMap[dynamicField
                                                      .fieldName],
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 16,
                                                    ),
                                                filled:
                                                    true, // Fill the background with color
                                                hintStyle: TextStyle(
                                                  color:
                                                      AppColors
                                                          .textFieldHintColor,
                                                ),
                                                fillColor:
                                                    Get.isDarkMode
                                                        ? AppColors
                                                            .darkCardColorDeep
                                                        : AppColors.whiteColor,
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color:
                                                        AppThemes.getSliderInactiveColor(),
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      Dimensions.kBorderRadius,
                                                ),

                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          Dimensions
                                                              .kBorderRadius,
                                                      borderSide: BorderSide(
                                                        color:
                                                            AppColors.mainColor,
                                                      ),
                                                    ),
                                              ),
                                              style: context.t.displayMedium,
                                            ),
                                            SizedBox(height: 16.h),
                                          ],
                                        ),
                                      if (dynamicField.type == "number")
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  merchantSettingController
                                                      .toCapital(
                                                        dynamicField.fieldName,
                                                      ),
                                                  style:
                                                      context.t.displayMedium,
                                                ),
                                                dynamicField.validation ==
                                                        'required'
                                                    ? const SizedBox()
                                                    : Text(
                                                      " ${storedLanguage['(Optional)'] ?? "(Optional)"}",
                                                      style:
                                                          context
                                                              .t
                                                              .displayMedium,
                                                    ),
                                              ],
                                            ),
                                            SizedBox(height: 8.h),
                                            TextFormField(
                                              validator: (value) {
                                                // Perform validation based on the 'validation' property
                                                if (dynamicField.validation ==
                                                        "required" &&
                                                    value!.isEmpty) {
                                                  return storedLanguage['Field is required'] ??
                                                      "Field is required";
                                                }
                                                return null;
                                              },
                                              onChanged: (v) {
                                                merchantSettingController
                                                    .textEditingControllerMap[dynamicField
                                                        .fieldName]!
                                                    .text = v;
                                              },
                                              controller:
                                                  merchantSettingController
                                                      .textEditingControllerMap[dynamicField
                                                      .fieldName],
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters:
                                                  <TextInputFormatter>[
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 16,
                                                    ),
                                                filled:
                                                    true, // Fill the background with color
                                                hintStyle: TextStyle(
                                                  color:
                                                      AppColors
                                                          .textFieldHintColor,
                                                ),
                                                fillColor:
                                                    Get.isDarkMode
                                                        ? AppColors
                                                            .darkCardColorDeep
                                                        : AppColors.whiteColor,
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color:
                                                        AppThemes.getSliderInactiveColor(),
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      Dimensions.kBorderRadius,
                                                ),

                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          Dimensions
                                                              .kBorderRadius,
                                                      borderSide: BorderSide(
                                                        color:
                                                            AppColors.mainColor,
                                                      ),
                                                    ),
                                              ),
                                              style: context.t.displayMedium,
                                            ),
                                            SizedBox(height: 16.h),
                                          ],
                                        ),
                                      if (dynamicField.type == "url")
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  merchantSettingController
                                                      .toCapital(
                                                        dynamicField.fieldName,
                                                      ),
                                                  style:
                                                      context.t.displayMedium,
                                                ),
                                                dynamicField.validation ==
                                                        'required'
                                                    ? const SizedBox()
                                                    : Text(
                                                      " ${storedLanguage['(Optional)'] ?? "(Optional)"}",
                                                      style:
                                                          context
                                                              .t
                                                              .displayMedium,
                                                    ),
                                              ],
                                            ),
                                            SizedBox(height: 8.h),
                                            TextFormField(
                                              validator: (value) {
                                                // Perform validation based on the 'validation' property
                                                if (dynamicField.validation ==
                                                        "required" &&
                                                    value!.isEmpty) {
                                                  return storedLanguage['Field is required'] ??
                                                      "Field is required";
                                                }
                                                return null;
                                              },
                                              onChanged: (v) {
                                                merchantSettingController
                                                    .textEditingControllerMap[dynamicField
                                                        .fieldName]!
                                                    .text = v;
                                              },
                                              controller:
                                                  merchantSettingController
                                                      .textEditingControllerMap[dynamicField
                                                      .fieldName],
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters:
                                                  <TextInputFormatter>[
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 16,
                                                    ),
                                                filled:
                                                    true, // Fill the background with color
                                                hintStyle: TextStyle(
                                                  color:
                                                      AppColors
                                                          .textFieldHintColor,
                                                ),
                                                fillColor:
                                                    Get.isDarkMode
                                                        ? AppColors
                                                            .darkCardColorDeep
                                                        : AppColors.whiteColor,
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color:
                                                        AppThemes.getSliderInactiveColor(),
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      Dimensions.kBorderRadius,
                                                ),

                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          Dimensions
                                                              .kBorderRadius,
                                                      borderSide: BorderSide(
                                                        color:
                                                            AppColors.mainColor,
                                                      ),
                                                    ),
                                              ),
                                              style: context.t.displayMedium,
                                            ),
                                            SizedBox(height: 16.h),
                                          ],
                                        ),
                                      if (dynamicField.type == "email")
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  merchantSettingController
                                                      .toCapital(
                                                        dynamicField.fieldName,
                                                      ),
                                                  style:
                                                      context.t.displayMedium,
                                                ),
                                                dynamicField.validation ==
                                                        'required'
                                                    ? const SizedBox()
                                                    : Text(
                                                      " ${storedLanguage['(Optional)'] ?? "(Optional)"}",
                                                      style:
                                                          context
                                                              .t
                                                              .displayMedium,
                                                    ),
                                              ],
                                            ),
                                            SizedBox(height: 8.h),
                                            TextFormField(
                                              validator: (value) {
                                                // Perform validation based on the 'validation' property
                                                if (dynamicField.validation ==
                                                        "required" &&
                                                    value!.isEmpty) {
                                                  return storedLanguage['Field is required'] ??
                                                      "Field is required";
                                                }
                                                return null;
                                              },
                                              onChanged: (v) {
                                                merchantSettingController
                                                    .textEditingControllerMap[dynamicField
                                                        .fieldName]!
                                                    .text = v;
                                              },
                                              controller:
                                                  merchantSettingController
                                                      .textEditingControllerMap[dynamicField
                                                      .fieldName],
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters:
                                                  <TextInputFormatter>[
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 16,
                                                    ),
                                                filled:
                                                    true, // Fill the background with color
                                                hintStyle: TextStyle(
                                                  color:
                                                      AppColors
                                                          .textFieldHintColor,
                                                ),
                                                fillColor:
                                                    Get.isDarkMode
                                                        ? AppColors
                                                            .darkCardColorDeep
                                                        : AppColors.whiteColor,
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color:
                                                        AppThemes.getSliderInactiveColor(),
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      Dimensions.kBorderRadius,
                                                ),

                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          Dimensions
                                                              .kBorderRadius,
                                                      borderSide: BorderSide(
                                                        color:
                                                            AppColors.mainColor,
                                                      ),
                                                    ),
                                              ),
                                              style: context.t.displayMedium,
                                            ),
                                            SizedBox(height: 16.h),
                                          ],
                                        ),
                                      if (dynamicField.type == "date")
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  merchantSettingController
                                                      .toCapital(
                                                        dynamicField.fieldName,
                                                      ),
                                                  style:
                                                      context.t.displayMedium,
                                                ),
                                                dynamicField.validation ==
                                                        'required'
                                                    ? const SizedBox()
                                                    : Text(
                                                      " ${storedLanguage['(Optional)'] ?? "(Optional)"}",
                                                      style:
                                                          context
                                                              .t
                                                              .displayMedium,
                                                    ),
                                              ],
                                            ),
                                            SizedBox(height: 8.h),
                                            InkWell(
                                              onTap: () async {
                                                /// SHOW DATE PICKER
                                                await showDatePicker(
                                                  context: context,
                                                  builder: (context, child) {
                                                    return Theme(
                                                      data: Theme.of(
                                                        context,
                                                      ).copyWith(
                                                        colorScheme: ColorScheme.dark(
                                                          surface:
                                                              Get.isDarkMode
                                                                  ? AppColors
                                                                      .darkCardColor
                                                                  : AppColors
                                                                      .paragraphColor,
                                                          onPrimary:
                                                              AppColors
                                                                  .whiteColor,
                                                        ),
                                                        textButtonTheme:
                                                            TextButtonThemeData(
                                                              style: TextButton.styleFrom(
                                                                foregroundColor:
                                                                    AppColors
                                                                        .mainColor, // button text color
                                                              ),
                                                            ),
                                                      ),
                                                      child: child!,
                                                    );
                                                  },
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime(1900),
                                                  lastDate: DateTime(
                                                    DateTime.now().year
                                                            .toInt() +
                                                        1,
                                                  ),
                                                ).then((value) {
                                                  if (value != null) {
                                                    merchantSettingController
                                                        .textEditingControllerMap[dynamicField
                                                            .fieldName]!
                                                        .text = DateFormat(
                                                      'yyyy-MM-dd',
                                                    ).format(value);
                                                  }
                                                });
                                              },
                                              child: IgnorePointer(
                                                ignoring: true,
                                                child: TextFormField(
                                                  validator: (value) {
                                                    // Perform validation based on the 'validation' property
                                                    if (dynamicField
                                                                .validation ==
                                                            "required" &&
                                                        value!.isEmpty) {
                                                      return storedLanguage['Field is required'] ??
                                                          "Field is required";
                                                    }
                                                    return null;
                                                  },
                                                  controller:
                                                      merchantSettingController
                                                          .textEditingControllerMap[dynamicField
                                                          .fieldName],
                                                  decoration: InputDecoration(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 0,
                                                          horizontal: 16,
                                                        ),
                                                    filled:
                                                        true, // Fill the background with color
                                                    hintStyle: TextStyle(
                                                      color:
                                                          AppColors
                                                              .textFieldHintColor,
                                                    ),
                                                    fillColor:
                                                        Get.isDarkMode
                                                            ? AppColors
                                                                .darkCardColorDeep
                                                            : AppColors
                                                                .whiteColor,
                                                    enabledBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            AppThemes.getSliderInactiveColor(),
                                                        width: 1,
                                                      ),
                                                      borderRadius:
                                                          Dimensions
                                                              .kBorderRadius,
                                                    ),

                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              Dimensions
                                                                  .kBorderRadius,
                                                          borderSide: BorderSide(
                                                            color:
                                                                AppColors
                                                                    .mainColor,
                                                          ),
                                                        ),
                                                  ),
                                                  style:
                                                      context.t.displayMedium,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 16.h),
                                          ],
                                        ),
                                      if (dynamicField.type == 'textarea')
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  merchantSettingController
                                                      .toCapital(
                                                        dynamicField.fieldName,
                                                      ),
                                                  style:
                                                      context.t.displayMedium,
                                                ),
                                                dynamicField.validation ==
                                                        'required'
                                                    ? const SizedBox()
                                                    : Text(
                                                      " (Optional)",
                                                      style:
                                                          context
                                                              .t
                                                              .displayMedium,
                                                    ),
                                              ],
                                            ),
                                            SizedBox(height: 8.h),
                                            TextFormField(
                                              validator: (value) {
                                                if (dynamicField.validation ==
                                                        "required" &&
                                                    value!.isEmpty) {
                                                  return "Field is required";
                                                }
                                                return null;
                                              },
                                              controller:
                                                  merchantSettingController
                                                      .textEditingControllerMap[dynamicField
                                                      .fieldName],
                                              maxLines: 7,
                                              minLines: 5,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 16,
                                                    ),
                                                filled: true,
                                                hintStyle: TextStyle(
                                                  color:
                                                      AppColors
                                                          .textFieldHintColor,
                                                ),
                                                fillColor:
                                                    Get.isDarkMode
                                                        ? AppColors
                                                            .darkCardColorDeep
                                                        : AppColors.whiteColor,
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color:
                                                        AppThemes.getSliderInactiveColor(),
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      Dimensions.kBorderRadius,
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          Dimensions
                                                              .kBorderRadius,
                                                      borderSide: BorderSide(
                                                        color:
                                                            AppColors.mainColor,
                                                      ),
                                                    ),
                                              ),
                                              style: context.t.displayMedium,
                                            ),
                                            SizedBox(height: 16.h),
                                          ],
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    VSpace(40.h),
                    AppButton(
                      isLoading: merchantSettingController.isloadingUpdate,
                      onTap:
                          merchantSettingController.isloadingUpdate
                              ? null
                              : () async {
                                try {
                                  if (merchantSettingController.chargeApplyTo ==
                                      null) {
                                    Helpers.showSnackBar(
                                      msg: "Charge apply is required",
                                    );
                                  } else if (merchantSettingController
                                          .autoWithdraw ==
                                      null) {
                                    Helpers.showSnackBar(
                                      msg: "Auto settlement is required",
                                    );
                                  } else if (merchantSettingController
                                          .withdrawFrequency ==
                                      null) {
                                    Helpers.showSnackBar(
                                      msg: "Settlement frequency is required",
                                    );
                                  } else if (merchantSettingController
                                      .amountController
                                      .text
                                      .isEmpty) {
                                    Helpers.showSnackBar(
                                      msg: "Settlement amount is required",
                                    );
                                  } else {
                                    await merchantSettingController
                                        .renderDynamicFieldData();
                                    Map<String, String> stringMap = {};
                                    merchantSettingController.dynamicData
                                        .forEach((key, value) {
                                          if (value is String) {
                                            stringMap[key] = value;
                                          }
                                        });

                                    await Future.delayed(
                                      Duration(milliseconds: 200),
                                    );
                                    Map<String, String> body = {
                                      "charge_applied_to":
                                          merchantSettingController
                                                      .chargeApplyTo ==
                                                  "Myself"
                                              ? 'merchant'
                                              : 'user',
                                      "auto_withdraw":
                                          merchantSettingController
                                                      .autoWithdraw ==
                                                  'On'
                                              ? '1'
                                              : '0',
                                      "withdraw_frequency":
                                          merchantSettingController
                                                      .withdrawFrequency ==
                                                  'Weekly'
                                              ? 'weekly'
                                              : 'monthly',
                                      "withdraw_amount":
                                          merchantSettingController
                                              .amountController
                                              .text,
                                      "withdraw_currency":
                                          merchantSettingController
                                              .selectedCurrency,
                                    };
                                    body.addAll(stringMap);
                                    await merchantSettingController
                                        .merchatSettingUpdate(
                                          fields: body,
                                          fileList:
                                              merchantSettingController
                                                  .fileMap
                                                  .entries
                                                  .map((e) => e.value)
                                                  .toList(),
                                        )
                                        .then((value) {});
                                    print(body);
                                  }
                                } catch (e) {
                                  Helpers.showSnackBar(msg: e.toString());
                                }
                              },
                      text: storedLanguage['Save Settings'] ?? "Save Settings",
                    ),
                    VSpace(65.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
