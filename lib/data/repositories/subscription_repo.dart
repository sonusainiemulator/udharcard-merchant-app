import 'package:http/http.dart' as http;

import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class SubscriptionRepo {
  static Future<http.Response> getPlans() async =>
      await ApiClient.get(ENDPOINT_URL: AppConstants.subscriptionPlansUrl);

  static Future<http.Response> getCurrentSubscription() async =>
      await ApiClient.get(ENDPOINT_URL: AppConstants.subscriptionCurrentUrl);

  static Future<http.Response> createCheckout({
    required String planCode,
    required String billingCycle,
  }) async =>
      await ApiClient.post(
        ENDPOINT_URL: AppConstants.subscriptionCheckoutUrl,
        fields: {
          'plan_code': planCode,
          'billing_cycle': billingCycle,
        },
      );

  static Future<http.Response> verifyCheckout({
    required String orderId,
    required String paymentId,
    required String status,
    String? signature,
  }) async =>
      await ApiClient.post(
        ENDPOINT_URL: AppConstants.subscriptionVerifyUrl,
        fields: {
          'order_id': orderId,
          'payment_id': paymentId,
          'status': status,
          if (signature != null && signature.isNotEmpty) 'signature': signature,
        },
      );

  static Future<http.Response> getPaymentHistory() async =>
      await ApiClient.get(ENDPOINT_URL: AppConstants.subscriptionHistoryUrl);
}
