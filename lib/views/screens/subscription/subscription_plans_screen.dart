import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/subscription_controller.dart';
import '../../../utils/services/helpers.dart';
import '../../widgets/custom_appbar.dart';

// Shared palette for this screen (file-level so every private class can use it)
const Color _brand = Color(0xFF0857E6);
const Color _ink = Color(0xFF1A1D2B);
const Color _sub = Color(0xFF7A7E8C);
const Color _bg = Color(0xFFF6F7F9);
const Color _card = Colors.white;
const Color _line = Color(0xFFEEF0F4);
const Color _green = Color(0xFF21A35C);
const Color _amber = Color(0xFFB45309);

/// Subscription plans screen for merchant.
/// - Lists available plans, current plan, and offline (admin-approval)
///   upgrade request flow. Online (Razorpay) payment is marked coming-soon.
class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      init: SubscriptionController.to,
      builder: (controller) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: CustomAppBar(
            title: 'Choose a Plan',
            actions: [
              if (!controller.isPlanEnrollmentRequired)
                TextButton(
                  onPressed: controller.skipPlanEnrollment,
                  child: const Text('Skip for now'),
                ),
            ],
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator(color: _brand))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // ---- Razorpay online payment "coming soon" notice ----
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBD3FF)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.lock_clock_outlined,
                              color: _brand, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Online card payment is coming soon. For now, request an upgrade and pay offline — admin will activate it.',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF1451B0),
                                  height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ---- Current plan banner ----
                    if (controller.currentSubscription != null)
                      _CurrentPlanBanner(
                          subscription: controller.currentSubscription!),

                    // ---- Pending offline request status ----
                    if (controller.pendingOfflineRequest != null)
                      _PendingRequestCard(req: controller.pendingOfflineRequest!),

                    const SizedBox(height: 8),

                    // currency/billing toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Monthly'),
                          selected:
                              controller.selectedBillingCycle == 'monthly',
                          onSelected: (_) =>
                              controller.setBillingCycle('monthly'),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Yearly (save)'),
                          selected:
                              controller.selectedBillingCycle == 'yearly',
                          onSelected: (_) =>
                              controller.setBillingCycle('yearly'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ---- Plan cards ----
                    ...controller.plans
                        .map((p) => _PlanCard(
                              plan: p as Map<String, dynamic>,
                              isCurrent: _isCurrent(controller, p['code']),
                              isLoading: controller.isRequestingOffline,
                              billing: controller.selectedBillingCycle,
                              onRequestOffline: () async {
                                final name = p['name']?.toString() ?? 'Plan';
                                await _confirmAndRequest(
                                    controller, p['code'].toString(), name);
                              },
                            ))
                        .expand((w) => [w, const SizedBox(height: 12)]),

                    const SizedBox(height: 4),
                    Text(
                      'Admin will confirm your payment and activate the plan. In case of any query, contact support.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _sub, fontSize: 11.5),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
        );
      },
    );
  }

  bool _isCurrent(dynamic controller, dynamic code) {
    final active = controller.currentSubscription;
    final plan = active?['plan'];
    final planCode = plan is Map ? plan['code']?.toString() : null;
    if (planCode == null) return false; // free/starter fallback, don't force lock
    return planCode == code?.toString();
  }

  Future<void> _confirmAndRequest(
      SubscriptionController ctrl, String planCode, String planName) async {
    if (ctrl.pendingOfflineRequest != null) {
      Helpers.showSnackBar(
          msg:
              'You already have a pending upgrade request. Please wait for admin approval.');
      return;
    }
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Request Offline Upgrade'),
        content: Text(
            'Request \"$planName\" plan (${ctrl.selectedBillingCycle})?\n\n'
            'Admin will contact you for payment confirmation and activate the plan after approval.'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _brand, foregroundColor: Colors.white),
              onPressed: () => Get.back(result: true),
              child: const Text('Send Request')),
        ],
      ),
    );
    if (ok == true) {
      await ctrl.requestOfflineUpgrade(
          planCode: planCode, planName: planName);
    }
  }
}

class _CurrentPlanBanner extends StatelessWidget {
  const _CurrentPlanBanner({required this.subscription});
  final Map<String, dynamic> subscription;

  @override
  Widget build(BuildContext context) {
    final status = subscription['status']?.toString() ?? '';
    final plan = subscription['plan'] is Map
        ? Map<String, dynamic>.from(subscription['plan'])
        : null;
    final name = plan?['name']?.toString() ?? 'Plan';
    final limit = plan?['customer_limit']?.toString();
    final renews = subscription['renews_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F6EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBCE4CD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: _green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your plan: $name',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                if (limit != null)
                  Text('Up to $limit customers',
                      style: const TextStyle(fontSize: 12.5, color: _sub)),
                if (renews.isNotEmpty && status == 'active')
                  Text('Renews: ${_shortDate(renews)}',
                      style: const TextStyle(fontSize: 12, color: _sub)),
              ],
            ),
          ),
          if (status == 'active')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Active',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}-${d.month}-${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({required this.req});
  final Map<String, dynamic> req;

  @override
  Widget build(BuildContext context) {
    final plan = req['plan'] is Map
        ? Map<String, dynamic>.from(req['plan'])
        : null;
    final String? fromPlan =
        plan == null ? null : plan['code']?.toString();
    final code =
        ((req['requested_plan_code'] ?? '').toString().isNotEmpty)
            ? (req['requested_plan_code'] ?? '').toString()
            : (fromPlan ?? '');
    final when =
        req['created_at']?.toString().split('T').first ?? '';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3D9A4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded,
              color: Color(0xFFB45309), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your upgrade request for "$code" is pending approval.\nSubmitted: $when',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF7c4a03)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isLoading,
    required this.billing,
    required this.onRequestOffline,
  });

  final Map<String, dynamic> plan;
  final bool isCurrent;
  final bool isLoading;
  final String billing;
  final VoidCallback onRequestOffline;

  @override
  Widget build(BuildContext context) {
    final name = plan['name']?.toString() ?? 'Plan';
    final price = billing == 'yearly'
        ? plan['yearly_price']?.toString()
        : plan['monthly_price']?.toString();
    final features = plan['features'];
    final List<String> feat = features is List
        ? features.map((e) => e.toString()).toList()
        : const ['Ledger tools', 'Customer management'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isCurrent ? _brand : _line, width: isCurrent ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Current',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _brand)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('₹$price / $billing',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isCurrent ? _green : _ink)),
          const SizedBox(height: 10),
          ...feat.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: _green, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(f,
                          style: const TextStyle(fontSize: 13, color: _sub))),
                ]),
              )),
          const SizedBox(height: 12),
          // --- offline upgrade / activate CTA ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onRequestOffline,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? _green : _brand,
                disabledBackgroundColor: _brand.withValues(alpha: .4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                isCurrent ? 'Request Change' : 'Request Offline Upgrade',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (!isCurrent)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 14, color: _amber),
                  SizedBox(width: 4),
                  Text('Online payment coming soon',
                      style: TextStyle(fontSize: 11.5, color: _amber)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
