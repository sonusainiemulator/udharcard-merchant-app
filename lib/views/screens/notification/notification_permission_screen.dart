import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/dimensions.dart';
import '../../../controllers/notification_settings_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/helpers.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';
import '../../widgets/text_theme_extension.dart';
import '../../../config/app_colors.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<NotificationSettingsController>(
        builder: (notificationCtrl) {
      return Scaffold(
        appBar: CustomAppBar(
            title: storedLanguage['Notification Permission'] ??
                "Notification Permission"),
        body: RefreshIndicator(
          color: AppColors.mainColor,
          onRefresh: () async {
            notificationCtrl.getNotificationSettings();
          },
          child: Padding(
            padding: Dimensions.kDefaultPadding,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VSpace(30.h),
                  notificationCtrl.isGettingInfo
                      ? Helpers.appLoader()
                      : notificationCtrl.notificationSettingsList.isEmpty
                          ? Helpers.notFound(text: "No notifications found")
                          : ListView.builder(
                              itemCount: notificationCtrl
                                  .notificationSettingsList.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, i) {
                                var data = notificationCtrl
                                    .notificationSettingsList[i];

                                return Padding(
                                  padding: EdgeInsets.only(bottom: 10.h),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: AppThemes.getFillColor(),
                                      borderRadius: Dimensions.kBorderRadius,
                                    ),
                                    child: Theme(
                                      data: ThemeData().copyWith(
                                        dividerColor: Colors.transparent,
                                        listTileTheme:
                                            ListTileTheme.of(context).copyWith(
                                          dense: true,
                                        ),
                                      ),
                                      child: ExpansionTile(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                Dimensions.kBorderRadius),
                                        textColor: AppColors.mainColor,
                                        iconColor:
                                            AppThemes.getIconBlackColor(),
                                        collapsedIconColor: Get.isDarkMode
                                            ? AppColors.whiteColor
                                            : AppColors.black50,
                                        onExpansionChanged: (v) {
                                          notificationCtrl.isCollapsed = v;
                                          notificationCtrl.collapsedIndex = i;
                                          notificationCtrl.update();
                                        },
                                        title: Text(
                                          data.name ?? "",
                                          style: context.t.displayMedium?.copyWith(
                                              fontWeight: notificationCtrl
                                                              .isCollapsed ==
                                                          true &&
                                                      notificationCtrl
                                                              .collapsedIndex ==
                                                          i
                                                  ? FontWeight.w500
                                                  : FontWeight.w400),
                                        ),
                                        children: <Widget>[
                                          newMethod(
                                              context: context,
                                              activeTrackColor:
                                                  data.status!.mail == "0"
                                                      ? AppColors.mainColor
                                                          .withValues(alpha: .4)
                                                      : AppColors.mainColor,
                                              inactiveThumbColor:
                                                  data.status!.mail == "0"
                                                      ? Colors.grey
                                                      : AppColors.whiteColor,
                                              subText: notificationCtrl.list[0],
                                              switchVal: notificationCtrl
                                                  .emailKey
                                                  .any((element) =>
                                                      data.key == element),
                                              onChanged: data.status!.mail ==
                                                      "0"
                                                  ? null
                                                  : (v) async {
                                                      bool isExist =
                                                          notificationCtrl
                                                              .emailKey
                                                              .any((element) =>
                                                                  element ==
                                                                  data.key);
                                                      if (isExist) {
                                                        notificationCtrl
                                                            .emailKey
                                                            .remove(data.key);
                                                        await notificationCtrl
                                                            .notificationPermission(
                                                                fields: {
                                                              "email_key": notificationCtrl
                                                                      .emailKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .emailKey,
                                                              "sms_key": notificationCtrl
                                                                      .smsKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .smsKey,
                                                              "push_key": notificationCtrl
                                                                      .pushKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .pushKey,
                                                              "in_app_key": notificationCtrl
                                                                      .inAppKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .inAppKey,
                                                            });
                                                      } else {
                                                        notificationCtrl
                                                            .emailKey
                                                            .add(data.key);
                                                        await notificationCtrl
                                                            .notificationPermission(
                                                                fields: {
                                                              "email_key": notificationCtrl
                                                                      .emailKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .emailKey,
                                                              "sms_key": notificationCtrl
                                                                      .smsKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .smsKey,
                                                              "push_key": notificationCtrl
                                                                      .pushKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .pushKey,
                                                              "in_app_key": notificationCtrl
                                                                      .inAppKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .inAppKey,
                                                            });
                                                      }
                                                      notificationCtrl.update();
                                                    }),
                                          newMethod(
                                              context: context,
                                              activeTrackColor:
                                                  data.status!.sms == "0"
                                                      ? AppColors.mainColor
                                                          .withValues(alpha: .4)
                                                      : AppColors.mainColor,
                                              inactiveThumbColor:
                                                  data.status!.sms == "0"
                                                      ? Colors.grey
                                                      : AppColors.whiteColor,
                                              subText: notificationCtrl.list[1],
                                              switchVal: notificationCtrl.smsKey
                                                  .any((element) =>
                                                      data.key == element),
                                              onChanged: data.status!.sms == "0"
                                                  ? null
                                                  : (v) async {
                                                      bool isExist =
                                                          notificationCtrl
                                                              .smsKey
                                                              .any((element) =>
                                                                  element ==
                                                                  data.key);
                                                      if (isExist) {
                                                        notificationCtrl.smsKey
                                                            .remove(data.key);
                                                        await notificationCtrl
                                                            .notificationPermission(
                                                                fields: {
                                                              "email_key": notificationCtrl
                                                                      .emailKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .emailKey,
                                                              "sms_key": notificationCtrl
                                                                      .smsKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .smsKey,
                                                              "push_key": notificationCtrl
                                                                      .pushKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .pushKey,
                                                              "in_app_key": notificationCtrl
                                                                      .inAppKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .inAppKey,
                                                            });
                                                      } else {
                                                        notificationCtrl.smsKey
                                                            .add(data.key);
                                                        await notificationCtrl
                                                            .notificationPermission(
                                                                fields: {
                                                              "email_key": notificationCtrl
                                                                      .emailKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .emailKey,
                                                              "sms_key": notificationCtrl
                                                                      .smsKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .smsKey,
                                                              "push_key": notificationCtrl
                                                                      .pushKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .pushKey,
                                                              "in_app_key": notificationCtrl
                                                                      .inAppKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .inAppKey,
                                                            });
                                                      }
                                                      notificationCtrl.update();
                                                    }),
                                          newMethod(
                                              context: context,
                                              activeTrackColor:
                                                  data.status!.push == "0"
                                                      ? AppColors.mainColor
                                                          .withValues(alpha: .4)
                                                      : AppColors.mainColor,
                                              inactiveThumbColor:
                                                  data.status!.push == "0"
                                                      ? Colors.grey
                                                      : AppColors.whiteColor,
                                              subText: notificationCtrl.list[2],
                                              switchVal: notificationCtrl
                                                  .pushKey
                                                  .any((element) =>
                                                      data.key == element),
                                              onChanged: data.status!.push ==
                                                      "0"
                                                  ? null
                                                  : (v) async {
                                                      bool isExist =
                                                          notificationCtrl
                                                              .pushKey
                                                              .any((element) =>
                                                                  element ==
                                                                  data.key);
                                                      if (isExist) {
                                                        notificationCtrl.pushKey
                                                            .remove(data.key);
                                                        await notificationCtrl
                                                            .notificationPermission(
                                                                fields: {
                                                              "email_key": notificationCtrl
                                                                      .emailKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .emailKey,
                                                              "sms_key": notificationCtrl
                                                                      .smsKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .smsKey,
                                                              "push_key": notificationCtrl
                                                                      .pushKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .pushKey,
                                                              "in_app_key": notificationCtrl
                                                                      .inAppKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .inAppKey,
                                                            });
                                                      } else {
                                                        notificationCtrl.pushKey
                                                            .add(data.key);
                                                        await notificationCtrl
                                                            .notificationPermission(
                                                                fields: {
                                                              "email_key": notificationCtrl
                                                                      .emailKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .emailKey,
                                                              "sms_key": notificationCtrl
                                                                      .smsKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .smsKey,
                                                              "push_key": notificationCtrl
                                                                      .pushKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .pushKey,
                                                              "in_app_key": notificationCtrl
                                                                      .inAppKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .inAppKey,
                                                            });
                                                      }
                                                      notificationCtrl.update();
                                                    }),
                                          newMethod(
                                              context: context,
                                              activeTrackColor: data
                                                              .status!.inApp ==
                                                          "0" &&
                                                      notificationCtrl.emailKey
                                                              .any((element) =>
                                                                  data.key ==
                                                                  element) ==
                                                          false
                                                  ? Colors.grey.shade300
                                                  : AppColors.mainColor,
                                              inactiveThumbColor:
                                                  data.status!.inApp == "0"
                                                      ? Colors.grey
                                                      : AppColors.whiteColor,
                                              subText: notificationCtrl.list[3],
                                              switchVal: notificationCtrl
                                                  .inAppKey
                                                  .any((element) =>
                                                      data.key == element),
                                              onChanged: data.status!.inApp ==
                                                      "0"
                                                  ? null
                                                  : (v) async {
                                                      bool isExist =
                                                          notificationCtrl
                                                              .inAppKey
                                                              .any((element) =>
                                                                  element ==
                                                                  data.key);
                                                      if (isExist) {
                                                        notificationCtrl
                                                            .inAppKey
                                                            .remove(data.key);
                                                        await notificationCtrl
                                                            .notificationPermission(
                                                                fields: {
                                                              "email_key": notificationCtrl
                                                                      .emailKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .emailKey,
                                                              "sms_key": notificationCtrl
                                                                      .smsKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .smsKey,
                                                              "push_key": notificationCtrl
                                                                      .pushKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .pushKey,
                                                              "in_app_key": notificationCtrl
                                                                      .inAppKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .inAppKey,
                                                            });
                                                      } else {
                                                        notificationCtrl
                                                            .inAppKey
                                                            .add(data.key);
                                                        await notificationCtrl
                                                            .notificationPermission(
                                                                fields: {
                                                              "email_key": notificationCtrl
                                                                      .emailKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .emailKey,
                                                              "sms_key": notificationCtrl
                                                                      .smsKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .smsKey,
                                                              "push_key": notificationCtrl
                                                                      .pushKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .pushKey,
                                                              "in_app_key": notificationCtrl
                                                                      .inAppKey
                                                                      .isEmpty
                                                                  ? [""]
                                                                  : notificationCtrl
                                                                      .inAppKey,
                                                            });
                                                      }
                                                      notificationCtrl.update();
                                                    }),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              })
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget newMethod(
      {required BuildContext context,
      required String subText,
      required bool switchVal,
      required Color activeTrackColor,
      required Color inactiveThumbColor,
      required void Function(bool)? onChanged}) {
    return Row(
      children: [
        HSpace(16),
        Text(subText,
            style: context.t.displayMedium?.copyWith(
                color: Get.isDarkMode
                    ? AppColors.black30
                    : AppColors.paragraphColor)),
        Spacer(),
        Transform.scale(
          scale: .7,
          child: Switch(
            activeTrackColor: activeTrackColor,
            inactiveTrackColor:
                Get.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            inactiveThumbColor: inactiveThumbColor,
            value: switchVal,
            onChanged: onChanged,
          ),
        ),
        HSpace(12),
      ],
    );
  }
}
