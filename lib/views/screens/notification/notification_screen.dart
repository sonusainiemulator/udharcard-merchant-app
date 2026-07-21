import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import 'package:get/get.dart';
import '../../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../notification_service/notification_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/custom_appbar.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<PushNotificationController>(builder: (pushNotificationController) {
      var channelName = HiveHelp.read(Keys.channelName) ?? "";
      var storedData = HiveHelp.read(channelName);
      List<Map<dynamic, dynamic>> notificationList = storedData != null
          ? List<Map<dynamic, dynamic>>.from(storedData)
          : [];
      return Scaffold(
        appBar: buildAppBar(storedLanguage, notificationList, pushNotificationController, context),
        body: Padding(
          padding: Dimensions.kDefaultPadding,
          child: Column(
            children: [
              SizedBox(height: 20.h),
              Expanded(
                child: notificationList.isEmpty
                    ? Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              Get.isDarkMode
                                  ? "assets/images/no_notification_dark.png"
                                  : "assets/images/no_notification.png",
                              height: 258,
                              width: 226.w,
                            ),
                            SizedBox(
                              height: 40.h,
                            ),
                            Text(
                                storedLanguage['No Notifications Yet'] ??
                                    "No Notifications Yet",
                                style: context.t.bodyLarge),
                            SizedBox(
                              height: 12.h,
                            ),
                            Center(
                              child: Text(
                                  "You have no notification right now.\nCome back later",
                                  textAlign: TextAlign.center,
                                  style: context.t.displayMedium),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: notificationList.length,
                        itemBuilder: (context, index) {
                          var data = notificationList[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: Dismissible(
                              key: UniqueKey(),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                notificationList.removeAt(index);
                                HiveHelp.write(channelName, notificationList);
                                pushNotificationController.update();
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                color: AppColors.redColor,
                                padding: EdgeInsets.only(right: 20.w),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppThemes.getFillColor(),
                                  borderRadius: BorderRadius.circular(5.r),
                                ),
                                child: Column(
                                  children: [
                                    ListTile(
                                      onTap: () {},
                                      leading: Container(
                                        padding: EdgeInsets.all(8.h),
                                        height: 35.h,
                                        width: 35.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.mainColor,
                                        ),
                                        child: Image.asset(
                                          "$rootImageDir/notification_icon_new.png",
                                          color: AppColors.whiteColor,
                                        ),
                                      ),
                                      title: Text(
                                        data['text'],
                                        style: context.t.bodySmall,
                                      ),
                                      subtitle: Text(
                                        data['date'],
                                        style: context.t.bodySmall?.copyWith(
                                          fontSize: 12.sp,
                                          color: AppThemes.getGreyColor(),
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
            ],
          ),
        ),
      );
    });
  }

  CustomAppBar buildAppBar(storedLanguage, List<Map<dynamic, dynamic>> notificationList, PushNotificationController pushNotificationController, BuildContext context) {
    return CustomAppBar(
        title: storedLanguage['Notifications'] ?? "Notifications",
        actions: [
          notificationList.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    pushNotificationController.clearList();
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: 20.w,
                    ),
                    child: Container(
                      height: 25.h,
                      width: 80.w,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: Text(
                            storedLanguage['Clear All'] ?? "Clear All",
                            style: context.t.displayMedium
                                ?.copyWith(fontSize: 13.sp)),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      );
  }
}
