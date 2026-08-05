import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart' hide Response, MultipartFile;
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import '../../../../../controllers/app_controller.dart';
import '../../../../../utils/app_constants.dart';
import '../../../../../utils/services/localstorage/hive.dart';
import '../../../../../utils/services/localstorage/keys.dart';
import '../errors/api_error.dart';

class ApiClient {
  static final String _BASE_URL = AppConstants.baseUrl;
  static const int _TIMEOUT_DURATION = 30; // 30 seconds timeout for real-time calls

  static Map<String, String> _getHeaders({bool isFormUrlEncoded = true}) {
    final token = HiveHelp.read(Keys.token) ?? '';
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': isFormUrlEncoded
          ? 'application/x-www-form-urlencoded'
          : 'application/json',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      final userId = HiveHelp.read(Keys.userId) ?? '1';
      headers['X-Merchant-Id'] = userId.toString();
    }

    final merchantPhone = HiveHelp.read(Keys.userPhone);
    if (merchantPhone != null && merchantPhone.toString().trim().isNotEmpty) {
      headers['X-Merchant-Phone'] = merchantPhone.toString().trim();
    }

    return headers;
  }

  static Future<bool> _isOfflineNow() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult == ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  static Future<void> syncQueuedRequests() async {}

  static Future<void> _triggerInternetIssueNotice() async {
    if (await _isOfflineNow() && Get.isRegistered<AppController>()) {
      Get.find<AppController>().updateConnectionStatus(ConnectivityResult.none);
    }
  }

  static Future<http.Response> _request({
    required String method,
    required String ENDPOINT_URL,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool isFormUrlEncoded = true,
  }) async {
    Response? response;
    final Map<String, String> resolvedHeaders =
        headers ?? _getHeaders(isFormUrlEncoded: isFormUrlEncoded);

    // Check internet connection before making live API call
    if (await _isOfflineNow()) {
      await _triggerInternetIssueNotice();
      return http.Response(
        jsonEncode({
          'status': 'error',
          'message': 'Internet Connection Issue. Please check your network connection.',
        }),
        503,
        headers: const {'content-type': 'application/json'},
      );
    }

    try {
      final uri = Uri.parse(_BASE_URL + ENDPOINT_URL);
      final request = http.Request(method, uri);
      request.headers.addAll(resolvedHeaders);

      if (body != null) {
        if (resolvedHeaders['Content-Type']?.contains('application/x-www-form-urlencoded') ?? false) {
          request.bodyFields = body.map((key, value) => MapEntry(key, value?.toString() ?? ''));
        } else {
          request.body = json.encode(body);
        }
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: _TIMEOUT_DURATION),
      );
      response = await http.Response.fromStream(streamedResponse);
      return await ApiResponse.processResponse(response);
    } catch (e) {
      await _triggerInternetIssueNotice();
      return ApiResponse.handleException(
        e,
        response == null ? 503 : response.statusCode,
      );
    }
  }

  static Future<http.Response> get({required String ENDPOINT_URL}) =>
      _request(method: 'GET', ENDPOINT_URL: ENDPOINT_URL);

  static Future<http.Response> post({
    required String ENDPOINT_URL,
    Map<String, dynamic>? fields,
  }) => _request(method: 'POST', ENDPOINT_URL: ENDPOINT_URL, body: fields);

  static Future<http.Response> patch({
    required String ENDPOINT_URL,
    Map<String, dynamic>? fields,
  }) => _request(method: 'PATCH', ENDPOINT_URL: ENDPOINT_URL, body: fields);

  static Future<http.Response> put({
    required String ENDPOINT_URL,
    Map<String, dynamic>? fields,
  }) => _request(method: 'PUT', ENDPOINT_URL: ENDPOINT_URL, body: fields);

  static Future<http.Response> delete({required String ENDPOINT_URL}) =>
      _request(method: 'DELETE', ENDPOINT_URL: ENDPOINT_URL);

  static Future<http.Response> postMultipart({
    required String ENDPOINT_URL,
    Map<String, String>? fields,
    MultipartFile? files,
    Iterable<MultipartFile>? fileList,
  }) async {
    Response? response;
    if (await _isOfflineNow()) {
      _triggerInternetIssueNotice();
      return ApiResponse.handleException(
        http.ClientException(
          'Internet Connection Issue. Please check your network connection.',
        ),
        503,
      );
    }

    try {
      MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse(_BASE_URL + ENDPOINT_URL),
      );
      request.headers.addAll(_getHeaders());
      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        request.files.add(files);
      }

      if (fileList != null && fileList.isNotEmpty) {
        request.files.addAll(fileList);
      }

      http.StreamedResponse streamedResponse = await request.send().timeout(
        const Duration(seconds: _TIMEOUT_DURATION),
      );
      response = await http.Response.fromStream(streamedResponse);
      return await ApiResponse.processResponse(response);
    } catch (e) {
      _triggerInternetIssueNotice();
      return ApiResponse.handleException(
        e,
        response == null ? 503 : response.statusCode,
      );
    }
  }
}
