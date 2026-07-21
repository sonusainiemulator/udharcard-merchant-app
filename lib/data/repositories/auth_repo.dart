import 'package:http/http.dart' as http;
import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class AuthRepo {
  static Future<http.Response> register(
          {required Map<String, dynamic> data}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.registerUrl, fields: data);

  static Future<http.Response> login(
          {required Map<String, dynamic> data}) async =>
      await ApiClient.post(ENDPOINT_URL: AppConstants.loginUrl, fields: data);

  static Future<http.Response> forgotPass(
          {required Map<String, dynamic> data}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.forgotPassUrl, fields: data);

  static Future<http.Response> getCode(
          {required Map<String, dynamic> data}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.forgotPassGetCodeUrl, fields: data);

  static Future<http.Response> updatePass(
          {required Map<String, dynamic> data}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.updatePassUrl, fields: data);
}
