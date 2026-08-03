// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
import '../../widgets/text_theme_extension.dart';

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
  final TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<UdharController>().fetchCustomerLedger(widget.customerId);
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    TextTheme t = Theme.of(context).textTheme;

    return GetBuilder<UdharController>(
      builder: (controller) {
        final double balance = controller.currentOutstandingBalance;
        final double limit = controller.currentCreditLimit;
        final double usageText =
            limit > 0 ? (balance / limit).clamp(0.0, 1.0) : 0.0;

        return Scaffold(
          backgroundColor:
              Get.isDarkMode ? AppColors.darkBgColor : AppColors.scaffoldColor,
          appBar: CustomAppBar(
            title: widget.customerName,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.mainColor,
                  size: 20.sp,
                ),
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
              IconButton(
                icon: Icon(
                  Icons.filter_alt_outlined,
                  color: AppColors.mainColor,
                  size: 20.sp,
                ),
                onPressed: () async {
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDateRange: controller.ledgerDateRange,
                  );
                  if (picked != null) {
                    controller.setLedgerDateRange(picked);
                  } else if (controller.ledgerDateRange != null) {
                    controller.setLedgerDateRange(null); // Clear filter
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.share,
                  color: AppColors.mainColor,
                  size: 20.sp,
                ),
                onPressed: () => _shareLedgerReport(balance, storedLanguage),
              ),
              HSpace(16.w),
            ],
          ),
          body:
              controller.isLedgerLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    children: [
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
                      // ── Ledger Balance Header Card ────────────────────────
                      Container(
                        padding: EdgeInsets.all(20.r),
                        margin: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Get.isDarkMode
                                  ? AppColors.darkCardColor
                                  : AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storedLanguage['Outstanding Balance'] ??
                                  'Outstanding Due',
                              style: t.displayMedium?.copyWith(
                                color: AppColors.black50,
                                fontSize: 13.sp,
                              ),
                            ),
                            VSpace(4.h),
                            Text(
                              '₹${balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color:
                                    balance > 0
                                        ? AppColors.redColor
                                        : (balance < 0
                                            ? AppColors.greenColor
                                            : AppColors.blackColor),
                              ),
                            ),
                            VSpace(14.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Credit Limit: ₹${limit.toInt()}',
                                  style: t.bodySmall?.copyWith(
                                    color: AppColors.black50,
                                    fontSize: 11.sp,
                                  ),
                                ),
                                Text(
                                  '${(usageText * 100).toInt()}% Used',
                                  style: t.bodySmall?.copyWith(
                                    color:
                                        usageText > 0.85
                                            ? AppColors.redColor
                                            : AppColors.blackColor,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            VSpace(6.h),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: usageText,
                                minHeight: 6.h,
                                backgroundColor: AppColors.fillColorColor,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  usageText > 0.85
                                      ? AppColors.redColor
                                      : AppColors.mainColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── CTA Quick Action Panel ────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: _QuickActionBtn(
                                label: 'WhatsApp',
                                icon: Icons.chat,
                                color: const Color(0xFF25D366),
                                onTap: () => controller.sendWhatsAppReminder({
                                  'name': widget.customerName,
                                  'mobile': controller.selectedUser?['mobile'] ?? controller.selectedUser?['phone'] ?? widget.customerId,
                                  'balance': balance,
                                }),
                              ),
                            ),
                            HSpace(6.w),
                            Expanded(
                              child: _QuickActionBtn(
                                label: 'PDF Bill',
                                icon: Icons.picture_as_pdf_outlined,
                                color: Colors.deepOrangeAccent,
                                onTap: () => _showPdfBillModal(context, widget.customerId),
                              ),
                            ),
                            HSpace(6.w),
                            Expanded(
                              child: _QuickActionBtn(
                                label: 'Remind',
                                icon: Icons.notifications_active_outlined,
                                color: Colors.green,
                                onTap:
                                    () => _showReminderOptions(context, balance, storedLanguage),
                              ),
                            ),
                            HSpace(6.w),
                            Expanded(
                              child: _QuickActionBtn(
                                label: 'UPI QR',
                                icon: Icons.qr_code_scanner,
                                color: AppColors.mainColor,
                                onTap: () => _showQrDialog(context, balance),
                              ),
                            ),
                          ],
                        ),
                      ),

                      VSpace(20.h),

                      // ── Ledger History Title ──────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            storedLanguage['Transaction History'] ??
                                'Ledger Statements',
                            style: t.bodyLarge?.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      VSpace(10.h),

                      // ── Transaction Feed Timeline ─────────────────────────
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.mainColor,
                          onRefresh:
                              () => controller.fetchCustomerLedger(
                                widget.customerId,
                                showLoading: false,
                              ),
                          child:
                              controller.filteredLedgerTransactions.isEmpty
                                  ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(height: 100.h),
                                      Center(
                                        child: Text(
                                          storedLanguage['No transactions found'] ??
                                              'No transaction history',
                                          style: context.t.bodyMedium?.copyWith(
                                            color: AppColors.black50,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                  : ListView.separated(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 8.h,
                                    ),
                                    itemCount:
                                        controller.filteredLedgerTransactions.length,
                                    separatorBuilder:
                                        (_, __) => Divider(
                                          height: 1,
                                          color: AppColors.borderColor,
                                        ),
                                    itemBuilder: (context, i) {
                                      final tx =
                                          controller.filteredLedgerTransactions[i];
                                      final bool isCredit =
                                          tx['type'] ==
                                          'given'; // Credit entry (Udhar Diya)
                                      final double amount =
                                          double.tryParse(
                                            tx['amount']?.toString() ?? '',
                                          ) ??
                                          0.0;
                                      final Color amountColor =
                                          isCredit
                                              ? AppColors.redColor
                                              : AppColors.greenColor;
                                      final String directionSign =
                                          isCredit ? '+' : '-';

                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10.h,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(10.r),
                                              decoration: BoxDecoration(
                                                color: amountColor.withValues(
                                                  alpha: 0.1,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isCredit
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward,
                                                color: amountColor,
                                                size: 18.sp,
                                              ),
                                            ),
                                            HSpace(14.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tx['remarks']
                                                                ?.toString()
                                                                .isNotEmpty ==
                                                            true
                                                        ? tx['remarks']
                                                            .toString()
                                                        : (isCredit
                                                            ? 'Udhar Given'
                                                            : 'Udhar Aaya (Payment Received)'),
                                                    style: context.t.bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  VSpace(2.h),
                                                  Text(
                                                    Helpers.formatDateAndTime(tx['created_at']),
                                                    style: context.t.bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              AppColors.black50,
                                                          fontSize: 11.sp,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '$directionSign ₹${amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.bold,
                                                color: amountColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ),
                    ],
                  ),
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: EdgeInsets.only(bottom: 6.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color:
                    Get.isDarkMode
                        ? AppColors.darkCardColor
                        : AppColors.whiteColor,
                border: Border(
                  top: BorderSide(color: AppColors.borderColor, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.redColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      icon: Icon(Icons.arrow_upward_rounded, size: 18.sp),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          storedLanguage['YOU GAVE'] ?? 'YOU GAVE (₹)',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onPressed: () {
                        final userMap = controller.usersList.firstWhere(
                          (u) => u['id'].toString() == widget.customerId,
                          orElse:
                              () => {
                                "id": widget.customerId,
                                "name": widget.customerName,
                              },
                        );
                        controller.selectUser(userMap);
                        controller.setType('given');
                        Get.toNamed('/addUdharScreen');
                      },
                    ),
                  ),
                  HSpace(12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greenColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      icon: Icon(Icons.arrow_downward_rounded, size: 18.sp),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          storedLanguage['YOU GOT'] ?? 'YOU GOT (₹)',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onPressed: () {
                        final userMap = controller.usersList.firstWhere(
                          (u) => u['id'].toString() == widget.customerId,
                          orElse:
                              () => {
                                "id": widget.customerId,
                                "name": widget.customerName,
                              },
                        );
                        controller.selectUser(userMap);
                        controller.setType('received');
                        Get.toNamed('/addUdharScreen');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
      backgroundColor: Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
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
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16.sp),
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
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                  ),
                  VSpace(4.h),
                  RadioListTile<String>(
                    title: const Text('28-Day Cycle Bill (Auto)'),
                    subtitle: const Text('Generates statement for the last 28 days of credit'),
                    value: '28_days',
                    groupValue: selectedCycle,
                    activeColor: AppColors.mainColor,
                    onChanged: (val) {
                      if (val != null) setStateModal(() => selectedCycle = val);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Calendar Month Bill'),
                    subtitle: const Text('Generates statement for the current calendar month'),
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
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
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
                              : Icon(Icons.send_rounded, size: 18.sp, color: Colors.white),
                          label: Text(
                            ctrl.isGeneratingPdf ? 'Generating PDF...' : 'Send 28-Day PDF Bill',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: ctrl.isGeneratingPdf
                              ? null
                              : () async {
                                  if (selectedChannel == 'whatsapp' || selectedChannel == 'both') {
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

  void _showReminderOptions(BuildContext context, double balance, Map language) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: 20 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Send Reminder",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainColor,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.notifications, color: Colors.blue),
                title: Text("In-App Notification"),
                subtitle: Text("Send a push notification to their UdharCard app"),
                onTap: () {
                  Navigator.pop(context);
                  Get.find<UdharController>().sendPaymentReminder(widget.customerId);
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.chat_bubble, color: Colors.green),
                title: Text("WhatsApp"),
                subtitle: Text("Send a personalized WhatsApp message"),
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
        final bool isGiven = (tx['type'] ?? 'given') == 'given' || (tx['type'] == 'credit');
        final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
        final date = Helpers.formatDateAndTime(tx['created_at']);
        final remark = tx['remarks'] ?? tx['notes'] ?? '';
        
        historyMsg += "• ${isGiven ? 'Given' : 'Received'}: ₹${amt.toStringAsFixed(2)} on $date";
        if (remark.toString().isNotEmpty) {
          historyMsg += " ($remark)";
        }
        historyMsg += "\n";
      }
    }

    String message = "";
    if (outstandingBalance <= 0) {
      message = "Dear ${widget.customerName}, your current account balance with us is settled (₹0.00). Thank you for doing business with us!";
    } else {
      message = "Dear ${widget.customerName}, this is a friendly reminder that you have an outstanding payment of ₹${outstandingBalance.toStringAsFixed(2)} due with our shop. Please pay as soon as possible. Thank you!";
    }

    message += historyMsg;

    final String encodedMsg = Uri.encodeComponent(message);
    final String url = "https://wa.me/?text=$encodedMsg";
    _launchUrl(url);
  }

  void _shareLedgerReport(double outstandingBalance, Map language) {
    // Basic share statement details
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

  // ── QR Modal Display ──────────────────────────────────────────────────

  void _showQrDialog(BuildContext context, double outstanding) {
    amountController.text =
        outstanding > 0 ? outstanding.toStringAsFixed(2) : '';
    final controller = Get.find<UdharController>();

    // Initial QR generation
    if (outstanding > 0) {
      controller.generateDynamicQr(
        widget.customerId,
        outstanding.toStringAsFixed(2),
      );
      controller.startPaymentStatusListener(widget.customerId);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            controller.stopPaymentStatusListener();
          },
          child: GetBuilder<UdharController>(
            builder: (ctrl) {
              final double payAmt =
                  double.tryParse(amountController.text.trim()) ?? 0.0;
              final String upiUrl =
                  ctrl.generatedUpiUri ??
                  "upi://pay?pa=paysecure@ybl&pn=PaySecure&am=${payAmt.toStringAsFixed(2)}";

              return AlertDialog(
                backgroundColor:
                    Get.isDarkMode
                        ? AppColors.darkCardColor
                        : AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                contentPadding: EdgeInsets.all(20.r),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Collect Payments via UPI',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppThemes.getIconBlackColor(),
                      ),
                    ),
                    VSpace(14.h),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final double amt = double.tryParse(val) ?? 0.0;
                        if (amt > 0) {
                          ctrl.generateDynamicQr(
                            widget.customerId,
                            amt.toStringAsFixed(2),
                          );
                          ctrl.startPaymentStatusListener(widget.customerId);
                        } else {
                          ctrl.stopPaymentStatusListener();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter payment amount',
                        prefixIcon: const Icon(Icons.currency_rupee),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 10.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    VSpace(20.h),
                    if (payAmt > 0) ...[
                      if (ctrl.isQrLoading)
                        SizedBox(
                          height: 180.h,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else ...[
                        QrImageView(
                          data: upiUrl,
                          version: QrVersions.auto,
                          size: 180.h,
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppThemes.getIconBlackColor(),
                          ),
                        ),
                        VSpace(10.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.mainColor,
                              ),
                            ),
                            HSpace(8.w),
                            Text(
                              'Waiting for payment...',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.mainColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ] else
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: Text(
                          'Please enter a valid amount to generate the payment QR code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.black50,
                          ),
                        ),
                      ),
                    VSpace(20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          child: const Text('Close'),
                          onPressed: () {
                            ctrl.stopPaymentStatusListener();
                            Navigator.pop(ctx);
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                          ),
                          onPressed:
                              payAmt > 0 && !ctrl.isQrLoading
                                  ? () {
                                    Clipboard.setData(
                                      ClipboardData(text: upiUrl),
                                    );
                                    Get.snackbar(
                                      'UPI URL Shared',
                                      'Deep link copied to clipboard.',
                                    );
                                  }
                                  : null,
                          child: const Text(
                            'Copy Link',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.sp),
            VSpace(4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
