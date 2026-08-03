import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../data/repositories/subscription_repo.dart';
import '../data/source/errors/check_api_status.dart';
import '../routes/routes_name.dart';
import '../utils/services/helpers.dart';
import '../utils/services/localstorage/hive.dart';
import '../utils/services/localstorage/keys.dart';

class SubscriptionController extends GetxController {
  static SubscriptionController get to => Get.find<SubscriptionController>();

  late Razorpay _razorpay;
  String _pendingOrderId = '';
  String _pendingPlanCode = '';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCheckoutLoading = false;
  bool get isCheckoutLoading => _isCheckoutLoading;

  List<dynamic> plans = [];
  Map<String, dynamic>? currentSubscription;

  String selectedBillingCycle = 'monthly';

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    getPlans();
    getCurrentSubscription();
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  Future<void> getPlans() async {
    _isLoading = true;
    update();

    http.Response response = await SubscriptionRepo.getPlans();
    _isLoading = false;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        plans = (data['data']?['plans'] as List?) ?? [];
      } else {
        ApiStatus.checkStatus(data['status'].toString(), data['message'] ?? 'Unable to fetch plans');
      }
    } else {
      if (kDebugMode) {
        print(response.body);
      }
      Helpers.showSnackBar(msg: 'Unable to fetch subscription plans');
    }

    update();
  }

  Future<void> getCurrentSubscription() async {
    http.Response response = await SubscriptionRepo.getCurrentSubscription();

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        currentSubscription = data['data']?['subscription'];
        final status = currentSubscription?['status']?.toString() ?? '';
        final plan = currentSubscription?['plan'];
        final planCode = plan is Map ? plan['code']?.toString() : null;
        final billingCycle = currentSubscription?['billing_cycle']?.toString();

        if (status == 'active' || status == 'grace_period') {
          HiveHelp.write(Keys.subscriptionPlanSelected, true);
          if (planCode != null && planCode.isNotEmpty) {
            HiveHelp.write(Keys.subscriptionPlanCode, planCode);
          }
          if (billingCycle != null && billingCycle.isNotEmpty) {
            HiveHelp.write(Keys.subscriptionBillingCycle, billingCycle);
          }
        }
      }
    }
    update();
  }

  Future<void> startPlanPurchase({
    required String planCode,
    required String planName,
  }) async {
    _isCheckoutLoading = true;
    update();

    http.Response response = await SubscriptionRepo.createCheckout(
      planCode: planCode,
      billingCycle: selectedBillingCycle,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      final orderId = data['data']?['order_id']?.toString() ?? '';
      final amountRaw = data['data']?['amount'];
      final amount = double.tryParse(amountRaw.toString()) ?? 0.0;
      final amountInPaise = (amount * 100).round();

      _pendingOrderId = orderId;
      _pendingPlanCode = planCode;

      final keyId = _resolveRazorpayKey();
      if (keyId.isEmpty) {
        _isCheckoutLoading = false;
        update();
        Helpers.showSnackBar(
          msg: 'Razorpay key is missing. Add RAZORPAY_KEY_ID in .env to continue.',
        );
        return;
      }

      final contact = (HiveHelp.read(Keys.userPhone) ?? '').toString();
      final email = (HiveHelp.read(Keys.userEmail) ?? '').toString();

      final options = {
        'key': keyId,
        'amount': amountInPaise,
        'name': 'UdharCard Merchant',
        'description': '$planName Plan ($selectedBillingCycle)',
        'order_id': orderId,
        'timeout': 600,
        'prefill': {
          'contact': contact,
          'email': email,
        },
        'theme': {
          'color': '#175CD3',
        },
      };

      try {
        _razorpay.open(options);
      } catch (_) {
        _isCheckoutLoading = false;
        update();
        Helpers.showSnackBar(msg: 'Unable to open payment gateway. Please retry.');
      }
    } else {
      _isCheckoutLoading = false;
      ApiStatus.checkStatus(data['status']?.toString() ?? 'error', data['message'] ?? 'Checkout failed');
      update();
    }
  }

  void setBillingCycle(String value) {
    selectedBillingCycle = value;
    update();
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final orderId = response.orderId?.toString().trim().isNotEmpty == true
        ? response.orderId!.toString()
        : _pendingOrderId;

    final paymentId = response.paymentId?.toString() ?? '';
    final signature = response.signature?.toString();

    await _verifyCheckout(
      orderId: orderId,
      paymentId: paymentId,
      status: 'captured',
      signature: signature,
    );
  }

  Future<void> _onPaymentError(PaymentFailureResponse response) async {
    final fallbackPaymentId = 'failed_${DateTime.now().millisecondsSinceEpoch}';

    await _verifyCheckout(
      orderId: _pendingOrderId,
      paymentId: fallbackPaymentId,
      status: 'failed',
      signature: null,
    );

    Helpers.showSnackBar(msg: response.message ?? 'Payment failed. Please retry.');
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    Helpers.showSnackBar(
      msg: 'External wallet selected: ${response.walletName ?? 'Unknown'}',
    );
  }

  Future<void> _verifyCheckout({
    required String orderId,
    required String paymentId,
    required String status,
    String? signature,
  }) async {
    if (orderId.trim().isEmpty) {
      _isCheckoutLoading = false;
      update();
      Helpers.showSnackBar(msg: 'Invalid order details. Please retry checkout.');
      return;
    }

    final response = await SubscriptionRepo.verifyCheckout(
      orderId: orderId,
      paymentId: paymentId,
      status: status,
      signature: signature,
    );

    _isCheckoutLoading = false;

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      if (status == 'captured') {
        HiveHelp.write(Keys.subscriptionPlanSelected, true);
        if (_pendingPlanCode.isNotEmpty) {
          HiveHelp.write(Keys.subscriptionPlanCode, _pendingPlanCode);
        }
        HiveHelp.write(Keys.subscriptionBillingCycle, selectedBillingCycle);
        _pendingOrderId = '';
        _pendingPlanCode = '';
        Helpers.showSnackBar(msg: 'Plan activated successfully.');
        Get.offAllNamed(RoutesName.bottomNavBar);
      }
    } else {
      ApiStatus.checkStatus(
        data['status']?.toString() ?? 'error',
        data['message'] ?? 'Payment verification failed',
      );
    }

    update();
  }

  String _resolveRazorpayKey() {
    final primary = (dotenv.env['RAZORPAY_KEY_ID'] ?? '').trim();
    if (primary.isNotEmpty) {
      return primary;
    }

    // Fallback key for dev teams still using legacy env naming.
    final fallback = (dotenv.env['RAZORPAY_KEY'] ?? '').trim();
    return fallback;
  }
}
