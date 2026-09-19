import 'package:flutter_test/flutter_test.dart';
import 'package:paysecure/controllers/subscription_controller.dart';
import 'package:paysecure/utils/services/subscription_gate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionGateService Unit Tests', () {
    test('Default plan is basic with zero customer limit restriction', () {
      final code = SubscriptionGateService.currentPlanCode();
      expect(code, equals('basic'));

      final state = SubscriptionGateService.customerLimitState(currentCount: 50);
      expect(state.hasLimit, isFalse);
      expect(state.isNearLimit, isFalse);
      expect(state.isAtOrOverLimit, isFalse);
      expect(state.summaryLabel, contains('(Unlimited)'));
    });

    test('CustomerLimitState formats summary label with limits correctly', () {
      final stateWithLimit = CustomerLimitState(
        planCode: 'starter',
        currentCount: 200,
        customerLimit: 250,
      );
      expect(stateWithLimit.hasLimit, isTrue);
      expect(stateWithLimit.isNearLimit, isFalse); // threshold is 225
      expect(stateWithLimit.summaryLabel, equals('Plan: Starter | Customers: 200 / 250'));

      final nearLimitState = CustomerLimitState(
        planCode: 'starter',
        currentCount: 230,
        customerLimit: 250,
      );
      expect(nearLimitState.isNearLimit, isTrue);
    });

    test('Soundbox inclusion requires Gold or Enterprise plan', () {
      expect(SubscriptionGateService.isSoundboxIncluded(), isFalse);
    });
  });

  group('SubscriptionController Default Plans Tests', () {
    test('defaultPlans provides the exact 3 cards matching the mockup', () {
      final plans = SubscriptionController.defaultPlans;
      expect(plans.length, equals(3));

      final basic = plans.firstWhere((p) => p['code'] == 'basic');
      expect(basic['name'], equals('Basic Plan'));
      expect(basic['tag'], equals('FREE'));
      expect(basic['monthly_price'], equals(0));
      expect(basic['yearly_price'], equals(0));
      expect(basic['trial_days'], equals(0));

      final premium = plans.firstWhere((p) => p['code'] == 'premium');
      expect(premium['name'], equals('Premium Plan'));
      expect(premium['tag'], equals('MOST POPULAR'));
      expect(premium['badge'], equals('VOICE'));
      expect(premium['monthly_price'], equals(29));
      expect(premium['yearly_price'], equals(299));
      expect(premium['trial_days'], equals(7));
      expect(premium['sample_prompts'], isNotEmpty);
      expect(premium['feature_flags']['has_voice_entry'], isTrue);

      final gold = plans.firstWhere((p) => p['code'] == 'gold');
      expect(gold['name'], equals('Gold Plan'));
      expect(gold['tag'], equals('BEST VALUE'));
      expect(gold['badge'], equals('SOUND'));
      expect(gold['monthly_price'], equals(129));
      expect(gold['yearly_price'], equals(1299));
      expect(gold['trial_days'], equals(0));
      expect(gold['features'], contains('Free UdharCard Soundbox Device'));
      expect(gold['feature_flags']['has_soundbox'], isTrue);
    });
  });
}
