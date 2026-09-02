import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import 'add_customer_screen.dart';

/// Khatabook-inspired, flat, fintech dashboard for the merchant.
/// Flat solid colours, NO gradients.
class UdharDashboardScreen extends StatefulWidget {
  const UdharDashboardScreen({super.key});

  @override
  State<UdharDashboardScreen> createState() => _UdharDashboardScreenState();
}

class _UdharDashboardScreenState extends State<UdharDashboardScreen> {
  // ---- Fintech flat palette (light intent) ----
  static const Color _brand = Color(0xFF0857E6); // primary blue
  static const Color _red = Color(0xFFFF3B30); // gave / outstanding (debtor)
  static const Color _green = Color(0xFF21A35C); // received / collected
  static const Color _ink = Color(0xFF1A1D2B); // primary text
  static const Color _sub = Color(0xFF7A7E8C); // secondary text
  static const Color _line = Color(0xFFEEF0F4); // hairline border
  static const Color _cardBg = Colors.white;
  static const Color _appBg = Color(0xFFF6F7F9); // neutral scaffold

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

    // Dark-mode overrides (flat, still no gradient)
    final bg = isDark ? const Color(0xFF0E1116) : _appBg;
    final card = isDark ? const Color(0xFF171B23) : _cardBg;
    final cardBorder = isDark ? const Color(0xFF272C37) : _line;
    final ink = isDark ? Colors.white : _ink;
    final sub = isDark ? const Color(0xFF9AA0AC) : _sub;

    return GetBuilder<UdharController>(
      builder: (controller) {
        // ---- compute same business stats ----
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
                  (u['total_given'] ??
                          u['total_diya'] ??
                          (bal > 0 ? bal : 0))
                      .toString()) ??
              0.0;
          double received = double.tryParse(
                  (u['total_received'] ??
                          u['total_mila'] ??
                          (bal < 0 ? bal.abs() : 0))
                      .toString()) ??
              0.0;
          totalDiya += given;
          totalMila += received;
          if (bal != 0) activeDebtors++;
        }
        final double pendingBalance = totalDiya - totalMila;

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

        final fmt = _fmt;
        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: card,
            surfaceTintColor: card,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            leadingWidth: 24.w,
            titleSpacing: 20.w,
            title: Text(
              storedLanguage['Udhar Ledger Dashboard'] ?? 'Ledger',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ),
          body: RefreshIndicator(
            color: _brand,
            onRefresh: () => controller.fetchUsers(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
              children: [
                // ---------- Two main Khatabook-style balance cards ----------
                Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        label: 'Total Diya',
                        subtitle: 'gaya udhaar',
                        value: '₹${fmt(totalDiya)}',
                        valueColor: _red,
                        icon: Icons.north_east_rounded,
                        card: card,
                        border: cardBorder,
                        sub: sub,
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _BalanceCard(
                        label: 'Total Mila',
                        subtitle: 'vapas aaya',
                        value: '₹${fmt(totalMila)}',
                        valueColor: _green,
                        icon: Icons.south_west_rounded,
                        card: card,
                        border: cardBorder,
                        sub: sub,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                // ---------- Pending / store summary strip ----------
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: _red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: _red.withValues(alpha: 0.16)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions_rounded,
                          color: _red, size: 18.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          pendingBalance >= 0
                              ? '₹${fmt(pendingBalance)} pending across your store'
                              : '₹${fmt(pendingBalance.abs())} excess collected',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFFF8A80)
                                : _red,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (activeDebtors > 0)
                        Text(
                          '$activeDebtors khata',
                          style: TextStyle(
                            color: sub,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

                // ---------- Prominent Add-Entry CTA ----------
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        openAddCustomerScreen(storedLanguage: storedLanguage),
                    icon: Icon(Icons.add_rounded, size: 22.sp),
                    label: Text(
                      storedLanguage['New Entry'] ?? 'New Khata / Entry',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),

                // ---------- Quick actions (flat tiles) ----------
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Add Customer',
                        accent: _brand,
                        card: card,
                        border: cardBorder,
                        ink: ink,
                        sub: sub,
                        onTap: () => openAddCustomerScreen(
                          storedLanguage: storedLanguage,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.mic_none_rounded,
                        label: 'Voice Udhar',
                        accent: const Color(0xFF7C59FF),
                        card: card,
                        border: cardBorder,
                        ink: ink,
                        sub: sub,
                        onTap: () => controller.openVoiceEntryWithSoftGate(),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.menu_book_rounded,
                        label: 'Directory',
                        accent: const Color(0xFF0FA47A),
                        card: card,
                        border: cardBorder,
                        ink: ink,
                        sub: sub,
                        onTap: () =>
                            Get.toNamed(RoutesName.customerListScreen),
                      ),
                    ),
                  ],
                ),

                // ---------- Recent activity ----------
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      storedLanguage['Recent Activity'] ??
                          'Recent Activity',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Get.toNamed(RoutesName.customerListScreen),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: _brand,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                if (recentActivity.isEmpty)
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 36.sp, color: sub),
                        SizedBox(height: 10.h),
                        Text(
                          storedLanguage['No recent activity'] ??
                              'No khata entries yet',
                          style: TextStyle(
                            color: ink,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Tap "New Entry" to start your first khata.',
                          style: TextStyle(
                            color: sub,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...recentActivity
                      .take(6)
                      .map((act) => _ActivityRow(
                            name: act['name'],
                            isCredit: act['type'] == 'given',
                            amount: act['amount'],
                            card: card,
                            border: cardBorder,
                            ink: ink,
                            sub: sub,
                          ))
                      .expand((w) => [
                            w,
                            SizedBox(height: 8.h),
                          ]),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(0);
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.card,
    required this.border,
    required this.sub,
    required this.isDark,
  });

  final String label;
  final String subtitle;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color card, border, sub;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : const Color(0xFF1A1D2B);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(7.r),
                decoration: BoxDecoration(
                  color: valueColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: valueColor, size: 15.sp),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12.sp, color: sub),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 26.sp,
                height: 1,
                fontWeight: FontWeight.w800,
                color: ink,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.sp, color: sub),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.card,
    required this.border,
    required this.ink,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Color card, border, ink, sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: accent, size: 18.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Quick action',
                style: TextStyle(fontSize: 9.sp, color: sub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.name,
    required this.isCredit,
    required this.amount,
    required this.card,
    required this.border,
    required this.ink,
    required this.sub,
  });

  final String name;
  final bool isCredit;
  final dynamic amount;
  final Color card, border, ink, sub;

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF21A35C);
    final red = const Color(0xFFFF3B30);
    final ac = isCredit ? red : green;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(9.r),
            decoration: BoxDecoration(
              color: ac.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: ac,
              size: 17.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isCredit ? 'You gave (udhaar diya)' : 'You received (mila)',
                  style: TextStyle(color: sub, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          Text(
            isCredit ? '-₹${amount.toStringAsFixed(0)}' : '+₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: ac,
            ),
          ),
        ],
      ),
    );
  }
}
