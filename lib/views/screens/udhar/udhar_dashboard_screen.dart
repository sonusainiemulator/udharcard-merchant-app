import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import 'add_customer_screen.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';

class UdharDashboardScreen extends StatefulWidget {
  const UdharDashboardScreen({super.key});

  @override
  State<UdharDashboardScreen> createState() => _UdharDashboardScreenState();
}

class _UdharDashboardScreenState extends State<UdharDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<UdharController>()) {
        Get.find<UdharController>().fetchUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};

    return GetBuilder<UdharController>(
      builder: (controller) {
        // Calculate dynamic dashboard stats
        double totalDiya = 0.0;
        double totalMila = 0.0;
        int activeDebtors = 0;

        for (var u in controller.usersList) {
          double bal =
              double.tryParse(u['outstanding_balance']?.toString() ??
                      u['balance']?.toString() ??
                      '0') ??
                  0.0;
          double given = double.tryParse(
                  (u['total_given'] ?? u['total_diya'] ?? (bal > 0 ? bal : 0))
                      .toString()) ??
              0.0;
          double received = double.tryParse(
                  (u['total_received'] ?? u['total_mila'] ?? (bal < 0 ? bal.abs() : 0))
                      .toString()) ??
              0.0;

          totalDiya += given;
          totalMila += received;
          if (bal != 0) {
            activeDebtors++;
          }
        }
        final double pendingBalance = totalDiya - totalMila;

        // Generate activity list
        List<dynamic> recentActivity = [];
        for (var u in controller.usersList) {
          double bal =
              double.tryParse(u['outstanding_balance']?.toString() ??
                      u['balance']?.toString() ??
                      '0') ??
                  0.0;
          if (bal != 0) {
            recentActivity.add({
              'id': u['id'] ?? u['user_id'] ?? '',
              'name': u['name'] ?? u['customer_name'] ?? 'Customer',
              'type': bal > 0 ? 'given' : 'received',
              'amount': bal.abs(),
            });
          }
        }

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
          appBar: CustomAppBar(
            title: storedLanguage['Udhar Ledger Dashboard'] ??
                'Ledger Overview',
          ),
          body: RefreshIndicator(
            color: AppColors.mainColor,
            onRefresh: () => controller.fetchUsers(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Subscription Plan Usage Banner ─────────────────────
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: controller.customerLimitState.isAtOrOverLimit
                          ? const Color(0xFFFEF3C7)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: controller.customerLimitState.isAtOrOverLimit
                            ? const Color(0xFFF59E0B)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.customerLimitState.summaryLabel,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                          ),
                        ),
                        if (controller.customerLimitState.isNearLimit)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              controller.customerLimitState.isAtOrOverLimit
                                  ? 'Soft-gating active: Add customer remains enabled temporarily.'
                                  : 'You are near plan limit. Upgrade recommended.',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Offline Warning Banner ──────────────────────────────
                  if (controller.isOffline)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.symmetric(
                          vertical: 8.h, horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              color: Colors.white, size: 16.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'No internet — Realtime ledger sync paused',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Hero 3-Metric Balance Banner ───────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0B1220), const Color(0xFF172033)]
                            : [const Color(0xFF0F172A), const Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22.r),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.38)
                              : const Color(0xFF0F172A).withValues(alpha: 0.18),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -18,
                          top: -16,
                          child: Container(
                            width: 110.r,
                            height: 110.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF38BDF8).withValues(alpha: 0.20),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6.r),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Color(0xFF7DD3FC),
                                        size: 16,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      "Ledger snapshot",
                                      style: TextStyle(
                                        color: const Color(0xFFE2E8F0),
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    "$activeDebtors active",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              pendingBalance >= 0
                                  ? "₹${pendingBalance.toStringAsFixed(0)} pending across your store"
                                  : "₹${pendingBalance.abs().toStringAsFixed(0)} excess collected",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21.sp,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "Track gives, receives, and settlements from one clean control panel.",
                              style: TextStyle(
                                color: const Color(0xFFCBD5E1),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _SummaryMetricPill(
                                    label: "Total Diya",
                                    value: "₹${totalDiya.toStringAsFixed(0)}",
                                    accent: const Color(0xFFF87171),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: _SummaryMetricPill(
                                    label: "Total Mila",
                                    value: "₹${totalMila.toStringAsFixed(0)}",
                                    accent: const Color(0xFF34D399),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: _SummaryMetricPill(
                                    label: "Pending",
                                    value: "₹${pendingBalance.abs().toStringAsFixed(0)}",
                                    accent: const Color(0xFF7DD3FC),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => Get.toNamed(RoutesName.customerListScreen),
                                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                                    label: const Text('Open ledgers'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF0F172A),
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14.r),
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => openAddCustomerScreen(
                                      storedLanguage: storedLanguage,
                                    ),
                                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                    label: const Text('Add customer'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.24),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14.r),
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 18.h),

                  // ── Quick Actions Grid ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          label: 'Add Customer',
                          subtitle: '+ New Entry',
                          icon: Icons.person_add_alt_1_rounded,
                          color: const Color(0xFF0284C7),
                          onTap: () => openAddCustomerScreen(
                            storedLanguage: storedLanguage,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _QuickActionButton(
                          label: 'Voice Udhar',
                          subtitle: '🎙️ Talk & Post',
                          icon: Icons.mic_rounded,
                          color: const Color(0xFF6366F1),
                          onTap: () =>
                              controller.openVoiceEntryWithSoftGate(),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _QuickActionButton(
                          label: 'Directory',
                          subtitle: 'View Ledgers',
                          icon: Icons.menu_book_rounded,
                          color: const Color(0xFF10B981),
                          onTap: () =>
                              Get.toNamed(RoutesName.customerListScreen),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 22.h),

                  // ── Recent Activity Feed ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        storedLanguage['Recent Activity'] ??
                            'Recent Ledger Activity',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Get.toNamed(RoutesName.customerListScreen),
                        child: Text(
                          "View All",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  recentActivity.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24.r),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.history_toggle_off_rounded,
                                  size: 40.sp, color: const Color(0xFF94A3B8)),
                              SizedBox(height: 8.h),
                              Text(
                                storedLanguage['No recent activity'] ??
                                    'No recent ledger activity recorded',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: recentActivity.length > 6
                              ? 6
                              : recentActivity.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8.h),
                          itemBuilder: (context, idx) {
                            final act = recentActivity[idx];
                            final bool isCredit = act['type'] == 'given';
                            final Color amtColor = isCredit
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981);

                            return Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18.r,
                                    backgroundColor:
                                        amtColor.withValues(alpha: 0.12),
                                    child: Icon(
                                      isCredit
                                          ? Icons.arrow_outward_rounded
                                          : Icons.south_west_rounded,
                                      color: amtColor,
                                      size: 16.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          act['name'],
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          isCredit
                                              ? 'Udhar Diya (+ Credit)'
                                              : 'Vasooli (✓ Collected)',
                                          style: TextStyle(
                                            color: const Color(0xFF64748B),
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${act['amount'].toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                      color: amtColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color, size: 16.sp),
            ),
            VSpace(6.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetricPill extends StatelessWidget {
  const _SummaryMetricPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFFCBD5E1),
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
