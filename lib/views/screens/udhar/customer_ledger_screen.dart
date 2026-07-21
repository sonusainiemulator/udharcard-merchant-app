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
                                icon: Icons.chat_bubble_outline,
                                color: Colors.green,
                                onTap:
                                    () => _sendWhatsAppReminder(
                                      balance,
                                      storedLanguage,
                                    ),
                              ),
                            ),
                            HSpace(12.w),
                            Expanded(
                              child: _QuickActionBtn(
                                label: 'UPI QR',
                                icon: Icons.qr_code_scanner,
                                color: AppColors.mainColor,
                                onTap: () => _showQrDialog(context, balance),
                              ),
                            ),
                            HSpace(12.w),
                            Expanded(
                              child: _QuickActionBtn(
                                label: 'Record',
                                icon: Icons.add_circle_outline,
                                color: AppColors.blackColor,
                                onTap: () {
                                  // Set selected customer on controller and navigate to add transaction
                                  final Map<String, dynamic> userMap =
                                      Map<String, dynamic>.from(
                                        controller.usersList.firstWhere(
                                          (u) =>
                                              u['id'].toString() ==
                                              widget.customerId,
                                          orElse:
                                              () => {
                                                "id": widget.customerId,
                                                "name": widget.customerName,
                                              },
                                        ),
                                      );
                                  controller.selectUser(userMap);
                                  Get.toNamed('/addUdharScreen');
                                },
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
                              ),
                          child:
                              controller.ledgerTransactions.isEmpty
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
                                        controller.ledgerTransactions.length,
                                    separatorBuilder:
                                        (_, __) => Divider(
                                          height: 1,
                                          color: AppColors.borderColor,
                                        ),
                                    itemBuilder: (context, i) {
                                      final tx =
                                          controller.ledgerTransactions[i];
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
                                                    tx['created_at'] ?? '',
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

  // ── Reminders & Integrations ─────────────────────────────────────────

  void _sendWhatsAppReminder(double outstandingBalance, Map language) {
    if (outstandingBalance <= 0) {
      Get.snackbar('Settled Account', 'No outstanding balance to collect.');
      return;
    }
    final String message =
        "Dear ${widget.customerName}, this is a friendly reminder that you have an outstanding payment of ₹${outstandingBalance.toStringAsFixed(2)} due with our shop. Please pay as soon as possible. Thank you!";
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
