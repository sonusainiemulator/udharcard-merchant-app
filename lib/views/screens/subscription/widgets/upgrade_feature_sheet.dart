import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/subscription_controller.dart';
import '../../../../routes/routes_name.dart';
import '../../../../utils/services/subscription_gate_service.dart';

class UpgradeFeatureSheet extends StatelessWidget {
  const UpgradeFeatureSheet({
    super.key,
    this.title = 'Unlock AI VoiceKhata',
    this.subtitle = 'Manage credit 10x faster using simple voice commands — no typing needed.',
    this.featureKey = 'has_voice_entry',
  });

  final String title;
  final String subtitle;
  final String featureKey;

  static Future<void> show({
    String title = 'Unlock AI VoiceKhata',
    String subtitle = 'Manage credit 10x faster using simple voice commands — no typing needed.',
    String featureKey = 'has_voice_entry',
  }) async {
    await Get.bottomSheet(
      UpgradeFeatureSheet(
        title: title,
        subtitle: subtitle,
        featureKey: featureKey,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      builder: (controller) {
        final bool isTrialActive = SubscriptionGateService.isTrialActive();

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Voice Wave / Mic Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.mic_rounded,
                    size: 32,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Feature Highlights Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: const [
                    _BenefitRow(
                      icon: Icons.record_voice_over_rounded,
                      title: 'Voice-Based Credit Entry',
                      subtitle: 'Speak "Rajesh ko ₹500 diye" to record instantly',
                    ),
                    SizedBox(height: 12),
                    _BenefitRow(
                      icon: Icons.bolt_rounded,
                      title: '10x Faster Ledger Management',
                      subtitle: 'Hands-free bookkeeping during busy store hours',
                    ),
                    SizedBox(height: 12),
                    _BenefitRow(
                      icon: Icons.query_stats_rounded,
                      title: 'Instant Voice Queries',
                      subtitle: 'Ask "How much is pending from Ram?"',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1-Tap Free Trial Button
              if (!isTrialActive)
                Builder(builder: (context) {
                  final trialPlan = controller.trialPlan;
                  final trialCode = trialPlan?['code']?.toString() ?? 'premium';
                  final trialName = trialPlan?['name']?.toString() ?? 'Premium Plan';
                  final trialDays = (trialPlan?['trial_days'] as num?)?.toInt() ?? 7;

                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: controller.isStartingTrial
                          ? null
                          : () async {
                              final success = await controller.startTrial(
                                planCode: trialCode,
                                planName: trialName,
                              );
                              if (success) {
                                Get.back();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isStartingTrial
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.flash_on_rounded, size: 18, color: Colors.amberAccent),
                                const SizedBox(width: 8),
                                Text(
                                  'Start $trialDays-Day Free Trial',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                }),

              const SizedBox(height: 10),

              // View All Plans Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () {
                    Get.back();
                    Get.toNamed(RoutesName.subscriptionPlansScreen);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View All Plans & Features',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Continue with Free Manual Entry',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF1D4ED8)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
