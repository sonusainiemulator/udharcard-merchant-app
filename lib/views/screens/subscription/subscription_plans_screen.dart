import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/subscription_controller.dart';
import '../../../utils/services/helpers.dart';
import '../../widgets/custom_appbar.dart';
import 'widgets/plan_card_widget.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  int _currentPageIndex = 1; // Default highlight Premium Plan in the middle!
  final PageController _pageController = PageController(
    initialPage: 1,
    viewportFraction: 0.88,
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      init: SubscriptionController.to,
      builder: (controller) {
        final activeCode = controller.activePlanCode.toLowerCase();
        final isTrial = controller.isTrialActive;
        final trialDays = controller.trialDaysRemaining;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: CustomAppBar(
            title: 'Choose a Plan',
            actions: [
              if (!controller.isPlanEnrollmentRequired)
                TextButton(
                  onPressed: controller.skipPlanEnrollment,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
            ],
          ),
          body: controller.isLoading && controller.plans.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    // --- Active Trial / Plan Banner ---
                    if (isTrial)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFF1D4ED8), size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🎉 Premium Free Trial Active!',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  Text(
                                    '$trialDays ${trialDays == 1 ? "day" : "days"} remaining. Enjoy full AI Voice Khata access.',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (activeCode != 'basic' && controller.currentSubscription != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your current plan: ${controller.activePlanCode.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // --- Pending Offline Request Banner ---
                    if (controller.pendingOfflineRequest != null)
                      _buildPendingRequestBanner(controller.pendingOfflineRequest!),

                    // --- Billing Cycle Switcher ---
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCycleButton(
                              title: 'Monthly',
                              isSelected: controller.selectedBillingCycle == 'monthly',
                              onTap: () => controller.setBillingCycle('monthly'),
                            ),
                            _buildCycleButton(
                              title: 'Yearly',
                              badge: 'SAVE 15%',
                              isSelected: controller.selectedBillingCycle == 'yearly',
                              onTap: () => controller.setBillingCycle('yearly'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Quick Plan Navigation Tabs ---
                    Row(
                      children: List.generate(controller.plans.length, (index) {
                        final p = controller.plans[index] as Map<String, dynamic>;
                        final pName = p['name']?.toString() ?? 'Plan';
                        final isSelected = _currentPageIndex == index;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _currentPageIndex = index);
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF1D4ED8) : Colors.transparent,
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                pName.replaceAll(' Plan', ''),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),

                    // --- Horizontal Swipeable Plan Cards ---
                    SizedBox(
                      height: 590,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: controller.plans.length,
                        onPageChanged: (idx) {
                          setState(() => _currentPageIndex = idx);
                        },
                        itemBuilder: (context, index) {
                          final plan = controller.plans[index] as Map<String, dynamic>;
                          final code = plan['code']?.toString().toLowerCase() ?? '';
                          final isCurrent = activeCode == code;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: PlanCardWidget(
                              plan: plan,
                              activePlanCode: activeCode,
                              isCurrent: isCurrent,
                              isTrialActive: isCurrent && isTrial,
                              billingCycle: controller.selectedBillingCycle,
                              isLoading: controller.isStartingTrial || controller.isCheckoutLoading,
                              onSelectPlan: () => _handlePlanSelection(controller, plan),
                              onStartTrial: () => _handleStartTrial(controller, plan),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Page Indicator Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(controller.plans.length, (idx) {
                        final isSel = _currentPageIndex == idx;
                        return Container(
                          width: isSel ? 20 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 18),

                    // Trust Badge Footer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Zero Risk. You can cancel or switch plans anytime. Free Basic Plan remains available forever.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCycleButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestBanner(Map<String, dynamic> req) {
    final code = req['requested_plan_code']?.toString() ?? 'Plan';
    final when = req['created_at']?.toString().split('T').first ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline upgrade request for "$code" submitted on $when. Admin will verify and activate your plan.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStartTrial(
    SubscriptionController controller,
    Map<String, dynamic> plan,
  ) async {
    final planCode = plan['code']?.toString() ?? 'premium';
    final planName = plan['name']?.toString() ?? 'Premium Plan';
    final trialDays = (plan['trial_days'] as num?)?.toInt() ?? 7;

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.flash_on_rounded, color: Color(0xFF1D4ED8)),
            SizedBox(width: 8),
            Text('Start Free Trial', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Activate your $trialDays-Day Free Trial of $planName?\n\n'
          '• Full access to AI Voice Khata\n'
          '• Voice credit entry & balance queries\n'
          '• No payment required upfront',
          style: const TextStyle(height: 1.4, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Activate Trial'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await controller.startTrial(planCode: planCode, planName: planName);
    }
  }

  Future<void> _handlePlanSelection(
    SubscriptionController controller,
    Map<String, dynamic> plan,
  ) async {
    final planCode = plan['code']?.toString() ?? 'basic';
    final planName = plan['name']?.toString() ?? 'Plan';
    final isFree = (plan['monthly_price'] as num?)?.toDouble() == 0;

    if (isFree) {
      Helpers.showSnackBar(msg: 'You are currently on the Free Basic Plan.');
      return;
    }

    // Modal to choose payment method (Online Razorpay or Offline Admin Request)
    await Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Subscribe to $planName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Select how you would like to complete your payment for the ${controller.selectedBillingCycle} cycle.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            // Option 1: Online Payment (Razorpay / UPI / Cards)
            ListTile(
              onTap: () {
                Get.back();
                controller.startPlanPurchase(planCode: planCode, planName: planName);
              },
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.credit_card_rounded, color: Color(0xFF1D4ED8)),
              ),
              title: const Text('Pay Online (Instant)', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('UPI, Cards, NetBanking via Razorpay', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(height: 10),

            // Option 2: Offline Request (Bank Transfer / Admin Approval)
            ListTile(
              onTap: () async {
                Get.back();
                await controller.requestOfflineUpgrade(
                  planCode: planCode,
                  planName: planName,
                );
              },
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded, color: Color(0xFFD97706)),
              ),
              title: const Text('Offline Bank / UPI Request', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Pay via direct transfer and admin will approve', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
