import 'package:http/http.dart' as http;
import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class TransactionRepo {
  static Future<http.Response> getTransactionList({
    required int page,

    required String created_at,
    String? utr,
  }) async =>
      await ApiClient.get(
          ENDPOINT_URL: AppConstants.transactionUrl +
              "?page=$page&created_at=$created_at&utr=$utr");
}
