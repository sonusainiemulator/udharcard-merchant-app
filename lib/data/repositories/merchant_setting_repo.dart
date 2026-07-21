import 'package:http/http.dart' as http;
import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class MerchantSettingRepo {

  static Future<http.Response> getMerchantSetting() async =>
      await ApiClient.get(ENDPOINT_URL: AppConstants.merchatSettingUrl);

  static Future<http.Response> merchatSettingUpdate({
    required Map<String, String> data,
    Iterable<http.MultipartFile>? fileList,
  }) async => await ApiClient.postMultipart(
    ENDPOINT_URL: AppConstants.merchatSettingUpdate,
    fields: data,
    fileList: fileList,
  );
}
