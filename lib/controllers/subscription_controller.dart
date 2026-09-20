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
import '../utils/services/subscription_gate_service.dart';

class SubscriptionController extends GetxController {
  static SubscriptionController get to => Get.find<SubscriptionController>();

  late Razorpay _razorpay;
  String _pendingOrderId = '';
  String _pendingPlanCode = '';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCheckoutLoading = false;
  bool get isCheckoutLoading => _isCheckoutLoading;

  bool _isStartingTrial = false;
  bool get isStartingTrial => _isStartingTrial;

  List<dynamic> plans = [];
  Map<String, dynamic>? currentSubscription;
  Map<String, dynamic>? currentPlanData;

  String selectedBillingCycle = 'monthly';

  // Trial state
  bool isTrialActive = false;
  int trialDaysRemaining = 0;
  String? trialEndsAt;
  String activePlanCode = 'basic';

  String get currentPlanName {
    if (currentPlanData != null && currentPlanData!['name'] != null) {
      return currentPlanData!['name'].toString();
    }
    final dynamic cachedName = HiveHelp.read(Keys.subscriptionPlanName);
    if (cachedName != null && cachedName.toString().trim().isNotEmpty) {
      return cachedName.toString().trim();
    }
    for (final p in plans) {
      if (p is Map && p['code']?.toString().toLowerCase() == activePlanCode.toLowerCase()) {
        if (p['name'] != null && p['name'].toString().isNotEmpty) {
          return p['name'].toString();
        }
      }
    }
    if (activePlanCode.isEmpty || activePlanCode.toLowerCase() == 'basic') {
      return 'Basic Plan';
    }
    return '${activePlanCode[0].toUpperCase()}${activePlanCode.substring(1)} Plan';
  }

  Map<String, dynamic>? get trialPlan {
    for (final p in plans) {
      if (p is Map && (p['trial_days'] as num? ?? 0) > 0) {
        return Map<String, dynamic>.from(p);
      }
    }
    return null;
  }
  Map<String, dynamic> activeFeatureFlags = {
    'has_voice_entry': false,
    'has_soundbox': false,
    'has_desktop_access': true,
    'pdf_bill_access': true,
  };

  // Offline (admin-approval) upgrade request state
  bool _isRequestingOffline = false;
  bool get isRequestingOffline => _isRequestingOffline;
  Map<String, dynamic>? latestUpgradeRequest; // pending/approved/rejected request shown to merchant
  Map<String, dynamic>? pendingOfflineRequest;

  // Fallback plans matching the user's mockup in case of network issue
  static final List<Map<String, dynamic>> defaultPlans = [
    {
      'code': 'basic',
      'name': 'Basic Plan',
      'tag': 'FREE',
      'tag_color': '#1E293B',
      'badge': 'FREE',
      'description': 'Perfect for merchants who want a simple way to manage customer credit records.',
      'subtitle': 'Perfect for merchants who want a simple way to manage customer credit records.',
      'monthly_price': 0,
      'yearly_price': 0,
      'currency': 'INR',
      'trial_days': 0,
      'features': [
        'Manually add and manage customer credit entries',
        'Track outstanding balances',
        'Access records from mobile, laptop, or desktop',
        'Simple and easy-to-use credit management system',
      ],
      'feature_flags': {
        'has_voice_entry': false,
        'has_soundbox': false,
        'has_desktop_access': true,
        'pdf_bill_access': true,
      },
      'sample_prompts': null,
      'cta_text': 'Get Started Free',
      'is_active': true,
    },
    {
      'code': 'premium',
      'name': 'Premium Plan',
      'tag': 'MOST POPULAR',
      'tag_color': '#EA580C',
      'badge': 'VOICE',
      'description': 'Manage your credit business faster with AI-powered voice assistance.',
      'subtitle': 'Manage your credit business faster with AI-powered voice assistance.',
      'monthly_price': 29,
      'yearly_price': 299,
      'currency': 'INR',
      'trial_days': 7,
      'features': [
        'Everything in the Basic Plan',
        'Voice-based credit entry',
        'Add customer transactions by speaking',
        'Quick credit and payment tracking using voice commands',
      ],
      'feature_flags': {
        'has_voice_entry': true,
        'has_soundbox': false,
        'has_desktop_access': true,
        'pdf_bill_access': true,
      },
      'sample_prompts': [
        'How much is pending from Ram?',
        "Show today's credit entries",
      ],
      'cta_text': 'Subscribe Now',
      'is_active': true,
    },
    {
      'code': 'gold',
      'name': 'Gold Plan',
      'tag': 'BEST VALUE',
      'tag_color': '#D97706',
      'badge': 'SOUND',
      'description': 'The ultimate hands-free credit management solution for merchants.',
      'subtitle': 'The ultimate hands-free credit management solution for merchants.',
      'monthly_price': 129,
      'yearly_price': 1299,
      'currency': 'INR',
      'trial_days': 0,
      'features': [
        'Everything in the Premium Plan',
        'Free UdharCard Soundbox Device',
        'Use the Soundbox as your dedicated voice assistant',
        'Add and manage credit entries without using a phone or laptop',
        'Check customer balances through voice commands',
        'Faster and more convenient shop management',
      ],
      'feature_flags': {
        'has_voice_entry': true,
        'has_soundbox': true,
        'has_desktop_access': true,
        'pdf_bill_access': true,
      },
      'sample_prompts': [
        'Add ₹500 credit to Ram',
        'How much balance is pending from Ram?',
      ],
      'cta_text': 'Subscribe Now',
      'is_active': true,
    },
  ];

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    // Initialize with default plans immediately to eliminate UI flicker
    plans = List.from(defaultPlans);
    _loadCachedSubscriptionState();

