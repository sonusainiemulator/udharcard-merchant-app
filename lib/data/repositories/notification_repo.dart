import 'package:http/http.dart' as http;
import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class NotificationRepo {
  static Future<http.Response> getPusherConfig() async =>
      await ApiClient.get(ENDPOINT_URL: AppConstants.pusherConfigUrl);
}
