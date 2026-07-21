import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import '../../../../../utils/app_constants.dart';
import '../../../../../utils/services/localstorage/hive.dart';
import '../../../../../utils/services/localstorage/keys.dart';
import '../errors/api_error.dart';

class ApiClient {
  static String _BASE_URL = AppConstants.baseUrl;
  static const int _TIMEOUT_DURATION = 35; // 35 seconds
  static const String _cachePrefix = 'api_cache_v1::';
  static const String _pendingQueueKey = 'pending_api_queue_v1';
  static bool _isSyncingQueue = false;

  static Map<String, String> _getHeaders() {
    final token = HiveHelp.read(Keys.token) ?? '';
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      final userId = HiveHelp.read(Keys.userId) ?? '1';
      headers['X-Merchant-Id'] = userId.toString();
    }
    return headers;
  }

  static Future<bool> _isOfflineNow() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.none;
  }

  static String _cacheKey({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) {
    final raw = jsonEncode({'m': method, 'e': endpoint, 'b': body ?? {}});
    return '$_cachePrefix${base64UrlEncode(utf8.encode(raw))}';
  }

  static void _cacheResponse({
    required String cacheKey,
    required http.Response response,
  }) {
    if (response.statusCode != 200) return;
    HiveHelp.write(cacheKey, {
      'statusCode': response.statusCode,
      'body': response.body,
      'headers': response.headers,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  static http.Response? _responseFromCache({
    required String method,
    required String endpoint,
    required String cacheKey,
  }) {
    final cached = HiveHelp.read(cacheKey);
    if (cached == null || cached is! Map) return null;
    final body = cached['body']?.toString() ?? '{}';
    final statusCode = cached['statusCode'] is int ? cached['statusCode'] : 200;
    final headers =
        cached['headers'] is Map
            ? Map<String, String>.from(cached['headers'])
            : <String, String>{'content-type': 'application/json'};

    return http.Response(
      body,
      statusCode,
      headers: headers,
      request: http.Request(method, Uri.parse(_BASE_URL + endpoint)),
    );
  }

  static void _queueWriteRequest({
    required String method,
    required String endpoint,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) {
    final List<dynamic> queue = List<dynamic>.from(
      HiveHelp.read(_pendingQueueKey) ?? [],
    );

    queue.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'method': method,
      'endpoint': endpoint,
      'headers': headers,
      'body': body ?? {},
      'createdAt': DateTime.now().toIso8601String(),
    });

    HiveHelp.write(_pendingQueueKey, queue);
  }

  static http.Response _offlineQueuedResponse({
    required String method,
    required String endpoint,
  }) {
    return http.Response(
      jsonEncode({
        'status': 'success',
        'queued': true,
        'offline': true,
        'message':
            'Saved offline. It will sync automatically when internet is available.',
        'meta': {'method': method, 'endpoint': endpoint},
      }),
      200,
      headers: const {'content-type': 'application/json'},
      request: http.Request(method, Uri.parse(_BASE_URL + endpoint)),
    );
  }

  static bool _shouldDropFromQueue(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return true;
    if (statusCode == 408 || statusCode == 429) return false;
    if (statusCode >= 500) return false;
    if (statusCode >= 400 && statusCode < 500) return true;
    return false;
  }

  static Future<void> syncQueuedRequests() async {
    if (_isSyncingQueue) return;
    if (await _isOfflineNow()) return;

    List<dynamic> queue = List<dynamic>.from(
      HiveHelp.read(_pendingQueueKey) ?? [],
    );
    if (queue.isEmpty) return;

    _isSyncingQueue = true;
    try {
      final List<dynamic> pending = [];

      for (final item in queue) {
        if (item is! Map) {
          continue;
        }

        try {
          final method = (item['method'] ?? 'POST').toString();
          final endpoint = (item['endpoint'] ?? '').toString();
          if (endpoint.isEmpty) {
            continue;
          }

          final uri = Uri.parse(_BASE_URL + endpoint);
          final request = http.Request(method, uri);
          final rawHeaders =
              item['headers'] is Map
                  ? Map<String, String>.from(item['headers'])
                  : _getHeaders();
          request.headers.addAll(rawHeaders);

          final rawBody =
              item['body'] is Map
                  ? Map<String, dynamic>.from(item['body'])
                  : {};
          if (rawBody.isNotEmpty) {
            request.body = jsonEncode(rawBody);
          }

          final streamed = await request.send().timeout(
            Duration(seconds: _TIMEOUT_DURATION),
          );
          final response = await http.Response.fromStream(streamed);

          if (!_shouldDropFromQueue(response.statusCode)) {
            pending.add(item);
          }
        } catch (_) {
          pending.add(item);
        }
      }

      HiveHelp.write(_pendingQueueKey, pending);
    } finally {
      _isSyncingQueue = false;
    }
  }

  static Future<http.Response> _request({
    required String method,
    required String ENDPOINT_URL,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    Response? response;
    final String cacheKey = _cacheKey(
      method: method,
      endpoint: ENDPOINT_URL,
      body: method == 'GET' ? null : body,
    );
    final Map<String, String> resolvedHeaders = headers ?? _getHeaders();

    try {
      final bool offline = await _isOfflineNow();

      if (offline) {
        if (method == 'GET') {
          final cached = _responseFromCache(
            method: method,
            endpoint: ENDPOINT_URL,
            cacheKey: cacheKey,
          );
          if (cached != null) {
            return cached;
          }
          return ApiResponse.handleException(
            http.ClientException('No internet and no cached data'),
            503,
          );
        }

        _queueWriteRequest(
          method: method,
          endpoint: ENDPOINT_URL,
          headers: resolvedHeaders,
          body: body,
        );
        return _offlineQueuedResponse(method: method, endpoint: ENDPOINT_URL);
      }

      await syncQueuedRequests();

      final uri = Uri.parse(_BASE_URL + ENDPOINT_URL);
      final request = http.Request(method, uri);
      request.headers.addAll(resolvedHeaders);

      if (body != null) {
        request.body = json.encode(body);
      }

      final streamedResponse = await request.send().timeout(
        Duration(seconds: _TIMEOUT_DURATION),
      );
      response = await http.Response.fromStream(streamedResponse);
      final processed = await ApiResponse.processResponse(response);
      if (method == 'GET') {
        _cacheResponse(cacheKey: cacheKey, response: processed);
      }
      return processed;
    } catch (E) {
      if (method != 'GET') {
        _queueWriteRequest(
          method: method,
          endpoint: ENDPOINT_URL,
          headers: resolvedHeaders,
          body: body,
        );
        return _offlineQueuedResponse(method: method, endpoint: ENDPOINT_URL);
      }

      final cached = _responseFromCache(
        method: method,
        endpoint: ENDPOINT_URL,
        cacheKey: cacheKey,
      );
      if (cached != null) {
        return cached;
      }

      return ApiResponse.handleException(
        E,
        response == null ? 999 : response.statusCode,
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
    try {
      final bool offline = await _isOfflineNow();
      if (offline) {
        return ApiResponse.handleException(
          http.ClientException(
            'Internet is required for file upload requests.',
          ),
          503,
        );
      }

      await syncQueuedRequests();

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
        Duration(seconds: _TIMEOUT_DURATION),
      );
      response = await http.Response.fromStream(streamedResponse);
      return await ApiResponse.processResponse(response);
    } catch (E) {
      return ApiResponse.handleException(
        E,
        response == null ? 999 : response.statusCode,
      );
    }
  }
}
