import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/config/dimensions.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/withdraw_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_custom_dropdown.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_searchable_dropdown.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/spacing.dart';

class WithdrawPreviewScreen extends StatelessWidget {
  WithdrawPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WithdrawController.to.paystackSelectedBank = null;
    WithdrawController.to.selectedPaypalValue = null;
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<WithdrawController>(
      builder: (withdrawController) {
        return Scaffold(
          appBar: CustomAppBar(
            title: storedLanguage['Withdraw Preview'] ?? 'Withdraw Preview',
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: Dimensions.kDefaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VSpace(40.h),
                  Container(
                    height: 210.h,
                    width: double.maxFinite,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 15.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppThemes.getFillColor(),
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              storedLanguage['Payout by'] ?? 'Payout by',
                              style: context.t.displayMedium?.copyWith(
                                color: AppThemes.getParagraphColor(),
                              ),
                            ),
                            Text(
                              '${withdrawController.gatewayName}',
                              style: context.t.bodyMedium,
                            ),
                          ],
                        ),
                        Container(
                          height: .2,
                          color:
                              Get.isDarkMode
                                  ? AppColors.black60
                                  : AppColors.black30,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              storedLanguage['Requested Amount'] ??
                                  'Requested Amount',
                              style: context.t.displayMedium?.copyWith(
                                color: AppThemes.getParagraphColor(),
                              ),
                            ),
                            Text(
                              '${withdrawController.amountCtrl.text} ${withdrawController.selectedCurrency}',
                              style: context.t.bodyMedium?.copyWith(
                                color: AppColors.greenColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: .2,
                          color:
                              Get.isDarkMode
                                  ? AppColors.black60
                                  : AppColors.black30,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              storedLanguage['Charge Amount'] ??
                                  'Charge Amount',
                              style: context.t.displayMedium?.copyWith(
                                color: AppThemes.getParagraphColor(),
                              ),
                            ),
                            Text(
                              '${withdrawController.chargeAmount} ${withdrawController.selectedCurrency}',
                              style: context.t.bodyMedium?.copyWith(
                                color: AppColors.redColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: .2,
                          color:
                              Get.isDarkMode
                                  ? AppColors.black60
                                  : AppColors.black30,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              storedLanguage['Total Payable'] ??
                                  'Total Payable',
                              style: context.t.displayMedium?.copyWith(
                                color: AppThemes.getParagraphColor(),
                              ),
                            ),
                            Text(
                              '${withdrawController.totalPayable} ${withdrawController.selectedCurrency}',
                              style: context.t.bodyMedium?.copyWith(
                                color: AppColors.redColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  VSpace(24.h),
                  if (withdrawController.currencyList.isNotEmpty)
                    Text(
                      storedLanguage['Select Bank Currency'] ??
                          "Select Bank Currency",
                      style: context.t.bodyMedium,
                    ),
                  if (withdrawController.currencyList.isNotEmpty) VSpace(5.h),
                  if (withdrawController.currencyList.isNotEmpty)
                    Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: AppThemes.getFillColor(),
                        borderRadius: Dimensions.kBorderRadius,
                      ),
                      child: AppCustomDropDown(
                        height: 46.h,
                        width: double.infinity,
                        items:
                            withdrawController.currencyList
                                .map((e) => e)
                                .toList(),
                        selectedValue: withdrawController.selectedBankCurrency,
                        onChanged: (value) async {
                          withdrawController.selectedBankCurrency = value;
                          if (withdrawController.gatewayName != "Paypal") {
                            withdrawController.bankFromCurrencyList.clear();
                            withdrawController.getBankFromCurrency(
                              currencyCode: value,
                            );
                          }

                          withdrawController.update();
                        },
                        hint:
                            storedLanguage['Select Bank Currency'] ??
                            "Select Bank Currency",
                        selectedStyle: context.t.displayMedium,
                      ),
                    ),
                  if (withdrawController.isBankLoading)
                    Padding(
                      padding: EdgeInsets.only(top: 20.h),
                      child: Helpers.appLoader(),
                    ),
                  if (withdrawController.gatewayName == "Paystack" &&
                      withdrawController.bankFromCurrencyList.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 24.h),
                      child: Text("Select Bank", style: context.t.bodyMedium),
                    ),
                  if (withdrawController.gatewayName == "Paystack" &&
                      withdrawController.bankFromCurrencyList.isNotEmpty)
                    VSpace(5.h),
                  if (withdrawController.gatewayName == "Paystack" &&
                      withdrawController.bankFromCurrencyList.isNotEmpty)
                    CustomSearchableDropDown(
                      padding: EdgeInsets.all(4),
                      items: withdrawController.bankFromCurrencyList,
                      prefixIcon: SizedBox(),
                      decoration: BoxDecoration(
                        color: AppThemes.getFillColor(),
                        borderRadius: Dimensions.kBorderRadius,
                      ),
                      label: storedLanguage['Select Bank'] ?? 'Select Bank',
                      dropdownItemStyle: TextStyle(color: Colors.black),
                      labelStyle: context.t.bodySmall?.copyWith(
                        color:
                            Get.isDarkMode
                                ? AppColors.whiteColor
                                : AppColors.blackColor,
                      ),
                      dropDownMenuItems: [
                        for (
                          int i = 0;
                          i < withdrawController.bankFromCurrencyList.length;
                          i++
                        )
                          withdrawController.bankFromCurrencyList[i].name,
                      ],
                      suffixIcon: Icon(
                        Icons.arrow_drop_down,
                        color:
                            withdrawController.bankFromCurrencyList.isEmpty
                                ? Colors.grey[400]
                                : Get.isDarkMode
                                ? Colors.grey[600]
                                : AppColors.blackColor,
                      ),
                      onChanged: (value) {
                        withdrawController.paystackSelectedBank = value.name;
                        var data = withdrawController.bankFromCurrencyList
                            .firstWhere((e) => e.name == value.name);
                        withdrawController.paystackSelectedBankNumber =
                            data.code.toString();
                        withdrawController.paystackSelectedType =
                            data.type.toString();

                        withdrawController.update();
                      },
                    ),
                  Form(
                    key: withdrawController.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //=====================if the gateway is paypal==============
                        if (withdrawController.gatewayName == "Paypal")
                          VSpace(24.h),
                        if (withdrawController.gatewayName == "Paypal")
                          Text(
                            "Select Recipient Type",
                            style: context.t.bodyMedium,
                          ),
                        if (withdrawController.gatewayName == "Paypal")
                          VSpace(5.h),
                        if (withdrawController.gatewayName == "Paypal")
                          Container(
                            height: 50.h,
                            decoration: BoxDecoration(
                              color: AppThemes.getFillColor(),
                              borderRadius: Dimensions.kBorderRadius,
                            ),
                            child: AppCustomDropDown(
                              height: 46.h,
                              width: double.infinity,
                              items: ["Email", "Phone", "Paypal Id"],
                              selectedValue:
                                  withdrawController.selectedPaypalValue,
                              onChanged: (value) async {
                                withdrawController.selectedPaypalValue = value;
                                withdrawController.update();
                              },
                              hint:
                                  storedLanguage['Select type'] ??
                                  "Select type",
                              selectedStyle: context.t.displayMedium,
                            ),
                          ),

                        VSpace(25.h),
                        if (withdrawController
                            .selectedDynamicList
                            .isNotEmpty) ...[
                          ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount:
                                withdrawController.selectedDynamicList.length,
                            itemBuilder: (context, index) {
                              final dynamicField =
                                  withdrawController.selectedDynamicList[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (dynamicField.type == "file")
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              dynamicField.fieldLevel!,
                                              style: context.t.displayMedium,
                                            ),
                                            dynamicField.validation ==
                                                    'required'
                                                ? const SizedBox()
                                                : Text(
                                                  " ${storedLanguage['(Optional)'] ?? "(Optional)"}",
                                                  style:
                                                      context.t.displayMedium,
                                                ),
                                          ],
                                        ),
                                        SizedBox(height: 8.h),
                                        Container(
                                          height: 45.5,
                                          width: double.maxFinite,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 10.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppThemes.getFillColor(),
                                            borderRadius:
                                                Dimensions.kBorderRadius,
                                          ),
                                          child: Row(
                                            children: [
                                              HSpace(12.w),
                                              Text(
                                                withdrawController
                                                            .imagePickerResults[dynamicField
                                                            .fieldName] !=
                                                        null
                                                    ? storedLanguage['1 File selected'] ??
                                                        "1 File selected"
                                                    : storedLanguage['No File selected'] ??
                                                        "No File selected",
                                                style: context.t.bodySmall?.copyWith(
                                                  color:
                                                      withdrawController
                                                                  .imagePickerResults[dynamicField
                                                                  .fieldName] !=
                                                              null
                                                          ? AppColors.greenColor
                                                          : AppColors.black60,
                                                ),
                                              ),
                                              const Spacer(),
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () async {
                                                    Helpers.hideKeyboard();

                                                    await withdrawController
                                                        .pickFile(
                                                          dynamicField
                                                              .fieldName!,
                                                        );
                                                  },
                                                  borderRadius:
                                                      Dimensions.kBorderRadius,
                                                  child: Ink(
                                                    width: 113.w,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppColors.mainColor,
                                                      borderRadius:
                                                          Dimensions
                                                              .kBorderRadius,
                                                      border: Border.all(
                                                        color:
                                                            AppColors.mainColor,
                                                        width: .2,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        storedLanguage['Choose File'] ??
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
                                              dynamicField.fieldLevel!,
                                              style: context.t.displayMedium,
                                            ),
                                            dynamicField.validation ==
                                                    'required'
                                                ? const SizedBox()
                                                : Text(
                                                  " ${storedLanguage['(Optional)'] ?? "(Optional)"}",
                                                  style:
                                                      context.t.displayMedium,
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
                                            withdrawController
                                                .textEditingControllerMap[dynamicField
                                                    .fieldName]!
                                                .text = v;
                                          },
                                          controller:
                                              withdrawController
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
                                                  AppColors.textFieldHintColor,
                                            ),
                                            fillColor:
                                                Colors
                                                    .transparent, // Background color
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    AppThemes.getSliderInactiveColor(),
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  Dimensions.kBorderRadius,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  Dimensions.kBorderRadius,
                                              borderSide: BorderSide(
                                                color: AppColors.mainColor,
                                              ),
                                            ),
                                          ),
                                          style: context.t.bodyMedium,
                                        ),
                                        SizedBox(
                                          height:
                                              index ==
                                                      withdrawController
                                                              .selectedDynamicList
                                                              .length -
                                                          1
                                                  ? 0
                                                  : 16.h,
                                        ),
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
                                              dynamicField.fieldLevel!,
                                              style: context.t.displayMedium,
                                            ),
                                            dynamicField.validation ==
                                                    'required'
                                                ? const SizedBox()
                                                : Text(
                                                  " ${storedLanguage['(Optional)'] ?? "(Optional)"}",
                                                  style:
                                                      context.t.displayMedium,
                                                ),
                                          ],
                                        ),
                                        SizedBox(height: 8.h),
                                        TextFormField(
                                          validator: (value) {
                                            if (dynamicField.validation ==
                                                    "required" &&
                                                value!.isEmpty) {
                                              return storedLanguage['Field is required'] ??
                                                  "Field is required";
                                            }
                                            return null;
                                          },
                                          controller:
                                              withdrawController
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
                                                  AppColors.textFieldHintColor,
                                            ),
                                            fillColor:
                                                Colors
                                                    .transparent, // Background color
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    AppThemes.getSliderInactiveColor(),
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  Dimensions.kBorderRadius,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25.r),
                                              borderSide: BorderSide(
                                                color: AppColors.mainColor,
                                              ),
                                            ),
                                          ),
                                          style: context.t.bodyMedium,
                                        ),
                                        SizedBox(height: 16.h),
                                      ],
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                        VSpace(24.h),

                        if (withdrawController.enable_for == true)
                          CustomTextField(
                            isBorderColor: true,
                            isSuffixIcon: false,
                            contentPadding: EdgeInsets.only(left: 20.w),
                            hintext:
                                storedLanguage['Security Pin'] ??
                                'Security Pin',
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            controller:
                                withdrawController.securityPinController,
                            onChanged: (v) {},
                          ),
                        VSpace(40.h),
                        Material(
                          color: Colors.transparent,
                          child: AppButton(
                            isLoading:
                                withdrawController.isPayoutSubmitting
                                    ? true
                                    : false,
                            onTap:
                                withdrawController.isPayoutSubmitting
                                    ? null
                                    : () async {
                                      Helpers.hideKeyboard();
                                      // if the payment gateway is paystack
                                      if (withdrawController.gatewayName ==
                                          "Paystack") {
                                        if (withdrawController
                                                .paystackSelectedBank ==
                                            null) {
                                          Helpers.showSnackBar(
                                            msg: "Please select bank",
                                          );
                                        } else if (withdrawController
                                                .formKey
                                                .currentState!
                                                .validate() &&
                                            withdrawController
                                                .requiredTypeFileList
                                                .isEmpty) {
                                          Map<String, String> body = {
                                            if (withdrawController
                                                .securityPinController
                                                .text
                                                .isNotEmpty)
                                              "security_pin":
                                                  withdrawController
                                                      .securityPinController
                                                      .text,
                                            "currency":
                                                withdrawController
                                                    .selectedCurrency,
                                            "bank":
                                                withdrawController
                                                    .paystackSelectedBankNumber,
                                            "trx_id": withdrawController.utr,
                                            "type": "ghipss",
                                          };

                                          withdrawController
                                              .textEditingControllerMap
                                              .forEach((key, value) {
                                                body[key] = value.text;
                                              });
                                          await Future.delayed(
                                            Duration(milliseconds: 100),
                                          );

                                          await withdrawController
                                              .submitPaystackPayout(
                                                context: context,
                                                fields: body,
                                              );
                                        } else {
                                          if (!withdrawController
                                              .formKey
                                              .currentState!
                                              .validate()) {
                                            Helpers.showSnackBar(
                                              msg:
                                                  "Please fill in all required fields.",
                                            );
                                          } else if (withdrawController
                                              .requiredTypeFileList
                                              .isNotEmpty) {
                                            Helpers.showSnackBar(
                                              msg: withdrawController
                                                  .requiredTypeFileList
                                                  .map(
                                                    (item) =>
                                                        '$item is required',
                                                  )
                                                  .join('\n'),
                                            );
                                          }

                                          print(
                                            "required type file list===========================: ${withdrawController.requiredTypeFileList}",
                                          );
                                        }
                                      }
                                      // if the payment gateway is other
                                      else {
                                        if (withdrawController.gatewayName ==
                                                "Paypal" &&
                                            withdrawController
                                                    .selectedPaypalValue ==
                                                null) {
                                          Helpers.showSnackBar(
                                            msg: "Please select bank currency",
                                          );
                                        } else if (withdrawController
                                                .formKey
                                                .currentState!
                                                .validate() &&
                                            withdrawController
                                                .requiredTypeFileList
                                                .isEmpty) {
                                          Map<String, String> body = {
                                            if (withdrawController
                                                    .selectedCurrency !=
                                                null)
                                              "trx_id": withdrawController.utr,
                                            "currency_code":
                                                withdrawController
                                                            .gatewayName ==
                                                        "Paypal"
                                                    ? withdrawController
                                                        .selectedBankCurrency
                                                        .toString()
                                                    : withdrawController
                                                        .selectedCurrency
                                                        .toString(),
                                            if (withdrawController.enable_for ==
                                                true)
                                              "security_pin":
                                                  withdrawController
                                                      .securityPinController
                                                      .text,
                                            if (withdrawController
                                                    .gatewayName ==
                                                "Paypal")
                                              "recipient_type":
                                                  withdrawController
                                                      .selectedPaypalValue,
                                          };
                                          withdrawController
                                              .textEditingControllerMap
                                              .forEach((key, value) {
                                                body[key] = value.text;
                                              });

                                          await Future.delayed(
                                            Duration(milliseconds: 100),
                                          );
                                          if (withdrawController
                                              .fileMap
                                              .isNotEmpty) {
                                            await withdrawController
                                                .payoutConfirmSubmit(
                                                  fileList:
                                                      withdrawController
                                                          .fileMap
                                                          .entries
                                                          .map((e) => e.value)
                                                          .toList(),
                                                  fields: body,
                                                  context: context,
                                                );
                                          }
                                          if (withdrawController
                                              .fileMap
                                              .isEmpty) {
                                            await withdrawController
                                                .payoutConfirmSubmit(
                                                  fileList: null,
                                                  fields: body,
                                                  context: context,
                                                );
                                          }
                                        } else {
                                          if (!withdrawController
                                              .formKey
                                              .currentState!
                                              .validate()) {
                                            Helpers.showSnackBar(
                                              msg:
                                                  "Please fill in all required fields.",
                                            );
                                          } else if (withdrawController
                                              .requiredTypeFileList
                                              .isNotEmpty) {
                                            Helpers.showSnackBar(
                                              msg: withdrawController
                                                  .requiredTypeFileList
                                                  .map(
                                                    (item) =>
                                                        '$item is required',
                                                  )
                                                  .join('\n'),
                                            );
                                          }
                                          print(
                                            "required type file list===========================: ${withdrawController.requiredTypeFileList}",
                                          );
                                        }
                                      }
                                    },
                            text:
                                storedLanguage['Confirm Now'] ?? 'Confirm Now',
                          ),
                        ),
                        VSpace(65.h),
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
  }
}
