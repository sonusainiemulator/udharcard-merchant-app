import 'localstorage/hive.dart';
import 'localstorage/keys.dart';

class CustomerLimitState {
  CustomerLimitState({
    required this.planCode,
    required this.currentCount,
    required this.customerLimit,
  });

  final String planCode;
  final int currentCount;
  final int? customerLimit;

  bool get hasLimit => customerLimit != null;

  int get warningThreshold {
    if (customerLimit == null) return 0;
    final int threshold = (customerLimit! * 0.9).floor();
    return threshold < 1 ? 1 : threshold;
  }

  bool get isNearLimit => hasLimit && currentCount >= warningThreshold;
  bool get isAtOrOverLimit => hasLimit && currentCount >= (customerLimit ?? 0);

  String get summaryLabel {
    if (!hasLimit) {
      return 'Plan: ${_titleCase(planCode)} | Customers: $currentCount (Unlimited)';
    }

    return 'Plan: ${_titleCase(planCode)} | Customers: $currentCount / $customerLimit';
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return 'Starter';
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}

class SubscriptionGateService {
  static bool isPlanEnrollmentRequired() {
    final dynamic raw = HiveHelp.read(Keys.subscriptionEnrollmentRequired);
    if (raw is bool) {
      return raw;
    }
    return false;
  }

  static const Map<String, int?> _customerLimitByPlan = {
    'starter': 250,
    'growth': 1000,
    'enterprise': null,
  };

  static String currentPlanCode() {
    final String raw = (HiveHelp.read(Keys.subscriptionPlanCode) ?? 'starter')
        .toString()
        .trim()
        .toLowerCase();
    if (_customerLimitByPlan.containsKey(raw)) {
      return raw;
    }
    return 'starter';
  }

  static bool isSoftRolloutEnabled() {
    final dynamic raw = HiveHelp.read(Keys.subscriptionSoftRolloutEnabled);
    if (raw is bool) {
      return raw;
    }
    return true;
  }

  static bool isHardLimitEnabled() {
    final dynamic raw = HiveHelp.read(Keys.subscriptionHardLimitEnabled);
    if (raw is bool) {
      return raw;
    }
    return false;
  }

  static CustomerLimitState customerLimitState({required int currentCount}) {
    final String plan = currentPlanCode();
    return CustomerLimitState(
      planCode: plan,
      currentCount: currentCount,
      customerLimit: _customerLimitByPlan[plan],
    );
  }

  static String? customerAddSoftWarning({required int currentCount}) {
    if (!isSoftRolloutEnabled()) {
      return null;
    }

    final state = customerLimitState(currentCount: currentCount);

    if (!state.hasLimit) {
      return null;
    }

    if (state.isAtOrOverLimit) {
      return 'You reached your ${state.planCode} plan customer limit (${state.customerLimit}). Soft rollout is active, so add is still allowed. Please upgrade soon.';
    }

    if (state.isNearLimit) {
      return 'You are close to your ${state.planCode} customer limit (${state.currentCount}/${state.customerLimit}). Consider upgrading before hard limits are enabled.';
    }

    return null;
  }

  static bool isVoiceEntryIncluded() {
    final plan = currentPlanCode();
    return plan == 'growth' || plan == 'enterprise';
  }

  static String voiceEntrySoftNudge() {
    if (!isSoftRolloutEnabled()) {
      return 'Voice Entry access is controlled by your current plan.';
    }

    if (isVoiceEntryIncluded()) {
      return 'Voice Entry is included in your current plan.';
    }

    return 'Voice Entry is part of Growth and Enterprise plans. Soft rollout is active, so access is allowed for now.';
  }
}
