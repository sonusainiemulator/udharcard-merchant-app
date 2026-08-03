import 'package:http/http.dart' as http;
import 'package:paysecure/utils/app_constants.dart';

import '../source/network/api_client.dart';

class WorkListRepo {
  static Future<http.Response> getItems({String? lastSyncTime}) async {
    final endpoint = lastSyncTime != null && lastSyncTime.isNotEmpty
        ? '${AppConstants.workListUrl}?last_sync_time=$lastSyncTime'
        : AppConstants.workListUrl;

    return ApiClient.get(ENDPOINT_URL: endpoint);
  }

  static Future<http.Response> createItem({
    required Map<String, dynamic> payload,
  }) async {
    return ApiClient.post(
      ENDPOINT_URL: AppConstants.workListUrl,
      fields: payload,
    );
  }

  static Future<http.Response> updateItem({
    required String itemId,
    required Map<String, dynamic> payload,
  }) async {
    return ApiClient.put(
      ENDPOINT_URL: '${AppConstants.workListUrl}/$itemId',
      fields: payload,
    );
  }

  static Future<http.Response> deleteItem({required String itemId}) async {
    return ApiClient.delete(ENDPOINT_URL: '${AppConstants.workListUrl}/$itemId');
  }

  static Future<http.Response> pullSync({required String lastSyncTime}) async {
    return ApiClient.get(
      ENDPOINT_URL: '${AppConstants.workListSyncUrl}?last_sync_time=$lastSyncTime',
    );
  }

  static Future<http.Response> pushSync({
    required List<Map<String, dynamic>> upserts,
    required List<String> deletes,
  }) async {
    return ApiClient.post(
      ENDPOINT_URL: AppConstants.workListSyncUrl,
      fields: {
        'upserts': upserts,
        'deletes': deletes,
      },
    );
  }
}