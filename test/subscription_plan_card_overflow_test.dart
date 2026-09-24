import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/subscription_controller.dart';
import 'package:paysecure/views/screens/subscription/widgets/plan_card_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanCardWidget Overflow Resilience Tests', () {
    testWidgets('Gold Plan card renders completely with zero bottom overflow',
        (WidgetTester tester) async {
      // Simulate phone screen size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75; // Standard 392x872 logical
      addTearDown(tester.view.resetPhysicalSize);

      final goldPlan = SubscriptionController.defaultPlans.firstWhere(
        (p) => p['code'] == 'gold',
      );

      bool selected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 645,
                child: PlanCardWidget(
                  plan: goldPlan,
                  isCurrent: false,
                  isTrialActive: false,
                  billingCycle: 'monthly',
                  activePlanCode: 'basic',
                  onSelectPlan: () {
                    selected = true;
                  },
                  onStartTrial: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow exception was thrown
      expect(tester.takeException(), isNull);

      // Verify elements rendered
      expect(find.text('Gold Plan'), findsOneWidget);
      expect(find.text('SOUND'), findsOneWidget);
      expect(find.text('BEST VALUE'), findsOneWidget);
      expect(find.text('₹129'), findsOneWidget);
      expect(find.text('/month'), findsOneWidget);
      expect(find.text('TRY SAYING:'), findsOneWidget);
      expect(find.text('Subscribe Now'), findsOneWidget);

      // Verify button tap works inside the card
      await tester.tap(find.text('Subscribe Now'));
      await tester.pump();
      expect(selected, isTrue);
    });

    testWidgets('Extreme text scale factor does not cause yellow/black overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      final goldPlan = SubscriptionController.defaultPlans.firstWhere(
        (p) => p['code'] == 'gold',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)), // 130% accessibility text scale
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  height: 645,
                  child: PlanCardWidget(
                    plan: goldPlan,
                    isCurrent: false,
                    isTrialActive: false,
                    billingCycle: 'monthly',
                    activePlanCode: 'basic',
                    onSelectPlan: () {},
                    onStartTrial: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Crucial: SingleChildScrollView prevents RenderFlex overflow even with huge font scale
      expect(tester.takeException(), isNull);
    });
  });
}
