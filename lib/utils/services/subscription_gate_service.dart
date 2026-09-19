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
    if (value.isEmpty) return 'Basic';
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
    'basic': null, // Basic is free with unlimited manual entries
    'premium': null,
    'gold': null,
    'starter': 250,
    'growth': 1000,
    'enterprise': null,
  };

  static String currentPlanCode() {
    final String raw = (HiveHelp.read(Keys.subscriptionPlanCode) ?? 'basic')
        .toString()
        .trim()
        .toLowerCase();
    if (_customerLimitByPlan.containsKey(raw)) {
      return raw;
    }
    return 'basic';
  }

  static bool isTrialActive() {
    final dynamic isTrial = HiveHelp.read(Keys.subscriptionIsTrial);
    if (isTrial != true) return false;

    final dynamic endsAtRaw = HiveHelp.read(Keys.subscriptionTrialEndsAt);
    if (endsAtRaw == null || endsAtRaw.toString().isEmpty) {
      return true;
    }

    try {
      final endsAt = DateTime.parse(endsAtRaw.toString());
      if (DateTime.now().isAfter(endsAt)) {
        HiveHelp.write(Keys.subscriptionIsTrial, false);
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  static int trialDaysRemaining() {
    if (!isTrialActive()) return 0;
    final dynamic endsAtRaw = HiveHelp.read(Keys.subscriptionTrialEndsAt);
    if (endsAtRaw == null || endsAtRaw.toString().isEmpty) {
      final dynamic cached = HiveHelp.read(Keys.subscriptionTrialDaysRemaining);
      return cached is int ? cached : 0;
    }

    try {
      final endsAt = DateTime.parse(endsAtRaw.toString());
      final diff = endsAt.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff + 1;
    } catch (_) {
      return 0;
    }
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
    // 1. Trial allows full AI Voice access
    if (isTrialActive()) {
      return true;
    }

    // 2. Feature flags check if cached
    final dynamic flags = HiveHelp.read(Keys.subscriptionFeatureFlags);
    if (flags is Map && flags['has_voice_entry'] == true) {
      return true;
    }

    // 3. Plan codes check (Premium & Gold or legacy Growth & Enterprise)
    final plan = currentPlanCode();
    return plan == 'premium' ||
        plan == 'gold' ||
        plan == 'growth' ||
        plan == 'enterprise';
  }

  static bool isSoundboxIncluded() {
    final dynamic flags = HiveHelp.read(Keys.subscriptionFeatureFlags);
    if (flags is Map && flags['has_soundbox'] == true) {
      return true;
    }

    final plan = currentPlanCode();
    return plan == 'gold' || plan == 'enterprise';
  }

  static String voiceEntrySoftNudge() {
    if (isTrialActive()) {
      final days = trialDaysRemaining();
      return 'AI Voice Khata is active on your Free Trial ($days ${days == 1 ? "day" : "days"} remaining).';
    }

    if (isVoiceEntryIncluded()) {
      return 'AI Voice Khata is included in your active plan.';
    }

    return 'AI Voice Khata is a Premium feature. Tap to start your 7-day Free Trial or upgrade.';
  }
}
