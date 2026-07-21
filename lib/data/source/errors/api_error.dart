import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../utils/services/helpers.dart';
import '../../../views/screens/auth/login_screen.dart';

class ApiResponse {
  /// Process the HTTP response and handle different status codes efficiently.
  static Future<http.Response> processResponse(http.Response response) async {
    int STATUS_CODE = response.statusCode;
    String URL = response.request!.url.toString();
    String METHOD = response.request!.method.toString();

    if (response.headers['content-type']?.contains('application/json') ??
        false) {
      switch (response.statusCode) {
        case 200:
          if (kDebugMode) print('✅ $METHOD: $URL');
          return response;

        case 401:
          Get.offAll(() => const LoginScreen());
          return _logError(
            STATUS_CODE,
            URL,
            'The user is unauthorized. Please log in to continue.',
            response.body,
          );

        case 404:
          return _logError(
            STATUS_CODE,
            URL,
            'Resource not found',
            response.body,
          );

        case 429:
          return _logError(
            STATUS_CODE,
            URL,
            'Too many requests',
            response.body,
          );

        case 500:
          return _logError(
            STATUS_CODE,
            URL,
            'Internal server error',
            response.body,
          );

        default:
          return _logError(STATUS_CODE, URL, 'Unexpected error', response.body);
      }
    } else {
      return _logError(
        STATUS_CODE,
        URL,
        'An unexpected error occurred. Please try to login again. status code',
        response.body,
      );
    }
  }

  /// Handle exceptions during API calls and return a custom HTTP response.
  static http.Response handleException(dynamic error, int statusCode) {
    String message;

    if (error is TimeoutException) {
      message = 'Request timed out. Please try again.';
    } else if (error is SocketException) {
      message = 'No internet connection. Please check your network.';
    } else if (error is HttpException) {
      message = error.message;
    } else if (error is FormatException) {
      message = 'Bad response format.';
    } else if (error is http.ClientException) {
      message = 'Client error occurred.';
    } else {
      message = 'An unexpected error occurred.';
    }

    // Keep 404 route errors silent here so feature-level handlers can show
    // clearer fallback messages (for example, queueing data offline).
    if (!message.contains('Resource not found || 404')) {
      Helpers.showSnackBar(msg: message);
    }
    return http.Response(message, statusCode);
  }

  /// Private method to log errors for debugging.
  static http.Response _logError(
    int statusCode,
    String url,
    String errorType,
    String details,
  ) {
    if (kDebugMode) {
      print('⛔STATUS_CODE:=====>>>>$statusCode<<<=========');
      print('⛔URL:=====>>>> $url');
      print('⛔CUSTOM_ERROR_TYPE:=====>>>>$errorType<<<=========');
      print('⛔ERROR_DETAILS_FROM_API:=====>>>> $details');
    }
    throw HttpException('$errorType || $statusCode');
  }
}
