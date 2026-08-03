import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../../utils/services/helpers.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';

class ChatLedgerScreen extends StatefulWidget {
  const ChatLedgerScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  final String customerId;
  final String customerName;

  @override
  State<ChatLedgerScreen> createState() => _ChatLedgerScreenState();
}

class _ChatLedgerScreenState extends State<ChatLedgerScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<UdharController>().fetchCustomerLedger(widget.customerId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

        return Scaffold(
          backgroundColor:
              Get.isDarkMode ? AppColors.darkBgColor : AppColors.scaffoldColor,
          appBar: CustomAppBar(
            title: widget.customerName,
            actions: [
              // Toggle back to standard list view
              IconButton(
                icon: Icon(
                  Icons.list_alt,
                  color: AppColors.mainColor,
                  size: 24.sp,
                ),
                onPressed: () {
                  Get.back();
                },
              ),
              HSpace(10.w),
            ],
          ),
          body: Column(
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
                      Icon(Icons.wifi_off, color: Colors.white, size: 14.sp),
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
              // Ledger Balance Sticky Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
                decoration: BoxDecoration(
                  color: Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storedLanguage['Outstanding Balance'] ?? 'Outstanding Due',
                          style: t.bodySmall?.copyWith(color: AppColors.black50),
                        ),
                        VSpace(4.h),
                        Text(
                          '₹${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: balance > 0
                                ? AppColors.redColor
                                : (balance < 0
                                    ? AppColors.greenColor
                                    : AppColors.blackColor),
                          ),
                        ),
                      ],
                    ),
                    if (limit > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Credit Limit',
                            style: t.bodySmall?.copyWith(color: AppColors.black50),
                          ),
                          VSpace(4.h),
                          Text(
                            '₹${limit.toInt()}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blackColor,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Chat List
              Expanded(
                child: controller.isLedgerLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.filteredLedgerTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 60.sp, color: AppColors.black30),
                                VSpace(12.h),
                                Text(
                                  storedLanguage['No transactions found'] ?? 'No transaction history',
                                  style: t.bodyMedium?.copyWith(color: AppColors.black50),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                            // Reverse to show newest at bottom if list is sorted newest first
                            reverse: true,
                            itemCount: controller.filteredLedgerTransactions.length,
                            itemBuilder: (context, i) {
                              // We use reverse, so index 0 is the newest transaction. 
                              // Assuming controller returns newest first (descending).
                              final tx = controller.filteredLedgerTransactions[i];
                              final bool isCredit = tx['type'] == 'given'; 
                              final double amount = double.tryParse(tx['amount']?.toString() ?? '') ?? 0.0;
                              
                              final String remarks = tx['remarks']?.toString().isNotEmpty == true 
                                  ? tx['remarks'].toString() 
                                  : (isCredit ? 'Udhar Given' : 'Payment Received');
                              
                              final String dateString = Helpers.formatDateAndTime(tx['created_at']);
                              
                              // isCredit means Merchant gave Udhar (Sent message - Right side)
                              // !isCredit means Customer paid (Received message - Left side)
                              return _buildChatBubble(isCredit, amount, remarks, dateString, t);
                            },
                          ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: EdgeInsets.only(bottom: 8.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.redColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                      ),
                      icon: Icon(Icons.arrow_upward_rounded, size: 18.sp),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          storedLanguage['YOU GAVE'] ?? 'YOU GAVE',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onPressed: () {
                        Get.toNamed(
                          RoutesName.addUdharScreen,
                          arguments: {
                            'customerId': widget.customerId,
                            'customerName': widget.customerName,
                            'transactionType': 'given',
                          },
                        );
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
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                      ),
                      icon: Icon(Icons.arrow_downward_rounded, size: 18.sp),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          storedLanguage['YOU GOT'] ?? 'YOU GOT',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onPressed: () {
                        Get.toNamed(
                          RoutesName.addUdharScreen,
                          arguments: {
                            'customerId': widget.customerId,
                            'customerName': widget.customerName,
                            'transactionType': 'received',
                          },
                        );
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

  Widget _buildChatBubble(bool isOutgoing, double amount, String remarks, String dateString, TextTheme t) {
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        constraints: BoxConstraints(maxWidth: Get.width * 0.75),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isOutgoing ? AppColors.redColor.withValues(alpha: 0.1) : AppColors.greenColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: isOutgoing ? Radius.circular(16.r) : const Radius.circular(0),
            bottomRight: isOutgoing ? const Radius.circular(0) : Radius.circular(16.r),
          ),
          border: Border.all(
            color: isOutgoing ? AppColors.redColor.withValues(alpha: 0.3) : AppColors.greenColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOutgoing ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isOutgoing ? AppColors.redColor : AppColors.greenColor,
                  size: 16.sp,
                ),
                HSpace(6.w),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isOutgoing ? AppColors.redColor : AppColors.greenColor,
                  ),
                ),
              ],
            ),
            VSpace(6.h),
            Text(
              remarks,
              style: t.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppThemes.getParagraphColor(),
              ),
            ),
            VSpace(4.h),
            Text(
              dateString,
              style: t.bodySmall?.copyWith(
                fontSize: 10.sp,
                color: AppColors.black50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
