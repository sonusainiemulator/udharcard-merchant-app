import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class WithdrawRepo {
  static Future<http.Response> getWithdrawHistoryList({
    required int page,
    required String transaction_id,
    required String email,
    required String created_at,
  }) async =>
      await ApiClient.get(
          ENDPOINT_URL: AppConstants.withdrawList +
              "?page=$page&trx_id=$transaction_id&email=$email&created_at=$created_at");

  static Future<http.Response> getPayouts() async =>
      await ApiClient.get(ENDPOINT_URL: AppConstants.payoutUrl);
      

  static Future<http.Response> getBankFromBank(
          {required String bankName}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.getBankFromBankUrl,
          fields: {"bankName": bankName});

  static Future<http.Response> getBankFromCurrency(
          {required String currencyCode}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.getBankFromCurrencyUrl,
          fields: {"currencyCode": currencyCode});

  static Future<http.Response> payoutConfirmSubmit(
          {required Iterable<MultipartFile>? fileList,
          required Map<String, String> fields}) async =>
      await ApiClient.postMultipart(
          ENDPOINT_URL: AppConstants.payoutConfirmSubmitUrl,
          fields: fields,
          fileList: fileList);

  static Future<http.Response> payoutRequest(
          {required Map<String, String> fields}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.payoutRequestUrl, fields: fields);

  static Future<http.Response> flutterwaveSubmit(
          {required Map<String, String> fields}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.flutterwaveSubmitUrl, fields: fields);

  static Future<http.Response> paystackSubmit(
          {required Map<String, String> fields}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.paystackSubmitUrl, fields: fields);

  static Future<http.Response> payoutPreview({required String utr}) async =>
      await ApiClient.get(
          ENDPOINT_URL: AppConstants.payoutConfirmPreviewUrl + "/$utr");
}
