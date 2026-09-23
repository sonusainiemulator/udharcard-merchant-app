import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../voice_entry/voice_khata_sheet.dart';
import 'select_user_sheet.dart';

class AddUdharScreen extends StatefulWidget {
  const AddUdharScreen({super.key});

  @override
  State<AddUdharScreen> createState() => _AddUdharScreenState();
}

class _AddUdharScreenState extends State<AddUdharScreen> {
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<UdharController>()) {
      Get.put(UdharController());
    }

    final args = Get.arguments;
    if (args is Map) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Get.find<UdharController>().applyVoiceEntryPrefill(
          name: args['name']?.toString(),
          amount: args['amount'] is num
              ? (args['amount'] as num).toDouble()
              : double.tryParse(args['amount']?.toString() ?? ''),
          type: args['type']?.toString(),
        );
      });
    }
  }

  void _onSetQuickAmount(UdharController controller, int amount) {
    HapticFeedback.selectionClick();
    controller.amountCtrl.text = amount.toString();
    controller.amountCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.amountCtrl.text.length),
    );
    controller.update();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};

    return GetBuilder<UdharController>(
      builder: (controller) {
        final bool isReceived = controller.transactionType == 'received';
        final Color themeColor =
            isReceived ? const Color(0xFF10B981) : const Color(0xFF0D9488);

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor:
                isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              isReceived
                  ? (storedLanguage['Payment Received'] ?? 'Payment Received')
                  : (storedLanguage['New Udhar'] ?? 'New Udhar'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            centerTitle: false,
            actions: [
              // Voice Khata quick launcher button
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    color: const Color(0xFF2563EB),
                    size: 18.sp,
                  ),
                ),
                tooltip: "Voice Udhar",
                onPressed: () {
                  VoiceKhataSheet.show(context);
                },
              ),
              SizedBox(width: 8.w),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Customer Section ──
                Text(
                  storedLanguage['Customer'] ?? 'Customer',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8.h),
                InkWell(
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    final picked = await SelectUserSheet.show(context);
                    if (picked != null) {
                      controller.selectUser(picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 13.h),
                    decoration: BoxDecoration(
                      color:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: controller.selectedUser != null
                            ? const Color(0xFF2563EB)
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                        width: controller.selectedUser != null ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: controller.selectedUser != null
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (controller.selectedUser!['name'] ??
                                              controller.selectedUser![
                                                  'customer_name'] ??
                                              'Customer')
                                          .toString(),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      (controller.selectedUser!['phone'] ??
                                              controller.selectedUser![
                                                  'mobile'] ??
                                              '')
                                          .toString(),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  storedLanguage[
                                          'Select or search customer'] ??
                                      'Select or search customer',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                        if (controller.selectedUser != null)
                          GestureDetector(
                            onTap: () {
                              controller.clearSelectedUser();
                            },
                            child: Icon(
                              Icons.close_rounded,
                              color: const Color(0xFF94A3B8),
                              size: 18.sp,
                            ),
                          )
                        else
                          Icon(
                            Icons.chevron_right_rounded,
                            color: const Color(0xFF94A3B8),
                            size: 20.sp,
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // ── 2. "OR" Divider ──
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Text(
                        "OR",
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // ── 3. Quick Action Cards: Add via NFC / Scan QR ──
                Row(
                  children: [
                    // Card 1: Add via NFC
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await SelectUserSheet.show(context);
                          if (picked != null) {
                            controller.selectUser(picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_add_alt_1_rounded,
                                color: const Color(0xFF0284C7),
                                size: 24.sp,
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                "Add Customer",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                "Select or create",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Card 2: Scan QR
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Get.toNamed(RoutesName.qrCodeScreen);
                        },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                color: const Color(0xFF0284C7),
                                size: 24.sp,
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                "Scan QR",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                "Scan customer QR",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // ── 4. Amount Section ──
                Text(
                  storedLanguage['Amount'] ?? 'Amount',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 2.h),
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
                      Text(
                        "₹",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: TextFormField(
                          controller: controller.amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter amount",
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.mic_none_rounded,
                          color: const Color(0xFF2563EB),
                          size: 20.sp,
                        ),
                        onPressed: () {
                          VoiceKhataSheet.show(context);
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10.h),

                // Quick Amount Chips Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAmountChip("₹ 500", 500, controller, isDark),
                    _buildAmountChip("₹ 1,000", 1000, controller, isDark),
                    _buildAmountChip("₹ 2,000", 2000, controller, isDark),
                    _buildAmountChip("₹ 5,000", 5000, controller, isDark),
                  ],
                ),

                SizedBox(height: 20.h),

                // ── 5. Due Date Section ──
                Text(
                  storedLanguage['Due Date'] ?? 'Due Date',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8.h),
                InkWell(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    controller.pickDateAndTime(context);
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 13.h),
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
                        Icon(
                          Icons.calendar_today_outlined,
                          color: const Color(0xFF64748B),
                          size: 18.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            controller.selectedDate != null
                                ? DateFormat('dd MMM yyyy')
                                    .format(controller.selectedDate!)
                                : 'Today',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF64748B),
                          size: 22.sp,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // ── 6. Note (optional) Section ──
                Text(
                  storedLanguage['Note (optional)'] ?? 'Note (optional)',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: TextFormField(
                    controller: controller.remarksCtrl,
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: "e.g. Ready goods, monthly etc.",
                      hintStyle: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // ── 7. Save Udhar Button ──
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: controller.isSubmitting
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            controller.submitUdhar();
                          },
                    child: controller.isSubmitting
                        ? SizedBox(
                            width: 22.h,
                            height: 22.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isReceived
                                ? (storedLanguage['Save Payment'] ??
                                    'Save Payment')
                                : (storedLanguage['Save Udhar'] ??
                                    'Save Udhar'),
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountChip(
      String label, int amount, UdharController controller, bool isDark) {
    return InkWell(
      onTap: () => _onSetQuickAmount(controller, amount),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
