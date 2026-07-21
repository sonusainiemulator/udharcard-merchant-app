import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class VerificationRepo {
  static Future<http.Response> getVerificationList() async =>
      await ApiClient.get(ENDPOINT_URL: AppConstants.verificationUrl);

  static Future<http.Response> submitVerification(
          {required Iterable<MultipartFile>? fileList,

          required Map<String, String> fields}) async =>
      await ApiClient.postMultipart(
          ENDPOINT_URL: AppConstants.identityVerificationUrl,
          fields: fields,
          fileList: fileList);

  static Future<http.Response> getTwoFa() async =>
      await ApiClient.get(ENDPOINT_URL: AppConstants.twoFaSecurityUrl);

  static Future<http.Response> enableTwoFa(
          {Map<String, dynamic>? fields}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.twoFaSecurityEnableUrl, fields: fields);

  static Future<http.Response> disableTwoFa(
          {Map<String, dynamic>? fields}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.twoFaSecurityDisableUrl, fields: fields);

  static Future<http.Response> mailVerify({required String code}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.mailUrl, fields: {"code": code});

  static Future<http.Response> smsVerify({required String code}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.smsVerifyUrl, fields: {"code": code});

  static Future<http.Response> twoFaVerify({required String code}) async =>
      await ApiClient.post(
          ENDPOINT_URL: AppConstants.twoFaVerifyUrl, fields: {"code": code});

  static Future<http.Response> resendCode({required String type}) async =>
      await ApiClient.get(
          ENDPOINT_URL: AppConstants.resendCodeUrl + "?type=$type");
}
