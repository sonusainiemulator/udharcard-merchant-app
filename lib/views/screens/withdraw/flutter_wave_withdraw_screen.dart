import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/config/dimensions.dart';
import 'package:paysecure/views/widgets/custom_appbar.dart';
import 'package:paysecure/views/widgets/custom_textfield.dart';
import 'package:paysecure/views/widgets/spacing.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/withdraw_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_custom_dropdown.dart';
import '../../widgets/custom_searchable_dropdown.dart';

class FlutterWaveWithdrawScreen extends StatelessWidget {
  FlutterWaveWithdrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WithdrawController.to.flutterWaveSelectedTransfer = null;
    WithdrawController.to.bankFromBankDynamicList = [];
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<WithdrawController>(builder: (withdrawController) {
      return Scaffold(
        appBar: CustomAppBar(
          title: storedLanguage['Payout Preview'] ?? 'Payout Preview',
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
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
                          Text(storedLanguage['Payout by'] ?? 'Payout by',
                              style: context.t.displayMedium?.copyWith(
                                  color: AppThemes.getParagraphColor())),
                          Text(
                            '${withdrawController.gatewayName}',
                            style: context.t.bodyMedium,
                          )
                        ],
                      ),
                      Container(
                        height: .2,
                        color: Get.isDarkMode
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
                                  color: AppThemes.getParagraphColor())),
                          Text(
                            '${withdrawController.amountCtrl.text} ${withdrawController.selectedCurrency}',
                            style: context.t.bodyMedium
                                ?.copyWith(color: AppColors.greenColor),
                          )
                        ],
                      ),
                      Container(
                        height: .2,
                        color: Get.isDarkMode
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
                                  color: AppThemes.getParagraphColor())),
                          Text(
                            '${withdrawController.chargeAmount} ${withdrawController.selectedCurrency}',
                            style: context.t.bodyMedium
                                ?.copyWith(color: AppColors.redColor),
                          )
                        ],
                      ),
                      Container(
                        height: .2,
                        color: Get.isDarkMode
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
                                  color: AppThemes.getParagraphColor())),
                          Text(
                            '${withdrawController.totalPayable} ${withdrawController.selectedCurrency}',
                            style: context.t.bodyMedium
                                ?.copyWith(color: AppColors.redColor),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                VSpace(60.h),
                if (withdrawController.selectedCurrency != null)
                  Text(
                      storedLanguage['Select Bank Currency'] ??
                          "Select Bank Currency",
                      style: context.t.bodyMedium),
                if (withdrawController.selectedCurrency != null) VSpace(5.h),
                if (withdrawController.selectedCurrency != null)
                  IgnorePointer(
                    ignoring: true,
                    child: CustomTextField(
                        hintext: 'Select Bank Currency',
                        controller:
                            TextEditingController(text: withdrawController.selectedCurrency)),
                  ),
                VSpace(15.h),
                if (withdrawController.bankList.isNotEmpty)
                  Text(storedLanguage['Select Transfer'] ?? "Select Transfer",
                      style: context.t.bodyMedium),
                if (withdrawController.bankList.isNotEmpty) VSpace(5.h),
                if (withdrawController.bankList.isNotEmpty)
                  Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: AppThemes.getFillColor(),
                      borderRadius: Dimensions.kBorderRadius,
                    ),
                    child: AppCustomDropDown(
                      height: 46.h,
                      width: double.infinity,
                      items: withdrawController.bankList.map((e) => e).toList(),
                      selectedValue: withdrawController.flutterWaveSelectedTransfer,
                      onChanged: (value) async {
                        withdrawController.flutterWaveSelectedTransfer = value;
                        withdrawController.bankFromBankList.clear();
                        withdrawController.bankFromBankDynamicList.clear();
                        withdrawController.getBankFromBank(bankName: value);
                        withdrawController.update();
                      },
                      hint: storedLanguage['Select Transfer'] ??
                          "Select Transfer",
                      selectedStyle: context.t.displayMedium,
                    ),
                  ),
                VSpace(15.h),
                if (withdrawController.bankFromBankList.isNotEmpty)
                  Text(storedLanguage['Select Bank'] ?? "Select Bank",
                      style: context.t.bodyMedium),
                if (withdrawController.bankFromBankList.isNotEmpty) VSpace(5.h),
                if (withdrawController.bankFromBankList.isNotEmpty)
                  CustomSearchableDropDown(
                    padding: EdgeInsets.all(4),
                    items: withdrawController.bankFromBankList,
                    prefixIcon: SizedBox(),
                    decoration: BoxDecoration(
                      color: AppThemes.getFillColor(),
                      borderRadius: Dimensions.kBorderRadius,
                    ),
                    label: storedLanguage['Select Bank'] ?? 'Select Bank',
                    dropdownItemStyle: TextStyle(
                      color: Colors.black,
                    ),
                    labelStyle: context.t.bodySmall?.copyWith(
                        color: Get.isDarkMode
                            ? AppColors.whiteColor
                            : AppColors.blackColor),
                    dropDownMenuItems: [
                      for (int i = 0; i < withdrawController.bankFromBankList.length; i++)
                        withdrawController.bankFromBankList[i].name,
                    ],
                    suffixIcon: Icon(
                      Icons.arrow_drop_down,
                      color: withdrawController.bankFromBankList.isEmpty
                          ? Colors.grey[400]
                          : Get.isDarkMode
                              ? Colors.grey[600]
                              : AppColors.blackColor,
                    ),
                    onChanged: (value) {
                      withdrawController.flutterWaveSelectedBank = value.name;
                      var data = withdrawController.bankFromBankList
                          .firstWhere((e) => e.name == value.name);
                      withdrawController.flutterwaveSelectedBankNumber = data.code.toString();
                      withdrawController.update();
                    },
                  ),
                VSpace(24.h),
                Form(
                  key: withdrawController.formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (withdrawController.isBankLoading) Helpers.appLoader(),
                        if (withdrawController.bankFromBankDynamicList.isNotEmpty) ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: withdrawController.bankFromBankDynamicList.length,
                            itemBuilder: (context, index) {
                              var data = withdrawController.bankFromBankDynamicList[index];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.replaceAll("_", " "),
                                        style: context.t.displayMedium,
                                      ),
                                      SizedBox(
                                        height: 8.h,
                                      ),
                                      TextFormField(
                                        validator: (value) {
                                          // Perform validation based on the 'validation' property
                                          if (value!.isEmpty) {
                                            return storedLanguage[
                                                    'Field is required'] ??
                                                "Field is required";
                                          }
                                          return null;
                                        },
                                        onChanged: (v) {
                                          withdrawController
                                              .bankFromBanktextEditingControllerMap[
                                                  data]!
                                              .text = v;
                                        },
                                        controller:
                                            withdrawController.bankFromBanktextEditingControllerMap[
                                                data],
                                        keyboardType: data
                                                .replaceAll("_", " ")
                                                .contains("number")
                                            ? TextInputType.number
                                            : TextInputType.text,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 0, horizontal: 16),
                                          filled:
                                              true, // Fill the background with color
                                          hintStyle: TextStyle(
                                            color: AppColors.textFieldHintColor,
                                          ),
                                          fillColor: Colors
                                              .transparent, // Background color
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: AppThemes
                                                  .getSliderInactiveColor(),
                                              width: 1,
                                            ),
                                            borderRadius:
                                                Dimensions.kBorderRadius,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                Dimensions.kBorderRadius,
                                            borderSide: BorderSide(
                                                color: AppColors.mainColor),
                                          ),
                                        ),
                                        style: context.t.bodyMedium,
                                      ),
                                      SizedBox(
                                        height: 16.h,
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ]),
                ),
                if (withdrawController.enable_for == true)
                  CustomTextField(
                    isBorderColor: true,
                    isSuffixIcon: false,
                    contentPadding: EdgeInsets.only(left: 20.w),
                    hintext: storedLanguage['Security Pin'] ?? 'Security Pin',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    controller: withdrawController.securityPinController,
                    onChanged: (v) {},
                  ),
                VSpace(40.h),
                if (withdrawController.flutterWaveSelectedTransfer != null &&
                    withdrawController.flutterWaveSelectedBank != null)
                  Material(
                    color: Colors.transparent,
                    child: AppButton(
                      isLoading: withdrawController.isPayoutSubmitting ? true : false,
                      onTap: withdrawController.isPayoutSubmitting
                          ? null
                          : () async {
                              Helpers.hideKeyboard();
                              if (withdrawController.selectedCurrency == null) {
                                Helpers.showSnackBar(
                                    msg: "Please select bank currency");
                              } else if (withdrawController.flutterWaveSelectedBank == null) {
                                Helpers.showSnackBar(msg: "Please select bank");
                              } else if (withdrawController.formKey.currentState!.validate()) {
                                Map<String, String> body = {
                                  if (withdrawController.enable_for == true)
                                    "security_pin":
                                        withdrawController.securityPinController.text,
                                  "trx_id": withdrawController.utr,
                                  "transfer_name":
                                      withdrawController.flutterWaveSelectedTransfer,
                                  "currency_code": withdrawController.selectedCurrency,
                                  "bank": withdrawController.flutterwaveSelectedBankNumber,
                                };
                                withdrawController.bankFromBanktextEditingControllerMap
                                    .forEach((key, value) {
                                  body[key] = value.text;
                                });
                                await Future.delayed(
                                    Duration(milliseconds: 100));
                                await withdrawController.submitFlutterwavePayout(
                                    context: context, fields: body);
                              } else {
                                print(
                                    "required type file list===========================: ${withdrawController.requiredTypeFileList}");
                                Helpers.showSnackBar(
                                    msg: "Please fill in all required fields.");
                              }
                            },
                      text: storedLanguage['Confirm Now'] ?? 'Confirm Now',
                      borderRadius: Dimensions.kBorderRadius,
                    ),
                  ),
                VSpace(40.h),
              ],
            ),
          ),
        ),
      );
    });
  }
}
