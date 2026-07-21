import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../controllers/verification_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';
import 'identity_verification_screen.dart';

class VerificationListScreen extends StatelessWidget {
  final bool? isFromCheckStatus;
  const VerificationListScreen({super.key, this.isFromCheckStatus = false});

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    TextTheme t = Theme.of(context).textTheme;
    return GetBuilder<VerificationController>(builder: (verifyCtrl) {
      return Scaffold(
        appBar: CustomAppBar(
          title: storedLanguage['Identity Verification'] ??
              'Identity Verification',
        ),
        body: RefreshIndicator(
          color: AppColors.secondaryColor,
          onRefresh: () async {
            await verifyCtrl.getVerificationList();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: Dimensions.kDefaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VSpace(20.h),
                  if (verifyCtrl.isLoading == false &&
                      verifyCtrl.categoryNameList.isNotEmpty) ...[
                    for (var i in verifyCtrl.categoryNameList)
                      if (i.status != "1")
                        Column(
                          children: [
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 10.h),
                              padding: EdgeInsets.symmetric(
                                  vertical: 8.h, horizontal: 12.w),
                              decoration: BoxDecoration(
                                color: i.status.toString() == "0"
                                    ? AppColors.pendingColor
                                        .withValues(alpha: .1)
                                    : AppColors.redColor.withValues(alpha: .1),
                                borderRadius: Dimensions.kBorderRadius / 1.5,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info,
                                      color: i.status.toString() == "0"
                                          ? AppColors.pendingColor
                                              .withValues(alpha: .8)
                                          : AppColors.redColor
                                              .withValues(alpha: .8)),
                                  HSpace(8.w),
                                  Text(
                                    i.status.toString() == "0"
                                        ? i.categoryName + " is Pending"
                                        : i.status.toString() == "2"
                                            ? i.categoryName + " is Rejected"
                                            : i.categoryName + " is Required",
                                    style: t.bodySmall?.copyWith(
                                        color: i.status.toString() == "0"
                                            ? AppColors.pendingColor
                                            : AppColors.redColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    VSpace(20.h),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: AppThemes.getSliderInactiveColor(),
                    ),
                  ],
                  verifyCtrl.isLoading
                      ? Helpers.appLoader()
                      : verifyCtrl.categoryNameList.isEmpty
                          ? Helpers.notFound()
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: verifyCtrl.categoryNameList.length,
                              itemBuilder: (context, i) {
                                var data = verifyCtrl.categoryNameList[i];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: Dimensions.kBorderRadius / 2,
                                  ),
                                  onTap: () async {
                                    verifyCtrl.selectedCategoryName =
                                        data.categoryName;
                                    verifyCtrl.update();
                                    await verifyCtrl.filterData();
                                    Get.to(() => IdentityVerificationScreen(
                                        id: data.id.toString(),
                                        verifyStatus: data.status.toString(),
                                        verificationType: data.categoryName));
                                  },
                                  leading: Container(
                                      height: 36.h,
                                      width: 36.h,
                                      padding: EdgeInsets.all(8.h),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(18.r),
                                        color: AppThemes.getFillColor(),
                                      ),
                                      child: Image.asset(
                                        data.status.toString() == 'null'
                                            ? "$rootImageDir/required.png"
                                            : data.status.toString() == "2"
                                                ? "$rootImageDir/rejected.png"
                                                : data.status.toString() == "0"
                                                    ? "$rootImageDir/pending.png"
                                                    : "$rootImageDir/tick-mark.png",
                                        color: data.status.toString() == "0"
                                            ? AppColors.pendingColor
                                            : data.status.toString() == "2"
                                                ? AppColors.redColor
                                                : null,
                                      )),
                                  title: Text(data.categoryName,
                                      style: t.displayMedium),
                                  trailing: Container(
                                    height: 30.h,
                                    width: 30.h,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6.r),
                                      color: AppThemes.getFillColor(),
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16.h,
                                      color: AppThemes.getGreyColor(),
                                    ),
                                  ),
                                );
                              }),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
