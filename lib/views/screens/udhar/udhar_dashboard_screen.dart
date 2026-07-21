import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';
import '../../widgets/text_theme_extension.dart';

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
      Get.find<UdharController>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    TextTheme t = Theme.of(context).textTheme;

    return GetBuilder<UdharController>(
      builder: (controller) {
        // Calculate dynamic dashboard stats
        double totalOutstanding = 0.0;
        double totalReceived = 0.0;
        int activeCount = 0;

        for (var u in controller.usersList) {
          double bal =
              double.tryParse(u['outstanding_balance']?.toString() ?? '0') ??
              0.0;
          if (bal > 0) {
            totalOutstanding += bal;
            activeCount++;
          } else if (bal < 0) {
            totalReceived += bal.abs();
          }
        }

        // Generate activity list
        List<dynamic> recentActivity = [];
        for (var u in controller.usersList) {
          double bal =
              double.tryParse(u['outstanding_balance']?.toString() ?? '0') ??
              0.0;
          if (bal != 0) {
            recentActivity.add({
              'name': u['name'] ?? 'Customer',
              'type': bal > 0 ? 'given' : 'received',
              'amount': bal.abs(),
            });
          }
        }

        return Scaffold(
          backgroundColor:
              Get.isDarkMode ? AppColors.darkBgColor : AppColors.scaffoldColor,
          appBar: CustomAppBar(
            title:
                storedLanguage['Udhar Ledger Dashboard'] ??
                'Udhar Ledger Dashboard',
          ),
          body: RefreshIndicator(
            color: AppColors.mainColor,
            onRefresh: () => controller.fetchUsers(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Offline Banner ──────────────────────────────────
                  if (controller.isOffline)
                    Container(
                      width: double.infinity,
                      color: Colors.redAccent.withValues(alpha: 0.9),
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off,
                            color: Colors.white,
                            size: 14.sp,
                          ),
                          HSpace(6.w),
                          Text(
                            'Offline - Cached Data',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  VSpace(16.h),

                  // ── Metrics Row ─────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title:
                                storedLanguage['Pending Collection'] ??
                                'Pending Collection',
                            value: '₹${totalOutstanding.toStringAsFixed(2)}',
                            color: const Color(0xFFE53E3E), // Crimson Accent
                            icon: Icons.trending_up,
                          ),
                        ),
                        HSpace(16.w),
                        Expanded(
                          child: _MetricCard(
                            title:
                                storedLanguage['Total Received'] ??
                                'Total Received',
                            value: '₹${totalReceived.toStringAsFixed(2)}',
                            color: const Color(0xFF38A169), // Emerald Accent
                            icon: Icons.trending_down,
                          ),
                        ),
                      ],
                    ),
                  ),

                  VSpace(24.h),

                  // ── Action Buttons Row ──────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _QuickAction(
                          label:
                              storedLanguage['Add Customer'] ?? 'Add Customer',
                          icon: Icons.person_add_alt_1_outlined,
                          onTap: () => Get.toNamed('/customerListScreen'),
                        ),
                        _QuickAction(
                          label:
                              storedLanguage['Record Udhar'] ?? 'Record Udhar',
                          icon: Icons.add_circle_outline,
                          onTap: () => Get.toNamed('/addUdharScreen'),
                        ),
                        _QuickAction(
                          label:
                              storedLanguage['Customers Ledger'] ??
                              'View Directory',
                          icon: Icons.menu_book_outlined,
                          onTap: () => Get.toNamed('/customerListScreen'),
                        ),
                      ],
                    ),
                  ),

                  VSpace(28.h),

                  // ── Weekly Collection Trends ─────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storedLanguage['Weekly Collection Trends'] ??
                              'Weekly Collection Trends',
                          style: t.bodyLarge?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        VSpace(12.h),
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color:
                                Get.isDarkMode
                                    ? AppColors.darkCardColor
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.black50,
                                size: 18.sp,
                              ),
                              HSpace(8.w),
                              Expanded(
                                child: Text(
                                  storedLanguage['Trend data will appear when real transactions are available'] ??
                                      'Trend data will appear when real transactions are available.',
                                  style: TextStyle(
                                    color: AppColors.black50,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  VSpace(28.h),

                  // ── Recent Activity Timeline ─────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      storedLanguage['Recent Activity'] ?? 'Recent Activity',
                      style: t.bodyLarge?.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  VSpace(10.h),
                  recentActivity.isEmpty
                      ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: Text(
                            storedLanguage['No recent activity'] ??
                                'No recent activity',
                            style: TextStyle(color: AppColors.black50),
                          ),
                        ),
                      )
                      : ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 8.h,
                        ),
                        itemCount:
                            recentActivity.length > 5
                                ? 5
                                : recentActivity.length,
                        separatorBuilder:
                            (_, __) => Divider(
                              height: 1,
                              color: AppColors.borderColor,
                            ),
                        itemBuilder: (context, idx) {
                          final act = recentActivity[idx];
                          final bool isCredit = act['type'] == 'given';
                          final Color amtColor =
                              isCredit
                                  ? const Color(0xFFE53E3E)
                                  : const Color(0xFF38A169);

                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18.r,
                                  backgroundColor: amtColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Icon(
                                    isCredit
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: amtColor,
                                    size: 16.sp,
                                  ),
                                ),
                                HSpace(12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        act['name'],
                                        style: context.t.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      VSpace(2.h),
                                      Text(
                                        isCredit
                                            ? 'Udhar Given'
                                            : 'Udhar Aaya (Payment Collected)',
                                        style: TextStyle(
                                          color: AppColors.black50,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isCredit ? '+' : '-'} ₹${act['amount'].toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: amtColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  VSpace(24.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20.sp),
              Container(
                width: 8.h,
                height: 8.h,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          ),
          VSpace(12.h),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.black50, fontSize: 11.sp),
          ),
          VSpace(4.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: 96.w,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.mainColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.mainColor.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.mainColor, size: 24.sp),
            VSpace(6.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.mainColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
