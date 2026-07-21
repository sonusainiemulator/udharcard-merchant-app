import 'package:http/http.dart' as http;
import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class TransferRepo {
  static Future<http.Response> submitTransfer({
    required String emailOrPhone,
    required String amount,
  }) async {
    return await ApiClient.post(
      ENDPOINT_URL: AppConstants.transferMoneySubmitUrl,
      fields: {
        "email_or_phone": emailOrPhone,
        "amount": amount,
      },
    );
  }

  static Future<http.Response> getContactsList() async {
    return await ApiClient.get(
      ENDPOINT_URL: AppConstants.getContactsUrl,
    );
  }
}
