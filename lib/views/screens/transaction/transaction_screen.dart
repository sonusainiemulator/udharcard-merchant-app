import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:paysecure/controllers/bindings/controller_index.dart';
import '../../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../themes/themes.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/appDialog.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/search_dialog.dart';
import '../../widgets/spacing.dart';
import '../home/home_screen.dart';

class TransactionScreen extends StatelessWidget {
  final bool? isFromHomePage;
  final bool? isFromWallet;
  const TransactionScreen({
    super.key,
    this.isFromHomePage = false,
    this.isFromWallet = false,
  });

  @override
  Widget build(BuildContext context) {
    TextTheme t = Theme.of(context).textTheme;
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<TransactionController>(
      builder: (transactionCtrl) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            Get.back();
          },
          child: Scaffold(
            appBar: buildAppbar(
              storedLanguage,
              context,
              transactionCtrl,
              isFromHomePage,
            ),
            body: RefreshIndicator(
              color: AppColors.mainColor,
              onRefresh: () async {
                transactionCtrl.transactionIdEditingCtrlr.clear();
                transactionCtrl.dateTimeEditingCtrlr.clear();
                transactionCtrl.resetDataAfterSearching(
                  isFromOnRefreshIndicator: true,
                );
                await transactionCtrl.getTransactionList(
                  page: 1,
                  created_at: "",
                  utr: "",
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: transactionCtrl.scrollController,
                child: Padding(
                  padding: Dimensions.kDefaultPadding,
                  child: Column(
                    children: [
                      VSpace(20.h),
                      transactionCtrl.isLoading
                          ? buildTransactionLoader(
                            itemCount: 20,
                            isReverseColor: true,
                          )
                          : transactionCtrl.transactionList.isEmpty
                          ? Helpers.notFound()
                          : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: transactionCtrl.transactionList.length,
                            itemBuilder: (context, i) {
                              var data = transactionCtrl.transactionList[i];
                              return InkWell(
                                borderRadius: Dimensions.kBorderRadius,
                                onTap: () {
                                  appDialog(
                                    context: context,
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
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
                                        Image.asset(
                                          "$rootImageDir/done.png",
                                          height: 48.h,
                                          width: 48.h,
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
                                                                  .blackColor,
                                                    ),
                                                  ),
                                                ),
                                                Center(
                                                  child: Text(
                                                    data.transactionId ?? '',
                                                    textAlign: TextAlign.center,
                                                    style: t.bodySmall,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (data.status != null) ...[
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
                                            style: t.bodySmall,
                                          ),
                                        ],
                                        VSpace(12.h),
                                        Text(
                                          storedLanguage['Amount'] ?? "Amount",
                                          style: t.bodyMedium?.copyWith(
                                            color:
                                                Get.isDarkMode
                                                    ? AppColors.whiteColor
                                                    : AppColors.blackColor,
                                          ),
                                        ),
                                        Text(
                                          data.amount.toString() +
                                              " ${data.currency.toString().replaceAll("null", "")}",
                                          style: t.bodySmall,
                                        ),
                                        VSpace(12.h),
                                        Text(
                                          storedLanguage['Charge'] ?? "Charge",
                                          style: t.bodyMedium?.copyWith(
                                            color:
                                                Get.isDarkMode
                                                    ? AppColors.whiteColor
                                                    : AppColors.blackColor,
                                          ),
                                        ),
                                        Text(
                                          data.charge.toString() +
                                              " ${data.currency}",
                                          style: t.bodySmall?.copyWith(
                                            color: AppColors.redColor,
                                          ),
                                        ),
                                        VSpace(12.h),

                                        Text(
                                          storedLanguage['Remarks'] ??
                                              "Remarks",
                                          style: t.bodyMedium?.copyWith(
                                            color:
                                                Get.isDarkMode
                                                    ? AppColors.whiteColor
                                                    : AppColors.blackColor,
                                          ),
                                        ),
                                        Text(
                                          data.remarks == null
                                              ? "-"
                                              : data.remarks.toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.bodySmall,
                                        ),
                                        VSpace(12.h),
                                      ],
                                    ),
                                  );
                                },
                                child: Ink(
                                  width: double.maxFinite,
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 45.h,
                                        height: 45.h,
                                        padding: EdgeInsets.all(12.h),
                                        decoration: BoxDecoration(
                                          color: AppColors.greenColor
                                              .withValues(alpha: .1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.asset(
                                          "$rootImageDir/approved.png",
                                          color: AppColors.greenColor,
                                        ),
                                      ),
                                      HSpace(12.w),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 14,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        data.remarks.toString(),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.fade,
                                                        style: t.bodyMedium,
                                                      ),
                                                      VSpace(3.h),
                                                      Text(
                                                        data.createdTime
                                                            .toString(),

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
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                      data.type +
                                                          "${data.amount.toString()} ${data.currency.toString().replaceAll("null", "")}",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: t.bodyMedium?.copyWith(
                                                        color:
                                                            data.type == "+"
                                                                ? AppColors
                                                                    .greenColor
                                                                : AppColors
                                                                    .redColor,
                                                      ),
                                                    ),
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
                                                            ? AppColors.black70
                                                            : AppColors.black20,
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
                      if (transactionCtrl.isLoadMore == true)
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
          ),
        );
      },
    );
  }

  CustomAppBar buildAppbar(
    storedLanguage,
    BuildContext context,
    TransactionController transactionCtrl,
    isFromHomePage,
  ) {
    return CustomAppBar(
      title: storedLanguage['Transaction'] ?? "Transaction",
      leading: BottomNavController.to.selectedIndex == 1 ? SizedBox() : null,
      actions: [
        InkResponse(
          onTap: () {
            searchDialog(
              context: context,
              children: [
                CustomTextField(
                  hintext: "Transaction ID",
                  controller: transactionCtrl.transactionIdEditingCtrlr,
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
                            transactionCtrl
                                .dateTimeEditingCtrlr
                                .text = DateFormat('yyyy-MM-dd').format(value);
                          }
                        });
                      },
                      child: IgnorePointer(
                        ignoring: true,
                        child: CustomTextField(
                          hintext: "Date",
                          controller: transactionCtrl.dateTimeEditingCtrlr,
                          contentPadding: EdgeInsets.only(left: 20.w),
                        ),
                      ),
                    ),
                    InkResponse(
                      onTap: () {
                        transactionCtrl.dateTimeEditingCtrlr.clear();
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
                    transactionCtrl.resetDataAfterSearching(
                      isFromOnRefreshIndicator: true,
                    );
                    Get.back();
                    await transactionCtrl.getTransactionList(
                      page: 1,

                      created_at: transactionCtrl.dateTimeEditingCtrlr.text,
                      utr: transactionCtrl.transactionIdEditingCtrlr.text,
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
