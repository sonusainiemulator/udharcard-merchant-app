import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:paysecure/controllers/bindings/controller_index.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../../../config/app_colors.dart';
import '../../../../config/dimensions.dart';
import '../../../../themes/themes.dart';
import '../../../../utils/app_constants.dart';
import '../../../../utils/services/helpers.dart';
import '../../../../utils/services/localstorage/hive.dart';
import '../../../../utils/services/localstorage/keys.dart';
import '../../../routes/routes_name.dart';
import '../home/home_screen.dart';
import '../../widgets/appDialog.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/search_dialog.dart';
import '../../widgets/spacing.dart';

class WithdrawHistoryScreen extends StatelessWidget {
  const WithdrawHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme t = Theme.of(context).textTheme;
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<WithdrawHistoryController>(
      builder: (withdrawHistoryController) {
        return GetBuilder<WithdrawController>(
          builder: (withdrawCtrl) {
            return Scaffold(
              appBar: buildAppbar(
                storedLanguage,
                context,
                withdrawHistoryController,
              ),
              body: RefreshIndicator(
                color: AppColors.mainColor,
                onRefresh: () async {
                  withdrawHistoryController.refreshSearchData();
                  withdrawHistoryController.resetDataAfterSearching(
                    isFromOnRefreshIndicator: true,
                  );
                  await withdrawHistoryController.getRequestList(
                    page: 1,
                    email: "",
                    created_at: "",
                    utr: "",
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: withdrawHistoryController.scrollController,
                  child: Padding(
                    padding: Dimensions.kDefaultPadding,
                    child: Column(
                      children: [
                        VSpace(20.h),
                        withdrawHistoryController.isLoading
                            ? buildTransactionLoader(
                              itemCount: 20,
                              isReverseColor: true,
                            )
                            : withdrawHistoryController.withdrawList.isEmpty
                            ? Helpers.notFound()
                            : ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount:
                                  withdrawHistoryController.withdrawList.length,
                              itemBuilder: (context, i) {
                                var data =
                                    withdrawHistoryController.withdrawList[i];
                                return InkWell(
                                  borderRadius: Dimensions.kBorderRadius,
                                  onTap: () {
                                    appDialog(
                                      context: context,
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          InkResponse(
                                            onTap: () {
                                              Get.back();
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(7.h),
                                              decoration: BoxDecoration(
                                                color: AppThemes.getFillColor(),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                size: 14.h,
                                                color:
                                                    Get.isDarkMode
                                                        ? AppColors.whiteColor
                                                        : AppColors.blackColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 48.h,
                                            height: 48.h,
                                            padding: EdgeInsets.all(12.h),
                                            decoration: BoxDecoration(
                                              color: checkBgColor(
                                                data.status.toString(),
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Image.asset(
                                              checkStatus(
                                                data.status.toString(),
                                              ),
                                              color: checkIconColor(
                                                data.status.toString(),
                                              ),
                                            ),
                                          ),
                                          VSpace(12.h),
                                          InkWell(
                                            onTap: () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).removeCurrentSnackBar();
                                              Clipboard.setData(
                                                new ClipboardData(
                                                  text:
                                                      "${data.transactionId ?? ''}",
                                                ),
                                              );

                                              Helpers.showSnackBar(
                                                msg: "Copied Successfully",
                                                title: 'Success',
                                                bgColor: AppColors.greenColor,
                                              );
                                            },
                                            child: Container(
                                              color: Colors.transparent,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Center(
                                                    child: Text(
                                                      storedLanguage['Transaction ID'] ??
                                                          "Transaction ID",
                                                      style: t.bodyMedium?.copyWith(
                                                        color:
                                                            Get.isDarkMode
                                                                ? AppColors
                                                                    .whiteColor
                                                                : AppColors
                                                                    .blackColor
                                                                    .withValues(
                                                                      alpha: .5,
                                                                    ),
                                                      ),
                                                    ),
                                                  ),
                                                  Center(
                                                    child: Text(
                                                      data.transactionId ?? '',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: t.bodySmall,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          VSpace(12.h),
                                          Text(
                                            storedLanguage['Status'] ??
                                                "Status",
                                            style: t.bodyMedium?.copyWith(
                                              color:
                                                  Get.isDarkMode
                                                      ? AppColors.whiteColor
                                                      : AppColors.blackColor,
                                            ),
                                          ),
                                          Text(
                                            data.status.toString(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.bodySmall?.copyWith(
                                              color:
                                                  data.status.toString() ==
                                                          "Pending"
                                                      ? AppColors.pendingColor
                                                      : data.status
                                                              .toString() ==
                                                          "Generated"
                                                      ? AppColors.euroColor
                                                      : data.status
                                                              .toString() ==
                                                          "Payout Done"
                                                      ? AppColors.greenColor
                                                      : AppColors.redColor,
                                            ),
                                          ),
                                          VSpace(12.h),
                                          Text(
                                            storedLanguage['Amount'] ??
                                                "Amount",
                                            style: t.bodyMedium?.copyWith(
                                              color:
                                                  Get.isDarkMode
                                                      ? AppColors.whiteColor
                                                      : AppColors.blackColor,
                                            ),
                                          ),
                                          Text(
                                            data.amount.toString() +
                                                " " +
                                                data.currency.toString(),
                                            style: t.bodySmall,
                                          ),
                                          VSpace(12.h),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Ink(
                                    width: double.maxFinite,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 10.h,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 45.h,
                                          height: 45.h,
                                          padding: EdgeInsets.all(12.h),
                                          decoration: BoxDecoration(
                                            color: checkBgColor(
                                              data.status.toString(),
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Image.asset(
                                            checkStatus(data.status.toString()),
                                            color: checkIconColor(
                                              data.status.toString(),
                                            ),
                                          ),
                                        ),
                                        HSpace(12.w),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    flex: 8,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          data.gateway
                                                              .toString(),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow.fade,
                                                          style: t.bodyMedium
                                                              ?.copyWith(
                                                                fontSize: 17.sp,
                                                              ),
                                                        ),
                                                        VSpace(3.h),
                                                        Text(
                                                          DateFormat(
                                                            'dd MMM yyyy',
                                                          ).format(
                                                            DateTime.parse(
                                                              data.createdTime
                                                                  .toString(),
                                                            ),
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style: t.bodySmall
                                                              ?.copyWith(
                                                                color:
                                                                    AppThemes.getBlack50Color(),
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  HSpace(3.w),
                                                  Flexible(
                                                    flex: 7,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            if (data.status
                                                                    .toString() ==
                                                                "Pending")
                                                              GetBuilder<
                                                                WithdrawController
                                                              >(
                                                                builder: (_) {
                                                                  return buildBtn(
                                                                    withdrawCtrl,
                                                                    t,
                                                                    isLoading:
                                                                        WithdrawController.to.isPayoutSubmitting &&
                                                                                WithdrawController.to.selectedPayoutConfirmIndex ==
                                                                                    i
                                                                            ? true
                                                                            : false,
                                                                    onTap:
                                                                        WithdrawController.to.isPayoutSubmitting
                                                                            ? null
                                                                            : () async {
                                                                              WithdrawController.to.selectedPayoutConfirmIndex = i;
                                                                              WithdrawController.to.update();
                                                                              WithdrawController.to.utr = data.transactionId.toString();
                                                                              WithdrawController.to.gatewayName = data.currency.toString();
                                                                              WithdrawController.to.selectedCurrency = data.gateway.toString();
                                                                              await WithdrawController.to.payoutPreview(
                                                                                utr:
                                                                                    data.transactionId.toString(),
                                                                              );
                                                                              await WithdrawController.to.filterData();
                                                                              if (WithdrawController.to.gatewayName ==
                                                                                  "Flutterwave") {
                                                                                Get.toNamed(
                                                                                  RoutesName.flutterWaveWithdrawScreen,
                                                                                );
                                                                              } else {
                                                                                if (WithdrawController.to.gatewayName ==
                                                                                    "Paystack") {
                                                                                  WithdrawController.to.getBankFromCurrency(
                                                                                    currencyCode:
                                                                                        data.currency.toString(),
                                                                                  );
                                                                                }
                                                                                Get.toNamed(
                                                                                  RoutesName.withdrawPreviewScreen,
                                                                                );
                                                                              }
                                                                            },
                                                                    text:
                                                                        "Confirm",
                                                                  );
                                                                },
                                                              ),
                                                          ],
                                                        ),
                                                        Align(
                                                          alignment:
                                                              Alignment
                                                                  .centerRight,
                                                          child: Text(
                                                            "${data.amount.toString()} ${data.currency.toString()}",
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: t.bodyMedium,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                margin: EdgeInsets.only(
                                                  top: 15.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color:
                                                          Get.isDarkMode
                                                              ? AppColors
                                                                  .black70
                                                              : AppColors
                                                                  .black20,
                                                      width: .2,
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
                                );
                              },
                            ),
                        if (withdrawHistoryController.isLoadMore == true)
                          Padding(
                            padding: EdgeInsets.only(top: 10.h, bottom: 20.h),
                            child: Helpers.appLoader(),
                          ),
                        VSpace(20.h),
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

  buildDialog(BuildContext context, {required void Function()? onTap}) {
    appDialog(
      context: context,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Confirmation", style: context.t.bodyLarge),
          InkResponse(
            onTap: () {
              Get.back();
            },
            child: Container(
              padding: EdgeInsets.all(7.h),
              decoration: BoxDecoration(
                color: AppThemes.getFillColor(),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14.h,
                color:
                    Get.isDarkMode
                        ? AppColors.whiteColor
                        : AppColors.blackColor,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Do you want to cancel this request?",
            style: context.t.bodyMedium,
          ),
          VSpace(40.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                buttonWidth: 90.w,
                buttonHeight: 35.h,
                bgColor: Colors.transparent,
                border: Border.all(color: AppColors.mainColor),
                style: context.t.bodyMedium,
                onTap: () {
                  Get.back();
                },
                text: "Close",
              ),
              HSpace(10.w),

              AppButton(
                loaderSize: 20.h,
                isLoading: false,
                buttonWidth: 110.w,
                buttonHeight: 35.h,
                onTap: onTap,
                text: "Confirm",
                style: context.t.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildBtn(
    WithdrawController withdrawCtrl,
    TextTheme t, {
    required String text,
    required void Function()? onTap,
    bool? isCancelColor = false,
    bool? isLoading = false,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        borderRadius: BorderRadius.circular(4.r),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 9.w),
          decoration: BoxDecoration(
            color:
                Get.isDarkMode
                    ? isCancelColor == true
                        ? AppColors.redColor.withValues(alpha: .1)
                        : AppColors.darkCardColor
                    : isCancelColor == true
                    ? AppColors.redColor.withValues(alpha: .1)
                    : AppColors.sliderInActiveColor,
            borderRadius: BorderRadius.circular(4.r),
          ),
          child:
              isLoading == true
                  ? SizedBox(
                    height: 18.h,
                    width: 18.h,
                    child: Helpers.appLoader(),
                  )
                  : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$text",
                        style: t.bodySmall?.copyWith(
                          fontSize: 14.sp,
                          color:
                              Get.isDarkMode
                                  ? AppColors.whiteColor
                                  : AppColors.blackColor,
                        ),
                      ),
                      HSpace(5.w),
                      Padding(
                        padding: EdgeInsets.only(top: 3.h),
                        child: Image.asset(
                          "$rootImageDir/confirm_arrow.png",
                          color: AppThemes.getIconBlackColor(),
                          height: 12.h,
                          width: 12.h,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  CustomAppBar buildAppbar(
    storedLanguage,
    BuildContext context,
    WithdrawHistoryController withdrawHistoryController,
  ) {
    return CustomAppBar(
      title: storedLanguage['Withdraw History'] ?? "Withdraw History",
      actions: [
        InkResponse(
          onTap: () {
            searchDialog(
              context: context,
              children: [
                CustomTextField(
                  hintext: "Transaction ID",
                  controller: withdrawHistoryController.utrEditingCtrlr,
                  contentPadding: EdgeInsets.only(left: 20.w),
                ),
                VSpace(24.h),
                CustomTextField(
                  hintext: "Email",
                  controller: withdrawHistoryController.emailEditingCtrlr,
                  contentPadding: EdgeInsets.only(left: 20.w),
                ),
                VSpace(24.h),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    InkWell(
                      onTap: () async {
                        /// SHOW DATE PICKER
                        await showDatePicker(
                          context: context,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.dark(
                                  surface:
                                      Get.isDarkMode
                                          ? AppColors.darkCardColor
                                          : AppColors.paragraphColor,
                                  onPrimary: AppColors.whiteColor,
                                ),
                                textButtonTheme: TextButtonThemeData(
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
                          firstDate: DateTime(2000),
                          lastDate: DateTime(DateTime.now().year.toInt() + 1),
                        ).then((value) {
                          if (value != null) {
                            withdrawHistoryController
                                .dateTimeEditingCtrlr
                                .text = DateFormat('yyyy-MM-dd').format(value);
                          }
                        });
                      },
                      child: IgnorePointer(
                        ignoring: true,
                        child: CustomTextField(
                          hintext: "Date",
                          controller:
                              withdrawHistoryController.dateTimeEditingCtrlr,
                          contentPadding: EdgeInsets.only(left: 20.w),
                        ),
                      ),
                    ),
                    InkResponse(
                      onTap: () {
                        withdrawHistoryController.dateTimeEditingCtrlr.clear();
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.h),
                        margin: EdgeInsets.only(right: 10.w),
                        decoration: BoxDecoration(
                          color: AppThemes.getFillColor(),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14.h,
                          color: AppThemes.getIconBlackColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                VSpace(28.h),
                AppButton(
                  text: "Search Now",
                  onTap: () async {
                    withdrawHistoryController.resetDataAfterSearching(
                      isFromOnRefreshIndicator: true,
                    );
                    Get.back();
                    await withdrawHistoryController.getRequestList(
                      page: 1,
                      email: withdrawHistoryController.emailEditingCtrlr.text,
                      created_at:
                          withdrawHistoryController.dateTimeEditingCtrlr.text,
                      utr: withdrawHistoryController.utrEditingCtrlr.text,
                    );
                  },
                ),
              ],
            );
          },
          child: Container(
            width: 34.h,
            height: 34.h,
            padding: EdgeInsets.all(10.5.h),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? AppColors.darkBgColor : AppColors.black5,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: AppColors.mainColor, width: .2),
            ),
            child: Image.asset(
              "$rootImageDir/filter_3.png",
              height: 32.h,
              width: 32.h,
              color:
                  Get.isDarkMode ? AppColors.whiteColor : AppColors.blackColor,
              fit: BoxFit.fitHeight,
            ),
          ),
        ),
        HSpace(20.w),
      ],
    );
  }
}

String checkStatus(String data) {
  switch (data) {
    case "Pending":
      return "$rootImageDir/pending.png";
    case "Generated":
      return "$rootImageDir/review.png";
    case "Payout Done":
      return "$rootImageDir/approved.png";
    case "Canceled":
      return "$rootImageDir/close.png";
    default:
      return "$rootImageDir/unknown.png";
  }
}

dynamic checkBgColor(String data) {
  switch (data) {
    case "Pending":
      return AppColors.pendingColor.withValues(alpha: .1);
    case "Generated":
      return AppColors.euroColor.withValues(alpha: .1);
    case "Payout Done":
      return AppColors.greenColor.withValues(alpha: .1);
    case "Canceled":
      return AppColors.redColor.withValues(alpha: .1);
    default:
      return AppColors.mainColor.withValues(alpha: .1);
  }
}

dynamic checkIconColor(String data) {
  switch (data) {
    case "Pending":
      return AppColors.pendingColor;
    case "Generated":
      return AppColors.euroColor;
    case "Payout Done":
      return AppColors.greenColor;
    case "Canceled":
      return AppColors.redColor;
    default:
      return AppColors.mainColor;
  }
}
