import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:paysecure/data/source/errors/check_api_status.dart';
import '../data/repositories/notification_repo.dart';
import '../routes/routes_name.dart';
import '../utils/services/localstorage/hive.dart';
import '../utils/services/localstorage/keys.dart';
import '../controllers/udhar_controller.dart';
import 'notification_service.dart';

class PushNotificationController extends GetxController {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  dynamic data;
  RxBool isSeen = true.obs;
  Future<dynamic> getPushNotificationConfig() async {
    _isLoading = true;
    update();
    http.Response res = await NotificationRepo.getPusherConfig();

    if (res.statusCode == 200) {
      _isLoading = false;
      data = jsonDecode(res.body);
      update();
      if (data['status'] == "success") {
        HiveHelp.write(Keys.channelName, data['message']['channel']);
        PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
        try {
          await pusher.init(
            apiKey: data['message']['apiKey'],
            cluster: data['message']['cluster'],
            onConnectionStateChange: onConnectionStateChange,
            onSubscriptionSucceeded: onSubscriptionSucceeded,
            onEvent: onEvent,
            onSubscriptionError: onSubscriptionError,
            onMemberAdded: onMemberAdded,
            onMemberRemoved: onMemberRemoved,
          );
          await pusher.subscribe(channelName: data['message']['channel']);
          await pusher.connect();
        } catch (e) {
          print("ERROR====================================: $e");
        }

        update();
      } else {
        ApiStatus.checkStatus(data['status'], data['message']);
      }
    } else {
      _isLoading = false;
      update();
    }
  }

  void onEvent(PusherEvent event) async {
    if (kDebugMode) {
      print("onEvent: ${event.data}");
    }
    // Parse the JSON response
    Map<String, dynamic> eventData = json.decode(event.data);
    Map<String, dynamic> message = eventData['message'];
    String text =
        message['description']['text'].toString().replaceAll("\n", " ");
    String formattedDate = DateFormat.yMMMMd().add_jm().format(DateTime.now());

    // Show the response in the flutter_local_notification
    LocalNotificationService().showNotification(
      id: Random().nextInt(99),
      title: text,
      body: formattedDate,
    );

    var storedData = await HiveHelp.read(data['message']['channel']);
    List<Map<dynamic, dynamic>> notificationList =
        storedData != null ? List<Map<dynamic, dynamic>>.from(storedData) : [];
    notificationList.insert(0, {
      'text': text.trim(),
      'date': formattedDate,
    });

    HiveHelp.write(data['message']['channel'], notificationList);
    HiveHelp.write(Keys.isNotificationSeen, false);
    isSeen.value = HiveHelp.read(Keys.isNotificationSeen);

    // Realtime Udhar Sync Trigger
    if (Get.isRegistered<UdharController>()) {
      final udharCtrl = Get.find<UdharController>();
      udharCtrl.fetchUsers();
      if (udharCtrl.selectedUser != null) {
        final custId = udharCtrl.selectedUser!['id']?.toString() ?? '';
        if (custId.isNotEmpty) {
          udharCtrl.fetchCustomerLedger(custId);
        }
      }
    }

    update();
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    debugPrint("onSubscriptionSucceeded: $channelName data: ${data}");
  }

  void onSubscriptionError(String message, dynamic e) {
    debugPrint("onSubscriptionError: $message Exception: $e");
  }

  void onMemberAdded(String channelName, PusherMember member) {
    debugPrint("onMemberAdded: $channelName member: $member");
  }

  void onMemberRemoved(String channelName, PusherMember member) {
    debugPrint("onMemberRemoved: $channelName member: $member");
  }

  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    debugPrint("Connection: $currentState");
  }

  clearList() {
    var channelName = HiveHelp.read(Keys.channelName);
    HiveHelp.remove(channelName);
    update();
  }

  isNotiSeen() {
    HiveHelp.write(Keys.isNotificationSeen, true);
    isSeen.value = HiveHelp.read(Keys.isNotificationSeen);
    Get.toNamed(RoutesName.notificationScreen);
    update();
  }
}
