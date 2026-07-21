import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../controllers/withdraw_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_custom_dropdown.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/spacing.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  FocusNode node = FocusNode();
  @override
  void initState() {
    node.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextTheme t = Theme.of(context).textTheme;
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<WithdrawController>(
      builder: (withdrawController) {
        return Scaffold(
          appBar: CustomAppBar(title: storedLanguage['Withdraw'] ?? "Withdraw"),
          body: Padding(
            padding: Dimensions.kDefaultPadding,
            child:
                withdrawController.isLoading
                    ? Helpers.appLoader()
                    : withdrawController.paymentGatewayList.isEmpty
                    ? Helpers.notFound()
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VSpace(32.h),
                        CustomTextField(
                          // CustomTextField is the main reason of the powerful idea you know=?
                          isBorderColor: true,
                          hintext:
                              storedLanguage['Search Gateway'] ??
                              "Search Gateway",
                          isSuffixIcon: true,
                          isSuffixBgColor: true,
                          suffixIcon: "search",
                          suffixIconColor:
                              Get.isDarkMode
                                  ? AppColors.whiteColor
                                  : AppColors.textFieldHintColor,
                          controller: withdrawController.gatewaySearchCtrl,
                          onChanged: withdrawController.queryPaymentGateway,
                        ),
                        VSpace(32.h),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color:
                                    Get.isDarkMode
                                        ? AppColors.darkCardColorDeep
                                        : AppColors.black20,
                                width: Get.isDarkMode ? .6 : .2,
                              ),
                            ),
                            child: ListView.builder(
                              itemCount:
                                  withdrawController.isGatewaySearching
                                      ? withdrawController
                                          .searchedGatewayItem
                                          .length
                                      : withdrawController
                                          .paymentGatewayList
                                          .length,
                              itemBuilder: (context, i) {
                                var data =
                                    withdrawController.isGatewaySearching
                                        ? withdrawController
                                            .searchedGatewayItem[i]
                                        : withdrawController
                                            .paymentGatewayList[i];
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 20.h),
                                  child: InkWell(
                                    borderRadius: Dimensions.kBorderRadius / 2,
                                    onTap: () async {
                                      Helpers.hideKeyboard();
                                      withdrawController.selectedGatewayIndex =
                                          i;
                                      withdrawController.getSelectedGatewayData(
                                        i,
                                      );
                                      withdrawController
                                          .getSelectedCurrencyData(
                                            withdrawController.selectedCurrency,
                                          );
                                      withdrawController.update();
                                      buildDialog(
                                        context,
                                        withdrawController,
                                        storedLanguage,
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.h,
                                        horizontal: 16.w,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color:
                                                Get.isDarkMode
                                                    ? AppColors
                                                        .darkCardColorDeep
                                                    : AppColors.black20,
                                            width: Get.isDarkMode ? .6 : .2,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            height: 42.h,
                                            width: 64.w,
                                            decoration: BoxDecoration(
                                              color:
                                                  Get.isDarkMode
                                                      ? AppColors.darkBgColor
                                                      : AppColors
                                                          .fillColorColor,
                                              borderRadius:
                                                  Dimensions.kBorderRadius / 2,
                                              image: DecorationImage(
                                                image:
                                                    CachedNetworkImageProvider(
                                                      data.image,
                                                    ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          HSpace(16.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  data.name.toString(),
                                                  style: t.bodyMedium,
                                                ),
                                                VSpace(1.h),
                                                Text(
                                                  data.description.toString(),
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: t.bodySmall?.copyWith(
                                                    color:
                                                        AppThemes.getParagraphColor(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 20.h,
                                            height: 20.h,
                                            decoration: BoxDecoration(
                                              color:
                                                  withdrawController
                                                              .selectedGatewayIndex ==
                                                          i
                                                      ? AppColors.mainColor
                                                      : Colors.transparent,
                                              border: Border.all(
                                                color:
                                                    withdrawController
                                                                .selectedGatewayIndex !=
                                                            i
                                                        ? Get.isDarkMode
                                                            ? AppColors
                                                                .darkCardColorDeep
                                                            : AppColors.black20
                                                        : Colors.transparent,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.done_rounded,
                                                size: 14.h,
                                                color:
                                                    withdrawController
                                                                .selectedGatewayIndex ==
                                                            i
                                                        ? AppColors.blackColor
                                                        : Colors.transparent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
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

  Future<dynamic> buildDialog(
    BuildContext context,
    WithdrawController withdrawController,
    storedLanguage,
  ) {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return GetBuilder<WithdrawController>(
          builder: (_) {
            return Container(
              padding: Dimensions.kDefaultPadding,
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: AppThemes.getDarkCardColor(),
                borderRadius: Dimensions.kBorderRadius * 2,
              ),
              child: ListView(
                children: [
                  VSpace(32.h),
                  if (withdrawController.gatewayName != "")
                    Padding(
                      padding: Dimensions.kDefaultPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              children: [
                                withdrawController.selectedCurrency == null
                                    ? const SizedBox()
                                    : Text(
                                      "Transaction Limit: ${withdrawController.minAmount}-${withdrawController.maxAmount} ${withdrawController.selectedCurrency}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.t.bodySmall?.copyWith(
                                        color: AppColors.redColor,
                                      ),
                                    ),
                                Spacer(),
                                Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(50),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(50),
                                    onTap: () {
                                      Get.back();
                                    },
                                    child: Ink(
                                      height: 26.h,
                                      width: 26.h,
                                      padding: EdgeInsets.all(3.h),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Get.isDarkMode
                                                ? AppColors.darkBgColor
                                                : AppColors.sliderInActiveColor,
                                      ),
                                      child: Icon(Icons.close, size: 15.h),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          VSpace(20.h),
                          Text(
                            storedLanguage['Select Gateway Currency'] ??
                                "Select Gateway Currency",
                            style: context.t.displayMedium,
                          ),
                          VSpace(12.h),
                          Container(
                            height: 50.h,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppThemes.getSliderInactiveColor(),
                              ),
                              borderRadius: Dimensions.kBorderRadius,
                            ),
                            child: AppCustomDropDown(
                              height: 50.h,
                              width: double.infinity,
                              items:
                                  withdrawController.supportedCurrencyList
                                      .map((e) => e)
                                      .toList(),
                              selectedValue:
                                  withdrawController.selectedCurrency,
                              onChanged: (value) async {
                                withdrawController.selectedCurrency = value;
                                withdrawController.getSelectedCurrencyData(
                                  value,
                                );
                                if (withdrawController.gatewayName ==
                                    "Paystack") {
                                  withdrawController.getBankFromCurrency(
                                    currencyCode: value,
                                  );
                                }

                                withdrawController.update();
                              },
                              hint:
                                  storedLanguage['Select currency'] ??
                                  "Select currency",
                              selectedStyle: context.t.displayMedium,
                              bgColor:
                                  Get.isDarkMode
                                      ? AppColors.darkBgColor
                                      : AppColors.fillColorColor,
                            ),
                          ),
                          VSpace(20.h),
                          withdrawController.selectedCurrency == null
                              ? const SizedBox()
                              : Text(
                                storedLanguage['Amount'] ?? 'Amount',
                                style: context.t.displayMedium,
                              ),
                          VSpace(12.h),
                          withdrawController.selectedCurrency == null
                              ? const SizedBox()
                              : CustomTextField(
                                focusNode: node,
                                isSuffixIcon:
                                    withdrawController.amountValue.isEmpty
                                        ? false
                                        : true,
                                suffixIconColor:
                                    withdrawController
                                            .isFollowedTransactionLimit
                                        ? AppColors.greenColor
                                        : AppColors.redColor,
                                suffixIcon:
                                    withdrawController.amountValue.isEmpty
                                        ? null
                                        : withdrawController
                                            .isFollowedTransactionLimit
                                        ? "check"
                                        : "warning",
                                suffixIconSize:
                                    withdrawController
                                            .isFollowedTransactionLimit
                                        ? 20.h
                                        : 15.h,
                                contentPadding: EdgeInsets.only(left: 20.w),
                                hintext:
                                    storedLanguage['Enter Amount'] ??
                                    'Enter Amount',
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                    withdrawController.maxAmount.length,
                                  ),
                                ],
                                controller: withdrawController.amountCtrl,
                                onChanged: withdrawController.onChangedAmount,
                              ),
                          VSpace(16.h),
                          if (withdrawController.amountValue.isNotEmpty &&
                              withdrawController.selectedCurrency != null)
                            Container(
                              height: 180.h,
                              width: double.maxFinite,
                              decoration: BoxDecoration(
                                borderRadius: Dimensions.kBorderRadius,
                                border: Border.all(
                                  color:
                                      Get.isDarkMode
                                          ? AppColors.black60
                                          : AppColors.black30,
                                  width: Dimensions.appThinBorder,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Amount In ${withdrawController.selectedCurrency}",
                                            style: context.t.displayMedium
                                                ?.copyWith(
                                                  color:
                                                      Get.isDarkMode
                                                          ? AppColors
                                                              .textFieldHintColor
                                                          : AppColors
                                                              .paragraphColor,
                                                ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                "${withdrawController.amountValue} ${withdrawController.selectedCurrency}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: context.t.displayMedium,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: .2,
                                      color:
                                          Get.isDarkMode
                                              ? AppColors.black60
                                              : AppColors.black30,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            storedLanguage['Charge'] ??
                                                "Charge",
                                            style: context.t.displayMedium
                                                ?.copyWith(
                                                  color:
                                                      Get.isDarkMode
                                                          ? AppColors
                                                              .textFieldHintColor
                                                          : AppColors
                                                              .paragraphColor,
                                                ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                "${withdrawController.charge} ${withdrawController.selectedCurrency}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: context.t.displayMedium
                                                    ?.copyWith(
                                                      color: AppColors.redColor,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: .2,
                                      color:
                                          Get.isDarkMode
                                              ? AppColors.black60
                                              : AppColors.black30,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            storedLanguage['Payout Amount'] ??
                                                "Payout Amount",
                                            style: context.t.displayMedium
                                                ?.copyWith(
                                                  color:
                                                      Get.isDarkMode
                                                          ? AppColors
                                                              .textFieldHintColor
                                                          : AppColors
                                                              .paragraphColor,
                                                ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                "${withdrawController.totalChargedAmount} ${withdrawController.selectedCurrency}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: context.t.displayMedium
                                                    ?.copyWith(
                                                      color:
                                                          AppColors.greenColor,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: .2,
                                      color:
                                          Get.isDarkMode
                                              ? AppColors.black60
                                              : AppColors.black30,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            storedLanguage['In Base Currency'] ??
                                                "In Base Currency",
                                            style: context.t.displayMedium
                                                ?.copyWith(
                                                  color:
                                                      Get.isDarkMode
                                                          ? AppColors
                                                              .textFieldHintColor
                                                          : AppColors
                                                              .paragraphColor,
                                                ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                "${withdrawController.totalPayoutAmountInBaseCurrency} ${HiveHelp.read(Keys.baseCurrency)}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: context.t.displayMedium
                                                    ?.copyWith(
                                                      color:
                                                          AppColors.greenColor,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          VSpace(32.h),
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
                                        if (withdrawController.gatewayName ==
                                            "") {
                                          Helpers.showSnackBar(
                                            msg:
                                                "Please select a gateway first",
                                          );
                                        } else if (withdrawController
                                                .selectedCurrency ==
                                            null) {
                                          Helpers.showSnackBar(
                                            msg: "Please select your currency.",
                                          );
                                        } else if (withdrawController
                                            .amountCtrl
                                            .text
                                            .isEmpty) {
                                          Helpers.showSnackBar(
                                            msg: "Amount field is required",
                                          );
                                        } else {
                                          if (double.parse(
                                                withdrawController
                                                    .amountCtrl
                                                    .text,
                                              ) <
                                              double.parse(
                                                withdrawController.minAmount,
                                              )) {
                                            Helpers.showSnackBar(
                                              msg:
                                                  "minimum payment ${withdrawController.minAmount} and maximum payment limit ${withdrawController.maxAmount}",
                                            );
                                          } else if (withdrawController
                                                  .isFollowedTransactionLimit ==
                                              false) {
                                            Helpers.showSnackBar(
                                              msg:
                                                  "minimum payment ${withdrawController.minAmount} and maximum payment limit ${withdrawController.maxAmount}",
                                            );
                                          } else {
                                            Navigator.pop(context);
                                            withdrawController
                                                    .selectedDynamicList =
                                                await withdrawController
                                                    .dynamicList
                                                    .where(
                                                      (e) =>
                                                          e.name ==
                                                          withdrawController
                                                              .gatewayName,
                                                    )
                                                    .toList();
                                            await withdrawController
                                                .filterData();

                                            await withdrawController
                                                .payoutRequest(
                                                  fields: {
                                                    "amount":
                                                        withdrawController
                                                            .amountCtrl
                                                            .text,
                                                    "payout_method_id":
                                                        withdrawController
                                                            .gatewayId
                                                            .toString(),
                                                    "supported_currency":
                                                        withdrawController
                                                            .selectedCurrency,
                                                  },
                                                );
                                          }
                                        }
                                      },
                              text:
                                  storedLanguage['Confirm & Next'] ??
                                  "Confirm & Next",
                            ),
                          ),
                          VSpace(node.hasFocus ? 150.h : 50.h),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