    getPlans();
    getCurrentSubscription();
    fetchMyUpgradeStatus();
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  void _loadCachedSubscriptionState() {
    isTrialActive = SubscriptionGateService.isTrialActive();
    trialDaysRemaining = SubscriptionGateService.trialDaysRemaining();
    activePlanCode = SubscriptionGateService.currentPlanCode();
    final cachedFlags = HiveHelp.read(Keys.subscriptionFeatureFlags);
    if (cachedFlags is Map) {
      activeFeatureFlags = Map<String, dynamic>.from(cachedFlags);
    }
  }

  Future<void> getPlans() async {
    _isLoading = true;
    update();

    try {
      http.Response response = await SubscriptionRepo.getPlans();
      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final fetched = (data['data']?['plans'] as List?) ?? [];
          if (fetched.isNotEmpty) {
            plans = fetched;
          }
        } else {
          ApiStatus.checkStatus(data['status'].toString(), data['message'] ?? 'Unable to fetch plans');
        }
      } else {
        if (kDebugMode) {
          print(response.body);
        }
      }
    } catch (_) {
      _isLoading = false;
    }

    if (plans.isEmpty) {
      plans = List.from(defaultPlans);
    }

    update();
  }

  Future<void> getCurrentSubscription() async {
    try {
      http.Response response = await SubscriptionRepo.getCurrentSubscription();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final resData = data['data'];
          currentSubscription = resData?['subscription'];
          currentPlanData = resData?['plan'];

          isTrialActive = resData?['is_trial'] == true;
          trialDaysRemaining = (resData?['trial_days_remaining'] as num?)?.toInt() ?? 0;
          trialEndsAt = resData?['trial_ends_at']?.toString();
          activePlanCode = resData?['plan_code']?.toString() ?? 'basic';

          if (resData?['feature_flags'] is Map) {
            activeFeatureFlags = Map<String, dynamic>.from(resData['feature_flags']);
            HiveHelp.write(Keys.subscriptionFeatureFlags, activeFeatureFlags);
          }

          final billingCycle = currentSubscription?['billing_cycle']?.toString();

          final resolvedPlanName = resData?['plan_name']?.toString() ??
              currentPlanData?['name']?.toString() ??
              '';
          if (resolvedPlanName.isNotEmpty) {
            HiveHelp.write(Keys.subscriptionPlanName, resolvedPlanName);
          }

          HiveHelp.write(Keys.subscriptionPlanSelected, true);
          HiveHelp.write(Keys.subscriptionPlanCode, activePlanCode);
          HiveHelp.write(Keys.subscriptionIsTrial, isTrialActive);
          if (trialEndsAt != null) {
            HiveHelp.write(Keys.subscriptionTrialEndsAt, trialEndsAt);
          }
          HiveHelp.write(Keys.subscriptionTrialDaysRemaining, trialDaysRemaining);

          if (billingCycle != null && billingCycle.isNotEmpty) {
            HiveHelp.write(Keys.subscriptionBillingCycle, billingCycle);
          }
        }
      }
    } catch (_) {}
    update();
  }

  /// Start Free Trial for a plan (dynamically resolved from plan or trialPlan).
  Future<bool> startTrial({
    String? planCode,
    String? planName,
  }) async {
    final code = (planCode != null && planCode.isNotEmpty)
        ? planCode
        : (trialPlan?['code']?.toString() ?? 'premium');
    final name = (planName != null && planName.isNotEmpty)
        ? planName
        : (trialPlan?['name']?.toString() ?? 'Premium Plan');

    if (_isStartingTrial) return false;
    _isStartingTrial = true;
    update();

    try {
      final response = await SubscriptionRepo.startTrial(planCode: code);
      final data = _decode(response.body);
      _isStartingTrial = false;

      if (response.statusCode == 200 && data?['status'] == 'success') {
        final d = data?['data'];
        final trialDays = (d?['trial_days_remaining'] as num?)?.toInt() ?? 7;
        final endsAt = d?['trial_ends_at']?.toString();

        isTrialActive = true;
        trialDaysRemaining = trialDays;
        activePlanCode = code;

        HiveHelp.write(Keys.subscriptionPlanSelected, true);
        HiveHelp.write(Keys.subscriptionPlanCode, code);
        HiveHelp.write(Keys.subscriptionPlanName, name);
        HiveHelp.write(Keys.subscriptionIsTrial, true);
        if (endsAt != null) {
          HiveHelp.write(Keys.subscriptionTrialEndsAt, endsAt);
        }
        HiveHelp.write(Keys.subscriptionTrialDaysRemaining, trialDays);

        if (d?['feature_flags'] is Map) {
          activeFeatureFlags = Map<String, dynamic>.from(d['feature_flags']);
          HiveHelp.write(Keys.subscriptionFeatureFlags, activeFeatureFlags);
        }

        Helpers.showSnackBar(
          msg: data?['message'] ?? '🎉 Free Trial activated! AI Voice Khata is unlocked.',
        );

        await getCurrentSubscription();
        update();
        return true;
      } else {
        final errorMsg = data?['message']?.toString() ?? 'Unable to activate free trial.';
        Helpers.showSnackBar(msg: errorMsg);
        update();
        return false;
      }
    } catch (_) {
      _isStartingTrial = false;
      Helpers.showSnackBar(msg: 'Unable to start trial. Please check connection and retry.');
      update();
      return false;
    }
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

      final serverKey = (data['data']?['razorpay_key_id'] ?? '').toString().trim();
      final keyId = serverKey.isNotEmpty ? serverKey : _resolveRazorpayKey();
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

  Future<void> skipPlanEnrollment() async {
    HiveHelp.write(Keys.subscriptionPlanSelected, false);
    await HiveHelp.remove(Keys.subscriptionPlanCode);
    await HiveHelp.remove(Keys.subscriptionBillingCycle);
    Get.offAllNamed(RoutesName.bottomNavBar);
  }

  bool get isPlanEnrollmentRequired =>
      SubscriptionGateService.isPlanEnrollmentRequired();

  /// Fetch merchant's upgrade state (active subscription + latest offline request).
  Future<void> fetchMyUpgradeStatus() async {
    try {
      final response = await SubscriptionRepo.myUpgradeStatus();
      final data = _decode(response.body);
      if (response.statusCode == 200 && data?['status'] == 'success') {
        final d = data?['data'];
        latestUpgradeRequest = d?['latest_request'] is Map
            ? Map<String, dynamic>.from(d['latest_request'])
            : null;
        final hasPending = d?['has_pending_request'] == true;
        if (hasPending && latestUpgradeRequest != null) {
          pendingOfflineRequest = latestUpgradeRequest;
        } else {
          pendingOfflineRequest = null;
        }
      }
    } catch (_) {}
    update();
  }

  /// Submit an OFFLINE upgrade request for admin approval (no online payment).
  Future<void> requestOfflineUpgrade({
    required String planCode,
    required String planName,
    String? note,
  }) async {
    if (_isRequestingOffline) return;
    _isRequestingOffline = true;
    update();

    try {
      final response = await SubscriptionRepo.offlineRequest(
        planCode: planCode,
        billingCycle: selectedBillingCycle,
        note: note,
      );
      final data = _decode(response.body);
      if (response.statusCode == 200 && data?['status'] == 'success') {
        Helpers.showSnackBar(
          msg: data?['message'] ??
              'Upgrade request submitted. Admin will activate it after payment confirmation.',
        );
        await fetchMyUpgradeStatus();
        await getCurrentSubscription();
      } else {
        Helpers.showSnackBar(
          msg: data?['message']?.toString() ??
              'Unable to submit request. Please try again.',
        );
      }
    } catch (_) {
      Helpers.showSnackBar(
        msg: 'Unable to submit request. Please check your internet and retry.',
      );
    }

    _isRequestingOffline = false;
    update();
  }

  Map<String, dynamic>? _decode(String raw) {
    try {
      final dynamic d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return d;
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
    return null;
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
        HiveHelp.write(Keys.subscriptionIsTrial, false);
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
    if (fallback.isNotEmpty) {
      return fallback;
    }

    // Default sandbox test key for seamless local testing
    return 'rzp_test_1DP5mmOlF5G5ag';
  }
}
