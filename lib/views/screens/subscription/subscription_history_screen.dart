import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../config/app_colors.dart';
import '../../../data/repositories/subscription_repo.dart';
import '../../../themes/themes.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';

class SubscriptionHistoryScreen extends StatefulWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  State<SubscriptionHistoryScreen> createState() =>
      _SubscriptionHistoryScreenState();
}

class _SubscriptionHistoryScreenState
    extends State<SubscriptionHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _history = [];
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final response = await SubscriptionRepo.getPaymentHistory();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _history = (data['data']?['history'] as List?) ?? [];
        } else {
          _errorMsg = data['message']?.toString() ?? 'Failed to load history';
        }
      } else {
        _errorMsg = 'Server error ()';
      }
    } catch (e) {
      _errorMsg = 'Unable to load payment history';
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: CustomAppBar(title: 'Payment History'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? _buildError(t)
              : _history.isEmpty
                  ? _buildEmpty(t)
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.separated(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        itemCount: _history.length,
                        separatorBuilder: (_, __) => VSpace(10.h),
                        itemBuilder: (context, index) {
                          final item = _history[index] as Map<String, dynamic>;
                          return _HistoryCard(item: item, t: t);
                        },
                      ),
                    ),
    );
  }

  Widget _buildError(TextTheme t) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 52.sp, color: AppColors.black30),
            VSpace(16.h),
            Text(
              _errorMsg!,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: AppColors.black50),
            ),
            VSpace(20.h),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(TextTheme t) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 56.sp, color: AppColors.black30),
            VSpace(16.h),
            Text(
              'No payment history',
              style: t.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.black50,
              ),
            ),
            VSpace(8.h),
            Text(
              'Your subscription payment history\nwill appear here.',
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(
                color: AppColors.black50,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final TextTheme t;
  const _HistoryCard({required this.item, required this.t});

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? '';
    final planName = item['plan_name']?.toString() ??
        (item['plan'] is Map
            ? item['plan']['name']?.toString()
            : null) ??
        'Plan';
    final amount =
        double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    final billingCycle = item['billing_cycle']?.toString() ?? 'monthly';
    final createdAt = item['created_at']?.toString() ??
        item['date']?.toString() ??
        '';

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    String statusLabel;

    switch (status.toLowerCase()) {
      case 'captured':
      case 'success':
      case 'paid':
        statusColor = AppColors.greenColor;
        statusBg = AppColors.greenColor.withValues(alpha: 0.1);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Paid';
        break;
      case 'failed':
      case 'failure':
        statusColor = AppColors.redColor;
        statusBg = AppColors.redColor.withValues(alpha: 0.1);
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Failed';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusBg = Colors.orange.withValues(alpha: 0.1);
        statusIcon = Icons.access_time_rounded;
        statusLabel = 'Pending';
        break;
      default:
        statusColor = AppColors.black50;
        statusBg = AppColors.black10;
        statusIcon = Icons.info_outline_rounded;
        statusLabel = status.isNotEmpty ? status : 'Unknown';
    }

    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: AppThemes.getFillColor(),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Get.isDarkMode
              ? AppColors.black70
              : AppColors.borderColor.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44.h,
            width: 44.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusBg,
            ),
            child: Icon(statusIcon, size: 22.sp, color: statusColor),
          ),
          HSpace(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$planName Plan',
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                VSpace(3.h),
                Text(
                  billingCycle == 'yearly' ? 'Yearly billing' : 'Monthly billing',
                  style: t.bodySmall?.copyWith(
                    color: AppThemes.getBlack50Color(),
                    fontSize: 11.sp,
                  ),
                ),
                if (createdAt.isNotEmpty) ...[
                  VSpace(2.h),
                  Text(
                    createdAt,
                    style: t.bodySmall?.copyWith(
                      color: AppThemes.getBlack50Color(),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount == 0 ? 'Free' : '₹',
                style: t.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                  color: statusColor == AppColors.greenColor
                      ? AppColors.greenColor
                      : null,
                ),
              ),
              VSpace(4.h),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
