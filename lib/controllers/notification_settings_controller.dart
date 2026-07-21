import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../data/models/notification_settings_model.dart' as notification;
import '../data/repositories/notification_settings_repo.dart';
import '../data/source/errors/check_api_status.dart';
import '../utils/services/helpers.dart';

class NotificationSettingsController extends GetxController {
  static NotificationSettingsController get to =>
      Get.find<NotificationSettingsController>();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool isCollapsed = false;
  int collapsedIndex = -1;
  List<String> list = [
    "Email",
    "SMS",
    "Push",
    "In App",
  ];

  @override
  void onInit() {
    super.onInit();
    getNotificationSettings();
  }

  // These data are for posting in notificationPermission API
  List<dynamic> emailKey = [];
  List<dynamic> smsKey = [];
  List<dynamic> pushKey = [];
  List<dynamic> inAppKey = [];

  Future notificationPermission({Map<String, dynamic>? fields}) async {
    _isLoading = true;
    update();
    try {
      http.Response response =
          await NotificationSettingsRepo.postNotificationSettings(
              fields: fields);
      _isLoading = false;
      update();
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['status'] == 'success') {
          getNotificationSettings(isFromPermissionApi: true);
          update();
        }
      } else {
        Helpers.showSnackBar(msg: '${data['message']}');
      }
    } catch (e) {
      _isLoading = false;
      update();
      Helpers.showSnackBar(msg: '$e');
    }
  }

  bool isGettingInfo = false;
  List<notification.Notification> notificationSettingsList = [];
  List<notification.UserHasPermission> notificationPermissionList = [];
  Future getNotificationSettings({bool? isFromPermissionApi = false}) async {
    if (isFromPermissionApi == false) {
      isGettingInfo = true;
    }
    update();

    http.Response response =
        await NotificationSettingsRepo.getNotificationSettings();

    if (isFromPermissionApi == false) {
      isGettingInfo = false;
    }

    notificationSettingsList = [];
    notificationPermissionList = [];

    emailKey = [];
    smsKey = [];
    pushKey = [];
    inAppKey = [];
    update();

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        notificationSettingsList.addAll(
            notification.NotificationSettingsModel.fromJson(data)
                .message!
                .notification!);
        if (data['message']['userHasPermission'] != null)
          notificationPermissionList.add(
              notification.NotificationSettingsModel.fromJson(data)
                  .message!
                  .userHasPermission!);
        if (notificationPermissionList.isNotEmpty) {
          if (notificationPermissionList[0].templateEmailKey != null &&
              notificationPermissionList[0].templateSmsKey != null &&
              notificationPermissionList[0].templatePushKey != null &&
              notificationPermissionList[0].templateInAppKey != null) {
            emailKey = [...?notificationPermissionList[0].templateEmailKey];
            smsKey = [...?notificationPermissionList[0].templateSmsKey];
            pushKey = [...?notificationPermissionList[0].templatePushKey];
            inAppKey = [...?notificationPermissionList[0].templateInAppKey];
          }
        }
        update();
      } else {
        ApiStatus.checkStatus(data['status'], data['message']);
      }
    } else {
      notificationSettingsList = [];
    }
  }
}
