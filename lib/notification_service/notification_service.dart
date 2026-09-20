import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../routes/routes_name.dart';
import '../utils/services/localstorage/hive.dart';
import '../utils/services/localstorage/keys.dart';
import 'notification_controller.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('flutter_logo');

    if (!kIsWeb) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    var initializationSettingsIOS = const DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    try {
      await notificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse:
              (NotificationResponse notificationResponse) async {
        HiveHelp.write(Keys.isNotificationSeen, true);
        Get.put(PushNotificationController()).isSeen.value =
            HiveHelp.read(Keys.isNotificationSeen);
        Get.toNamed(RoutesName.notificationScreen);
      });
    } catch (e) {
      debugPrint("LocalNotificationService initialize error: $e");
    }
  }

  Future<bool?> requestPermissions() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return await notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    return null;
  }

  notificationDetails() => const NotificationDetails(
      android: AndroidNotificationDetails('channelId', 'channelName',
          importance: Importance.max),
      iOS: DarwinNotificationDetails());

  Future showNotification(
          {required int id,
          required String title,
          required String body}) async =>
      notificationsPlugin.show(id, title, body, await notificationDetails());
}
