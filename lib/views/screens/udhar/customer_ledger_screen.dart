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
  String _activeTab = "details"; // "details" (Screen 4) or "transactions" (Screen 5)
  String _txFilter = "all"; // "all", "given", "received"

  Widget _buildTxFilterChip(String filterKey, String label, bool isDark) {
    final isSelected = _txFilter == filterKey;
    Color activeColor;
    if (filterKey == 'given') {
      activeColor = const Color(0xFF2563EB);
    } else if (filterKey == 'received') {
      activeColor = const Color(0xFF16A34A);
    } else {
      activeColor = const Color(0xFF2563EB);
    }

    return InkWell(
      onTap: () => setState(() => _txFilter = filterKey),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Future<void> _callCustomer(String phone) async {
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleanPhone.isEmpty) {
      Get.snackbar('No Phone', 'Customer phone number is not available');
      return;
    }
    final Uri url = Uri.parse('tel:$cleanPhone');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not open phone dialer');
    }
  }

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

        final txList = controller.filteredLedgerTransactions;
        final postBalances = _calculatePostTxBalances(txList, balance);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: CustomAppBar(
            title: _activeTab == "details" ? "Customer Details" : widget.customerName,
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
              // PDF Statement / Bill
              IconButton(
                icon: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.mainColor,
                  size: 21.sp,
                ),
                tooltip: 'PDF Bill',
                onPressed: () => _showPdfBillModal(context, widget.customerId),
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
                    _buildSegmentedTabToggle(isDark),
                    Expanded(
                      child: _activeTab == "details"
                          ? _buildCustomerDetailsView(
                              context: context,
                              controller: controller,
                              balance: balance,
                              limit: limit,
                              usageText: usageText,
                              txList: txList,
                              storedLanguage: storedLanguage,
                              isDark: isDark,
                            )
                          : _buildTransactionsTimelineView(
                              context: context,
                              controller: controller,
                              txList: txList,
                              postBalances: postBalances,
                              balance: balance,
                              storedLanguage: storedLanguage,
                              isDark: isDark,
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
  // UI: Segmented Tab Toggle (Details vs Transactions)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSegmentedTabToggle(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = "details"),
              borderRadius: BorderRadius.circular(18.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: _activeTab == "details"
                      ? (isDark ? const Color(0xFF334155) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: _activeTab == "details"
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  "Details",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: _activeTab == "details"
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = "transactions"),
              borderRadius: BorderRadius.circular(18.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: _activeTab == "transactions"
                      ? (isDark ? const Color(0xFF334155) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: _activeTab == "transactions"
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  "Transactions",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: _activeTab == "transactions"
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI: Screen 4 - Customer Details View
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCustomerDetailsView({
    required BuildContext context,
    required UdharController controller,
    required double balance,
    required double limit,
    required double usageText,
    required List<dynamic> txList,
    required Map storedLanguage,
    required bool isDark,
  }) {
    final customer = controller.selectedUser ?? {};
    final phone = (customer['phone'] ??
            customer['mobile'] ??
            customer['contact'] ??
            customer['phone_number'] ??
            '')
        .toString();
    final effectiveLimit = limit > 0 ? limit : 10000.0;
    final available = (effectiveLimit - balance).clamp(0.0, effectiveLimit);
    final usagePercent = effectiveLimit > 0
        ? ((balance.abs() / effectiveLimit) * 100).clamp(0, 100).toInt()
        : 24;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Customer Profile Card ──
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: Text(
                    widget.customerName.isNotEmpty
                        ? widget.customerName[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customerName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    "Active",
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // ── 2. Credit Limit & Available Card ──
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Credit Limit",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "₹ ${NumberFormat('#,##,###').format(effectiveLimit.toInt())}",
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Available",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "₹ ${NumberFormat('#,##,###').format(available.toInt())}",
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D9488),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: (usagePercent / 100.0).clamp(0.0, 1.0),
                          minHeight: 6.h,
                          backgroundColor: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF0D9488)),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      "Used $usagePercent%",
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // ── 3. Outstanding Balance Card ──
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Outstanding Balance",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "₹ ${NumberFormat('#,##,###').format(balance.abs().toInt())}",
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () =>
                          _showReminderOptions(context, balance, storedLanguage),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          "3 days due",
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // 3 Circular Action Buttons: Call, WhatsApp, Collect
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRoundActionButton(
                      icon: Icons.phone_rounded,
                      label: "Call",
                      bgColor: const Color(0xFF10B981),
                      iconColor: Colors.white,
                      isDark: isDark,
                      onTap: () => _callCustomer(phone),
                    ),
                    _buildRoundActionButton(
                      icon: Icons.chat_bubble_rounded,
                      label: "WhatsApp",
                      bgColor: const Color(0xFF10B981),
                      iconColor: Colors.white,
                      isDark: isDark,
                      onTap: () => _sendWhatsAppReminder(balance, storedLanguage),
                    ),
                    _buildRoundActionButton(
                      icon: Icons.currency_rupee_rounded,
                      label: "Collect",
                      bgColor: const Color(0xFF2563EB),
                      iconColor: Colors.white,
                      isDark: isDark,
                      onTap: () {
                        controller.selectUser(customer.isNotEmpty
                            ? customer
                            : {
                                'id': widget.customerId,
                                'name': widget.customerName,
                                'phone': phone,
                              });
                        controller.setType('received');
                        Get.toNamed(RoutesName.addUdharScreen);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // ── 4. Transaction History Section ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Transaction History",
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _activeTab = "transactions";
                  });
                },
                child: Text(
                  "View All >",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          if (txList.isEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              alignment: Alignment.center,
              child: Text(
                "No transactions yet",
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ] else ...[
            ...txList.take(4).map((tx) {
              final bool isGiven = _isGivenTransaction(tx);
              final double amt =
                  double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
              final String rawDate =
                  (tx['created_at'] ?? tx['date'] ?? '').toString();
              DateTime? parsedDate = DateTime.tryParse(rawDate);
              final String dateStr = parsedDate != null
                  ? DateFormat('dd MMM yyyy').format(parsedDate)
                  : 'Recent';

              return InkWell(
                onTap: () => _showTransactionDetailsSheet(
                    context, tx is Map ? tx : {}, isGiven, amt, balance),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: BoxDecoration(
                          color: isGiven
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isGiven
                              ? Icons.currency_rupee_rounded
                              : Icons.check_rounded,
                          color: isGiven
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF16A34A),
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              isGiven ? "Udhar Added" : "Payment Received",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${isGiven ? '' : '+ '}₹ ${NumberFormat('#,##,###').format(amt.abs().toInt())}",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: isGiven
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI: Screen 5 - Connected Vertical Timeline View
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTransactionsTimelineView({
    required BuildContext context,
    required UdharController controller,
    required List<dynamic> txList,
    required Map<int, double> postBalances,
    required double balance,
    required Map storedLanguage,
    required bool isDark,
  }) {
    final totalGivenCount =
        txList.where((tx) => _isGivenTransaction(tx)).length;
    final totalReceivedCount =
        txList.where((tx) => !_isGivenTransaction(tx)).length;

    final List<MapEntry<int, dynamic>> filteredIndexedTx =
        txList.asMap().entries.where((entry) {
      if (_txFilter == 'given') return _isGivenTransaction(entry.value);
      if (_txFilter == 'received') return !_isGivenTransaction(entry.value);
      return true;
    }).toList();

    return Column(
      children: [
        // ── Transaction Filter Chips ───────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              _buildTxFilterChip("all", "All (${txList.length})", isDark),
              SizedBox(width: 8.w),
              _buildTxFilterChip(
                  "given", "Udhar Diya ($totalGivenCount)", isDark),
              SizedBox(width: 8.w),
              _buildTxFilterChip(
                  "received", "Paise Mile ($totalReceivedCount)", isDark),
            ],
          ),
        ),

        Expanded(
          child: filteredIndexedTx.isEmpty
              ? Center(
                  child: Text(
                    "No transactions found",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: filteredIndexedTx.length,
                  itemBuilder: (context, i) {
                    final originalIndex = filteredIndexedTx[i].key;
                    final tx = filteredIndexedTx[i].value;
                    final bool isGiven = _isGivenTransaction(tx);
                    final double amt =
                        double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
                    final String rawDate =
                        (tx['created_at'] ?? tx['date'] ?? '').toString();
                    DateTime? parsedDate = DateTime.tryParse(rawDate);
                    final String dateStr = parsedDate != null
                        ? DateFormat('dd MMM yyyy').format(parsedDate)
                        : 'Recent';
                    final String timeStr = parsedDate != null
                        ? DateFormat('hh:mm a').format(parsedDate)
                        : '';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vertical Connected Timeline Left Column
                        Column(
                          children: [
                            Container(
                              width: 32.r,
                              height: 32.r,
                              decoration: BoxDecoration(
                                color: isGiven
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isGiven
                                    ? Icons.currency_rupee_rounded
                                    : Icons.check_rounded,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                            ),
                            if (i < filteredIndexedTx.length - 1)
                              Container(
                                width: 2.w,
                                height: 50.h,
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                              ),
                          ],
                        ),
                        SizedBox(width: 12.w),
                        // Content Right Column
                        Expanded(
                          child: InkWell(
                            onTap: () => _showTransactionDetailsSheet(
                                context,
                                tx is Map ? tx : {},
                                isGiven,
                                amt,
                                postBalances[originalIndex] ?? balance),
                            borderRadius: BorderRadius.circular(8.r),
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isGiven
                                                ? "Udhar Added"
                                                : "Payment Received",
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (timeStr.isNotEmpty) ...[
                                            SizedBox(height: 2.h),
                                            Text(
                                              timeStr,
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        "${isGiven ? '' : '+ '}₹ ${NumberFormat('#,##,###').format(amt.abs().toInt())}",
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                          color: isGiven
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF10B981),
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
                    );
                  },
                ),
        ),

        // ── Sticky Bottom Bar: Total Outstanding ──
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Outstanding",
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    "₹ ${NumberFormat('#,##,###').format(balance.abs().toInt())}",
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFF64748B),
                    size: 18.sp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoundActionButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475467),
              ),
            ),
          ],
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

