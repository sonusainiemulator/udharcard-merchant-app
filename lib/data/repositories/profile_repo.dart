import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class ProfileRepo {
  static Future<http.Response> getProfile() async =>
      await ApiClient.get(ENDPOINT_URL: AppConstants.profileUrl);

  static Future<http.Response> profileUpdate({
    required Map<String, String> data,
    MultipartFile? files,
  }) async {
    if (files == null) {
      return await ApiClient.post(
        ENDPOINT_URL: AppConstants.profileUrl,
        fields: data,
      );
    }
    return await ApiClient.postMultipart(
      ENDPOINT_URL: AppConstants.profileUrl,
      fields: data,
      files: files,
    );
  }

  static Future<http.Response> updateShopStatus({
    required bool isShopOnline,
    String? shopOpeningTime,
    String? shopClosingTime,
    String? shopClosedDays,
  }) async {
    final Map<String, dynamic> data = {
      'is_shop_online': isShopOnline ? '1' : '0',
    };
    if (shopOpeningTime != null) data['shop_opening_time'] = shopOpeningTime;
    if (shopClosingTime != null) data['shop_closing_time'] = shopClosingTime;
    if (shopClosedDays != null) data['shop_closed_days'] = shopClosedDays;

    return await ApiClient.post(
      ENDPOINT_URL: AppConstants.shopStatusUrl,
      fields: data,
    );
  }

  static Future<http.Response> profilePassUpdate(
          {required Map<String, dynamic> data}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.profilePassUpdateUrl, fields: data);

            static Future<http.Response> deleteAccount({required String code}) async =>
      await ApiClient.post(ENDPOINT_URL: AppConstants.deleteAccount,fields: {'code': code});
}
