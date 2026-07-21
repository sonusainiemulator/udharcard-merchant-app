import 'package:http/http.dart' as http;
import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class NotificationSettingsRepo {
  static Future<http.Response> getNotificationSettings() async =>
      await ApiClient.get(ENDPOINT_URL: AppConstants.notificationSettingsUrl);

  static Future<http.Response> postNotificationSettings(
          {Map<String, dynamic>? fields}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.notificationPermissionUrl, fields: fields);
}
