import 'package:http/http.dart' as http;
import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class SupportTicketRepo {
  static Future<http.Response> getSupportTicketList(
          {required int page}) async =>
      await ApiClient.get(
          ENDPOINT_URL: AppConstants.supportTicketListUrl + "?page=$page");

  static Future<http.Response> getSupportTicketView(
          {required String ticket}) async =>
      await ApiClient.get(
          ENDPOINT_URL: AppConstants.supportTicketViewUrl + "/$ticket");

  static Future<http.Response> createSupportTicket(
          {Map<String, String>? fields,
          Iterable<http.MultipartFile>? fileList}) async =>
      await ApiClient.postMultipart(
          ENDPOINT_URL: AppConstants.supportTicketCreateUrl,
          fields: fields,
          fileList: fileList);

  static Future<http.Response> replySupportTicket(
          {Map<String, String>? fields,
          Iterable<http.MultipartFile>? fileList}) async =>
      await ApiClient.postMultipart(
          ENDPOINT_URL: AppConstants.supportTicketReplyUrl,
          fields: fields,
          fileList: fileList);

  static Future<http.Response> closeSupportTicket({required String id}) async =>
      await ApiClient.patch(
          ENDPOINT_URL: AppConstants.supportTicketCloseUrl + "/$id");
}
