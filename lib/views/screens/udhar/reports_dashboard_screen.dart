import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../config/app_colors.dart';
import '../../../controllers/udhar_controller.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<UdharController>().fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GetBuilder<UdharController>(
      builder: (controller) {
        final NumberFormat currency = NumberFormat.currency(
          locale: 'en_IN',
          symbol: 'Rs. ',
          decimalDigits: 2,
        );
        final double totalCredit = _toDouble(controller.reportsSummary['total_credit_given']);
        final double totalDebit = _toDouble(controller.reportsSummary['total_debit_received']);
        final double outstanding = controller.reportOutstandingCustomers.fold<double>(
          0.0,
          (sum, item) => sum + _toDouble((item as Map)['outstanding_balance']),
        );

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
          appBar: CustomAppBar(
            title: 'Reports Dashboard',
            actions: [
              IconButton(
                onPressed: () async {
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: controller.reportsDateRange,
                  );
                  if (picked != null) {
                    await controller.fetchReports(range: picked);
                  }
                },
                icon: Icon(Icons.date_range_rounded, color: AppColors.mainColor),
              ),
              IconButton(
                onPressed: controller.reportsDateRange == null
                    ? null
                    : controller.clearReportsDateRange,
                icon: Icon(Icons.filter_alt_off_rounded, color: AppColors.mainColor),
              ),
              IconButton(
                onPressed: controller.isReportsLoading ? null : controller.fetchReports,
                icon: Icon(Icons.refresh_rounded, color: AppColors.mainColor),
              ),
            ],
          ),
          body: controller.isReportsLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  color: AppColors.mainColor,
                  onRefresh: () => controller.fetchReports(),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
                    children: [
                      if (controller.reportsDateRange != null)
                        Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF172033) : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'Range: ${DateFormat('dd MMM yyyy').format(controller.reportsDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(controller.reportsDateRange!.end)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total Credit Given',
                              value: currency.format(totalCredit),
                              accent: AppColors.redColor,
                              background: const Color(0xFFFEE2E2),
                            ),
                          ),
                          HSpace(10.w),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Collections',
                              value: currency.format(totalDebit),
                              accent: AppColors.greenColor,
                              background: const Color(0xFFDCFCE7),
                            ),
                          ),
                        ],
                      ),
                      VSpace(10.h),
                      _SummaryCard(
                        title: 'Outstanding Balance',
                        value: currency.format(outstanding),
                        accent: AppColors.mainColor,
                        background: isDark ? const Color(0xFF172033) : const Color(0xFFDBEAFE),
                        fullWidth: true,
                      ),
                      VSpace(18.h),
                      _SectionCard(
                        title: 'Exports',
                        child: Column(
                          children: [
                            _ActionTile(
                              title: 'Full Ledger Statement (PDF)',
                              subtitle: 'Generate a device-openable PDF statement of the filtered ledger.',
                              icon: Icons.picture_as_pdf_rounded,
                              color: Colors.deepOrange,
                              loading: controller.isExportingReport,
                              onTap: controller.isExportingReport ? null : controller.exportFullLedgerPdf,
                            ),
                            Divider(height: 18.h),
                            _ActionTile(
                              title: 'Outstanding Balances (CSV)',
                              subtitle: 'Export top outstanding customers to CSV and open it on the device.',
                              icon: Icons.table_chart_rounded,
                              color: Colors.teal,
                              loading: controller.isExportingReport,
                              onTap: controller.isExportingReport ? null : controller.exportOutstandingCsv,
                            ),
                            if ((controller.lastGeneratedReportPath ?? '').isNotEmpty) ...[
                              Divider(height: 18.h),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Last file: ${controller.lastGeneratedReportPath}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: isDark ? Colors.white70 : AppColors.black60,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      VSpace(18.h),
                      _SectionCard(
                        title: 'Outstanding Customers',
                        trailing: '${controller.reportOutstandingCustomers.length} records',
                        child: controller.reportOutstandingCustomers.isEmpty
                            ? _EmptyState(text: 'No outstanding balances found for the selected range.')
                            : Column(
                                children: controller.reportOutstandingCustomers.take(10).map((dynamic item) {
                                  final Map customer = item as Map;
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.mainColor.withValues(alpha: 0.12),
                                      child: Text(
                                        (customer['name'] ?? 'C').toString().substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          color: AppColors.mainColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      (customer['name'] ?? 'Customer').toString(),
                                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                      (customer['phone'] ?? '-').toString(),
                                      style: TextStyle(fontSize: 11.sp),
                                    ),
                                    trailing: Text(
                                      currency.format(_toDouble(customer['outstanding_balance'])),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.redColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      VSpace(18.h),
                      _SectionCard(
                        title: 'Recent Ledger Activity',
                        trailing: '${controller.reportTransactions.length} rows',
                        child: controller.reportTransactions.isEmpty
                            ? _EmptyState(text: 'No ledger activity found for the selected range.')
                            : Column(
                                children: controller.reportTransactions.take(12).map((dynamic item) {
                                  final Map tx = item as Map;
                                  final bool isCredit = _normalizeType(tx['type']) == 'Credit';
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      isCredit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                      color: isCredit ? AppColors.redColor : AppColors.greenColor,
                                    ),
                                    title: Text(
                                      (tx['customer_name'] ?? tx['customer']?['name'] ?? 'Customer').toString(),
                                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                      '${_normalizeType(tx['type'])} • ${(tx['payment_method'] ?? 'cash').toString()} • ${(tx['created_at'] ?? '').toString()}',
                                      style: TextStyle(fontSize: 11.sp),
                                    ),
                                    trailing: Text(
                                      currency.format(_toDouble(tx['amount'])),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                        color: isCredit ? AppColors.redColor : AppColors.greenColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  String _normalizeType(dynamic rawType) {
    final String type = rawType?.toString().toLowerCase() ?? '';
    return type == 'given' || type == 'credit' ? 'Credit' : 'Debit';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.background,
    this.fullWidth = false,
  });

  final String title;
  final String value;
  final Color accent;
  final Color background;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          VSpace(8.h),
          Text(
            value,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: accent),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.black60),
                ),
            ],
          ),
          VSpace(12.h),
          child,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.loading,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: loading
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                : Icon(icon, color: color),
          ),
          HSpace(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                VSpace(4.h),
                Text(subtitle, style: TextStyle(fontSize: 11.sp, color: AppColors.black60)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.black60),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: AppColors.black60),
        ),
      ),
    );
  }
}