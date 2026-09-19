// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../../utils/services/helpers.dart';
import '../../../routes/routes_name.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';

class CustomerLedgerScreen extends StatefulWidget {
  const CustomerLedgerScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  final String customerId;
  final String customerName;

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.customerId.trim().isNotEmpty) {
        Get.find<UdharController>().fetchCustomerLedger(widget.customerId);
      }
    });
  }

  /// Reliable transaction direction detector
  /// Returns TRUE if Merchant Gave Udhar (Debit Customer / Credit Ledger / You Gave)
  /// Returns FALSE if Merchant Got Payment (Credit Customer / Debit Ledger / You Got / Paisa Mila)
  bool _isGivenTransaction(dynamic tx) {
    if (tx is! Map) return false;
    final String rawType = (tx['type'] ?? '').toString().toLowerCase().trim();
    if (rawType == 'given' || rawType == 'credit') return true;
    if (rawType == 'received' || rawType == 'debit' || rawType == 'taken') return false;
    final double amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    return amt >= 0;
  }

  /// Calculates the post-transaction running balance for each transaction
  /// by backward chaining from the net current balance.
  Map<int, double> _calculatePostTxBalances(
    List<dynamic> list,
    double currentNetBalance,
  ) {
    final Map<int, double> postBalances = {};
    double running = currentNetBalance;

    for (int i = 0; i < list.length; i++) {
      final tx = list[i];
      final bool isGiven = _isGivenTransaction(tx);
      final double amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;

      postBalances[i] = running;

      // Balance before this transaction took place:
      if (isGiven) {
        running -= amt;
      } else {
        running += amt;
      }
    }

    return postBalances;
  }

  @override
  Widget build(BuildContext context) {
    final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    final bool isDark = Get.isDarkMode;

    return GetBuilder<UdharController>(
      builder: (controller) {
        final double balance = controller.currentOutstandingBalance;
        final double limit = controller.currentCreditLimit;
        final double usageText =
            limit > 0 ? (balance / limit).clamp(0.0, 1.0) : 0.0;

        // Calculate Totals for Given and Received
        double totalGiven = 0.0;
        double totalReceived = 0.0;
        for (var tx in controller.ledgerTransactions) {
          final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
          if (_isGivenTransaction(tx)) {
            totalGiven += amt;
          } else {
            totalReceived += amt;
          }
        }

        final txList = controller.filteredLedgerTransactions;
        final postBalances = _calculatePostTxBalances(txList, balance);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
          appBar: CustomAppBar(
            title: widget.customerName,
            actions: [
              // Chat Ledger View
              IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.mainColor,
                  size: 22.sp,
                ),
                tooltip: 'Chat Ledger',
                onPressed: () {
                  Get.toNamed(
                    RoutesName.chatLedgerScreen,
                    arguments: {
                      'customerId': widget.customerId,
                      'customerName': widget.customerName,
                    },
                  );
                },
              ),
              // Filter by Date Range
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_alt_outlined,
                      color: AppColors.mainColor,
                      size: 22.sp,
                    ),
                    tooltip: 'Date Filter',
                    onPressed: () async {
                      final DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: controller.ledgerDateRange,
                      );
                      if (picked != null) {
                        controller.setLedgerDateRange(picked);
                      }
                    },
                  ),
                  if (controller.ledgerDateRange != null)
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: BoxDecoration(
                          color: AppColors.redColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              // Share Statement
              IconButton(
                icon: Icon(
                  Icons.share_rounded,
                  color: AppColors.mainColor,
                  size: 21.sp,
                ),
                tooltip: 'Share Statement',
                onPressed: () => _shareLedgerReport(balance, storedLanguage),
              ),
              HSpace(8.w),
            ],
          ),
          body: controller.isLedgerLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // ── Outstanding Balance Summary Card ────────────────────
                    _buildOutstandingCard(
                      context: context,
                      balance: balance,
                      limit: limit,
                      usageText: usageText,
                      totalGiven: totalGiven,
                      totalReceived: totalReceived,
                      isDark: isDark,
                    ),

                    // ── Quick Actions Row (WhatsApp, PDF Bill, Remind, QR) ─
                    _buildQuickActionRow(
                      context: context,
                      controller: controller,
                      balance: balance,
                      storedLanguage: storedLanguage,
                      isDark: isDark,
                    ),

                    // ── Active Date Filter Chip (if active) ─────────────────
                    if (controller.ledgerDateRange != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.mainColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 12.sp, color: AppColors.mainColor),
                                  SizedBox(width: 6.w),
                                  Text(
                                    "${DateFormat('dd MMM').format(controller.ledgerDateRange!.start)} - ${DateFormat('dd MMM').format(controller.ledgerDateRange!.end)}",
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.mainColor,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  GestureDetector(
                                    onTap: () => controller.setLedgerDateRange(null),
                                    child: Icon(Icons.close_rounded, size: 14.sp, color: AppColors.mainColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    VSpace(12.h),

                    // ── Khatabook-Style Ledger Table Header ─────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                "ENTRIES (तारीख एवं विवरण)",
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.redColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                "आपने दिया (₹)",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.redColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.greenColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                "मिला (₹)",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.greenColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    VSpace(6.h),

                    // ── Transaction Feed List ───────────────────────────────
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.mainColor,
                        onRefresh: () => controller.fetchCustomerLedger(
                          widget.customerId,
                          showLoading: false,
                        ),
                        child: txList.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: 80.h),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.receipt_long_rounded,
                                          size: 54.sp,
                                          color: isDark ? Colors.white24 : Colors.black26,
                                        ),
                                        VSpace(12.h),
                                        Text(
                                          storedLanguage['No transactions found'] ??
                                              'No transactions yet',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.black50,
                                          ),
                                        ),
                                        VSpace(4.h),
                                        Text(
                                          'Niche diye gaye buttons se pehli entry karein',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: isDark ? Colors.white38 : AppColors.black50,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                                itemCount: txList.length,
                                itemBuilder: (context, i) {
                                  final tx = txList[i];
                                  final bool isGiven = _isGivenTransaction(tx);
                                  final double amount = double.tryParse(
                                        tx['amount']?.toString() ?? '',
                                      ) ??
                                      0.0;
                                  final double postBal = postBalances[i] ?? balance;

                                  return _buildLedgerTransactionCard(
                                    context: context,
                                    tx: tx,
                                    isGiven: isGiven,
                                    amount: amount,
                                    postBalance: postBal,
                                    isDark: isDark,
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: _buildBottomActionBar(controller, isDark),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI Component: Outstanding Summary Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOutstandingCard({
    required BuildContext context,
    required double balance,
    required double limit,
    required double usageText,
    required double totalGiven,
    required double totalReceived,
    required bool isDark,
  }) {
    final bool isDue = balance > 0;
    final bool isAdvance = balance < 0;
    final Color statusColor = isDue
        ? AppColors.redColor
        : (isAdvance ? AppColors.greenColor : const Color(0xFF64748B));

    final String statusLabel = isDue
        ? "LENE HAIN (बाकी लेना है)"
        : (isAdvance ? "DENE HAIN (एडवांस मिला)" : "HISAB BARABAR (चुकता)");

    final String statusSubtitle = isDue
        ? "${widget.customerName} से कुल ₹${balance.toStringAsFixed(2)} लेना बाकी है"
        : (isAdvance
            ? "${widget.customerName} का ₹${balance.abs().toStringAsFixed(2)} एडवांस जमा है"
            : "पूरा हिसाब चुकता है • कोई बकाया नहीं");

    return Container(
      padding: EdgeInsets.all(16.r),
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDue
              ? AppColors.redColor.withValues(alpha: 0.25)
              : (isDark ? Colors.white12 : AppColors.borderColor),
          width: isDue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Label & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LEADGER BALANCE (कुल हिसाब)',
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDue
                          ? Icons.arrow_outward_rounded
                          : (isAdvance ? Icons.arrow_downward_rounded : Icons.check_circle_outline_rounded),
                      color: statusColor,
                      size: 13.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          VSpace(6.h),

          // Big Net Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${balance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  statusSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : AppColors.black50,
                  ),
                ),
              ),
            ],
          ),

          VSpace(12.h),
          Divider(height: 1, color: isDark ? Colors.white12 : AppColors.borderColor),
          VSpace(10.h),

          // Two-Column Breakdown: Total Given vs Total Received
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: AppColors.redColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_upward_rounded, size: 13.sp, color: AppColors.redColor),
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'कुल दिया (Gave)',
                          style: TextStyle(fontSize: 10.5.sp, color: isDark ? Colors.white60 : AppColors.black50),
                        ),
                        Text(
                          '₹${totalGiven.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.redColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28.h, color: isDark ? Colors.white12 : AppColors.borderColor),
              SizedBox(width: 12.w),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: AppColors.greenColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_downward_rounded, size: 13.sp, color: AppColors.greenColor),
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'कुल मिला (Got)',
                          style: TextStyle(fontSize: 10.5.sp, color: isDark ? Colors.white60 : AppColors.black50),
                        ),
                        Text(
                          '₹${totalReceived.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.greenColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          VSpace(10.h),

          // Credit Limit Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Credit Limit: ₹${limit.toInt()}',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.black50,
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(usageText * 100).toInt()}% Used',
                style: TextStyle(
                  color: usageText > 0.85 ? AppColors.redColor : (isDark ? Colors.white70 : AppColors.black80),
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          VSpace(4.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: usageText,
              minHeight: 5.h,
              backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                usageText > 0.85 ? AppColors.redColor : AppColors.mainColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI Component: Quick Action Row (WhatsApp, PDF Bill, Remind, Merchant QR)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionRow({
    required BuildContext context,
    required UdharController controller,
    required double balance,
    required Map storedLanguage,
    required bool isDark,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionBtn(
              label: 'WhatsApp',
              subLabel: '1-Tap Pay',
              icon: Icons.chat_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
              onTap: () => controller.sendWhatsAppReminder({
                'name': widget.customerName,
                'mobile': controller.selectedUser?['mobile'] ??
                    controller.selectedUser?['phone'] ??
                    widget.customerId,
                'balance': balance,
              }),
            ),
          ),
          HSpace(8.w),
          Expanded(
            child: _QuickActionBtn(
              label: 'PDF Bill',
              subLabel: 'Statement',
              icon: Icons.picture_as_pdf_rounded,
              color: const Color(0xFFF97316),
              isDark: isDark,
              onTap: () => _showPdfBillModal(context, widget.customerId),
            ),
          ),
          HSpace(8.w),
          Expanded(
            child: _QuickActionBtn(
              label: 'Remind',
              subLabel: 'In-App/SMS',
              icon: Icons.notifications_active_rounded,
              color: const Color(0xFF0EA5E9),
              isDark: isDark,
              onTap: () => _showReminderOptions(context, balance, storedLanguage),
            ),
          ),
          HSpace(8.w),
          Expanded(
            child: _QuickActionBtn(
              label: 'QR Pay',
              subLabel: 'Merchant QR',
              icon: Icons.qr_code_2_rounded,
              color: AppColors.mainColor,
              isDark: isDark,
              onTap: () {
                Get.toNamed(RoutesName.qrCodeScreen);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI Component: Transaction Card (Khatabook Style - High Clarity)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLedgerTransactionCard({
    required BuildContext context,
    required Map tx,
    required bool isGiven,
    required double amount,
    required double postBalance,
    required bool isDark,
  }) {
    final Color badgeColor = isGiven ? AppColors.redColor : AppColors.greenColor;
    final Color badgeBg = isGiven ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final String directionSign = isGiven ? '+' : '-';
    final String directionLabel = isGiven ? 'आपने दिया (YOU GAVE)' : 'आपको मिला (YOU GOT)';
    final IconData directionIcon = isGiven ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded;

    final String remarks = (tx['remarks'] ?? tx['notes'] ?? '').toString().trim();
    final String paymentMethod = (tx['payment_method'] ?? 'cash').toString().toUpperCase();
    final bool hasBill = tx['bill_image'] != null || tx['bill_image_path'] != null;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Color Strip
              Container(
                width: 4.w,
                color: badgeColor,
              ),

              // Main Transaction Content
              Expanded(
                child: InkWell(
                  onTap: () => _showTransactionDetailsSheet(context, tx, isGiven, amount, postBalance),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Direction Badge & Large Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(directionIcon, size: 13.sp, color: badgeColor),
                                  SizedBox(width: 4.w),
                                  Text(
                                    directionLabel,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w800,
                                      color: badgeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$directionSign ₹${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16.5.sp,
                                fontWeight: FontWeight.w900,
                                color: badgeColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),

                        VSpace(8.h),

                        // Row 2: Remarks / Note & Optional Bill Tag
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                remarks.isNotEmpty
                                    ? remarks
                                    : (isGiven ? 'उधार सामान / बिक्री' : 'पेमेंट / जमा प्राप्त'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (hasBill)
                              Container(
                                margin: EdgeInsets.only(left: 6.w),
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.receipt_rounded, size: 11.sp, color: Colors.orange.shade800),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Bill',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        VSpace(8.h),
                        Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                        VSpace(6.h),

                        // Row 3: Date/Time + Payment Mode & Post-Tx Running Balance
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12.sp,
                                  color: isDark ? Colors.white38 : AppColors.black50,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  Helpers.formatDateAndTime(tx['created_at']),
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : AppColors.black50,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    paymentMethod,
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                postBalance > 0
                                    ? 'बैलेंस: ₹${postBalance.toStringAsFixed(2)} बाकी'
                                    : (postBalance < 0
                                        ? 'बैलेंस: ₹${postBalance.abs().toStringAsFixed(2)} जमा'
                                        : 'बैलेंस: चुकता'),
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI Component: Bottom Navigation Bar (YOU GAVE / YOU GOT Buttons)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomActionBar(UdharController controller, bool isDark) {
    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: 6.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardColor : AppColors.whiteColor,
          border: Border(
            top: BorderSide(color: isDark ? Colors.white12 : AppColors.borderColor, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            // YOU GAVE (उधार दिया - लाल बटन)
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.redColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () {
                  final userMap = controller.usersList.firstWhere(
                    (u) =>
                        (u['id'] ?? u['source_id'] ?? u['user_id'] ?? '')
                            .toString() ==
                        widget.customerId,
                    orElse: () => {
                      "id": widget.customerId,
                      "name": widget.customerName,
                    },
                  );
                  controller.selectUser(userMap);
                  controller.setType('given');
                  Get.toNamed(RoutesName.addUdharScreen);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward_rounded, size: 17.sp, color: Colors.white),
                        SizedBox(width: 4.w),
                        Text(
                          'आपने दिया (YOU GAVE)',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'उधार / सामान दिया',
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            HSpace(10.w),

            // YOU GOT (पैसा मिला - हरा बटन)
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () {
                  final userMap = controller.usersList.firstWhere(
                    (u) =>
                        (u['id'] ?? u['source_id'] ?? u['user_id'] ?? '')
                            .toString() ==
                        widget.customerId,
                    orElse: () => {
                      "id": widget.customerId,
                      "name": widget.customerName,
                    },
                  );
                  controller.selectUser(userMap);
                  controller.setType('received');
                  Get.toNamed(RoutesName.addUdharScreen);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_downward_rounded, size: 17.sp, color: Colors.white),
                        SizedBox(width: 4.w),
                        Text(
                          'आपको मिला (YOU GOT)',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'पैसा / पेमेंट मिला',
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Transaction Details BottomSheet on Card Tap
  // ───────────────────────────────────────────────────────────────────────────
  void _showTransactionDetailsSheet(
    BuildContext context,
    Map tx,
    bool isGiven,
    double amount,
    double postBalance,
  ) {
    final bool isDark = Get.isDarkMode;
    final String remarks = (tx['remarks'] ?? tx['notes'] ?? '').toString().trim();
    final String paymentMethod = (tx['payment_method'] ?? 'cash').toString().toUpperCase();
    final String? billImg = tx['bill_image']?.toString() ?? tx['bill_image_path']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            VSpace(16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Receipt',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.black80,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            VSpace(8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: (isGiven ? AppColors.redColor : AppColors.greenColor).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: (isGiven ? AppColors.redColor : AppColors.greenColor).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isGiven ? 'आपने दिया (YOU GAVE)' : 'आपको मिला (YOU GOT)',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: isGiven ? AppColors.redColor : AppColors.greenColor,
                    ),
                  ),
                  VSpace(4.h),
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w900,
                      color: isGiven ? AppColors.redColor : AppColors.greenColor,
                    ),
                  ),
                  VSpace(4.h),
                  Text(
                    'Customer: ${widget.customerName}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? Colors.white70 : AppColors.black50,
                    ),
                  ),
                ],
              ),
            ),
            VSpace(16.h),
            _buildDetailRow('Date & Time', Helpers.formatDateAndTime(tx['created_at']), isDark),
            _buildDetailRow('Payment Mode', paymentMethod, isDark),
            _buildDetailRow('Post-Tx Balance', '₹${postBalance.toStringAsFixed(2)} Due', isDark),
            if (remarks.isNotEmpty)
              _buildDetailRow('Remarks / Notes', remarks, isDark),

            if (billImg != null && billImg.isNotEmpty) ...[
              VSpace(12.h),
              Text(
                'Attached Bill Receipt:',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
              VSpace(6.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: billImg.startsWith('http')
                    ? Image.network(billImg, height: 120.h, fit: BoxFit.cover)
                    : Image.file(File(billImg), height: 120.h, fit: BoxFit.cover),
              ),
            ],

            VSpace(18.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                icon: const Icon(Icons.chat_rounded, color: Colors.white),
                label: const Text(
                  'Share This Receipt on WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  final msg = "Namaste ${widget.customerName} ji 🙏\n\n"
                      "Udhar Card Receipt:\n"
                      "${isGiven ? 'Maine Diya (Udhar)' : 'Paisa Mila (Payment)'}: ₹${amount.toStringAsFixed(2)}\n"
                      "Date: ${Helpers.formatDateAndTime(tx['created_at'])}\n"
                      "Current Balance: ₹${postBalance.toStringAsFixed(2)}\n\n"
                      "Thank you!";
                  _launchUrl("https://wa.me/?text=${Uri.encodeComponent(msg)}");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white54 : AppColors.black50,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.black80,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helper Modals & Services
  // ───────────────────────────────────────────────────────────────────────────
  void _showPdfBillModal(BuildContext context, String customerId) {
    String selectedChannel = 'both'; // 'whatsapp', 'email', 'both'
    String selectedCycle = '28_days'; // '28_days', 'calendar_month'

    final controller = Get.find<UdharController>();
    final bool isOverdue = controller.isCustomerOverdue28Days();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      backgroundColor:
          Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.r,
                right: 20.r,
                top: 20.r,
                bottom: 20.r + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Generate & Send PDF Bill',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppThemes.getIconBlackColor(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  if (isOverdue) ...[
                    VSpace(6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                            size: 16.sp,
                          ),
                          HSpace(6.w),
                          Expanded(
                            child: Text(
                              'Automatic Alert: Unpaid Udhar exceeded 28-day cycle!',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  VSpace(10.h),
                  Text(
                    'Billing Cycle:',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  VSpace(4.h),
                  RadioListTile<String>(
                    title: const Text('28-Day Cycle Bill (Auto)'),
                    subtitle: const Text(
                      'Generates statement for the last 28 days of credit',
                    ),
                    value: '28_days',
                    groupValue: selectedCycle,
                    activeColor: AppColors.mainColor,
                    onChanged: (val) {
                      if (val != null) setStateModal(() => selectedCycle = val);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Calendar Month Bill'),
                    subtitle: const Text(
                      'Generates statement for the current calendar month',
                    ),
                    value: 'calendar_month',
                    groupValue: selectedCycle,
                    activeColor: AppColors.mainColor,
                    onChanged: (val) {
                      if (val != null) setStateModal(() => selectedCycle = val);
                    },
                  ),
                  VSpace(10.h),
                  Text(
                    'Dispatch Channels:',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  VSpace(4.h),
                  RadioListTile<String>(
                    title: const Text('Both WhatsApp & Email PDF'),
                    value: 'both',
                    groupValue: selectedChannel,
                    activeColor: AppColors.mainColor,
                    onChanged: (val) {
                      if (val != null) setStateModal(() => selectedChannel = val);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('WhatsApp PDF Only'),
                    value: 'whatsapp',
                    groupValue: selectedChannel,
                    activeColor: AppColors.mainColor,
                    onChanged: (val) {
                      if (val != null) setStateModal(() => selectedChannel = val);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Email PDF Only'),
                    value: 'email',
                    groupValue: selectedChannel,
                    activeColor: AppColors.mainColor,
                    onChanged: (val) {
                      if (val != null) setStateModal(() => selectedChannel = val);
                    },
                  ),
                  VSpace(16.h),
                  GetBuilder<UdharController>(
                    builder: (ctrl) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrangeAccent,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          icon: ctrl.isGeneratingPdf
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  size: 18.sp,
                                  color: Colors.white,
                                ),
                          label: Text(
                            ctrl.isGeneratingPdf
                                ? 'Generating PDF...'
                                : 'Send 28-Day PDF Bill',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: ctrl.isGeneratingPdf
                              ? null
                              : () async {
                                  if (selectedChannel == 'whatsapp' ||
                                      selectedChannel == 'both') {
                                    Helpers.checkAndForcePhoneVerification(
                                      context,
                                      onVerified: () async {
                                        Navigator.pop(ctx);
                                        await ctrl.generateAndSendPdfBill(
                                          customerId,
                                          channel: selectedChannel,
                                          cycle: selectedCycle,
                                        );
                                      },
                                    );
                                  } else {
                                    Navigator.pop(ctx);
                                    await ctrl.generateAndSendPdfBill(
                                      customerId,
                                      channel: selectedChannel,
                                      cycle: selectedCycle,
                                    );
                                  }
                                },
                        ),
                      );
                    },
                  ),
                  VSpace(10.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReminderOptions(
    BuildContext context,
    double balance,
    Map language,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 20.h,
            bottom: 20.h + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Send Payment Reminder",
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainColor,
                ),
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications, color: Colors.blue),
                ),
                title: const Text("In-App Notification"),
                subtitle: const Text(
                  "Send a push notification to their UdharCard app",
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.find<UdharController>().sendPaymentReminder(
                    widget.customerId,
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble, color: Colors.green),
                ),
                title: const Text("WhatsApp Message"),
                subtitle: const Text("Send a personalized WhatsApp message with 1-tap UPI payment"),
                onTap: () {
                  Navigator.pop(context);
                  Helpers.checkAndForcePhoneVerification(
                    context,
                    onVerified: () => _sendWhatsAppReminder(balance, language),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendWhatsAppReminder(double outstandingBalance, Map language) {
    final controller = Get.find<UdharController>();
    final txList = controller.filteredLedgerTransactions;

    String historyMsg = "";
    if (txList.isNotEmpty) {
      historyMsg = "\n\n*Recent Transactions:*\n";
      final int count = txList.length > 5 ? 5 : txList.length;
      for (int i = 0; i < count; i++) {
        final tx = txList[i];
        final bool isGiven = _isGivenTransaction(tx);
        final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
        final date = Helpers.formatDateAndTime(tx['created_at']);
        final remark = tx['remarks'] ?? tx['notes'] ?? '';

        historyMsg +=
            "• ${isGiven ? 'Udhar Diya' : 'Paisa Mila'}: ₹${amt.toStringAsFixed(2)} on $date";
        if (remark.toString().isNotEmpty) {
          historyMsg += " ($remark)";
        }
        historyMsg += "\n";
      }
    }

    final String shopName =
        (HiveHelp.read('shop_name') ?? 'Udhar Card Merchant').toString().trim();
    final String merchantUpi = (HiveHelp.read(Keys.merchantUpiId) ??
            HiveHelp.read('merchant_upi_id') ??
            'paysecure@upi')
        .toString()
        .trim();
    final String encodedShop =
        Uri.encodeComponent(shopName.isEmpty ? 'Merchant' : shopName);
    final String upiUrl =
        "upi://pay?pa=$merchantUpi&pn=$encodedShop&am=${outstandingBalance.abs()}&cu=INR";

    String message = "";
    if (outstandingBalance <= 0) {
      message =
          "Dear ${widget.customerName} ji, your account balance with *$shopName* is fully settled (₹0.00). Thank you! 🙏";
    } else {
      message =
          "Namaste ${widget.customerName} ji 🙏\n\n"
          "Aapka kul pending udhar hisab *$shopName* par *₹${outstandingBalance.toStringAsFixed(2)}* hai.\n\n"
          "📲 *1-Click UPI Payment Link:*\n"
          "$upiUrl\n\n"
          "Kripya jaldi se clear karein. Dhanyawad!\n\n"
          "*Recent Transactions:*\n";
    }

    message += historyMsg;

    final String encodedMsg = Uri.encodeComponent(message);
    final String url = "https://wa.me/?text=$encodedMsg";
    _launchUrl(url);
  }

  void _shareLedgerReport(double outstandingBalance, Map language) {
    final String text =
        "Ledger Statement for ${widget.customerName}\nTotal Outstanding: ₹${outstandingBalance.toStringAsFixed(2)}";
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied Statement',
      'Summary text copied to clipboard to share.',
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Launch Failure', 'Could not launch URL helper.');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Action Button
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final String subLabel;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
            VSpace(4.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            VSpace(1.h),
            Text(
              subLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
