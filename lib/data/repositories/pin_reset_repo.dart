import 'package:http/http.dart' as http;
import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class PinResetRepo {
  static Future<http.Response> getPinReset() async =>
      await ApiClient.get(ENDPOINT_URL: AppConstants.pinReset);

  static Future<http.Response> pinReset({
    required Map<String, dynamic> data,
  }) async =>
      await ApiClient.post(ENDPOINT_URL: AppConstants.pinReset, fields: data);
}
