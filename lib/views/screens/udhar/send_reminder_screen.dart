import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/services/helpers.dart';
import '../../widgets/custom_appbar.dart';

class SendReminderScreen extends StatefulWidget {
  final Map<String, dynamic>? customer;
  final double? amount;
  final int? daysDue;

  const SendReminderScreen({
    super.key,
    this.customer,
    this.amount,
    this.daysDue,
  });

  @override
  State<SendReminderScreen> createState() => _SendReminderScreenState();
}

class _SendReminderScreenState extends State<SendReminderScreen> {
  String _selectedChannel = 'whatsapp'; // 'whatsapp', 'sms', 'call'
  late TextEditingController _messageCtrl;

  @override
  void initState() {
    super.initState();
    final customerName = widget.customer?['name'] ?? widget.customer?['customer_name'] ?? 'Customer';
    final amountVal = widget.amount ??
        double.tryParse(widget.customer?['outstanding_balance']?.toString() ?? '0') ??
        2450.0;
    final days = widget.daysDue ?? 3;

    final defaultMsg =
        "Hi $customerName, your udhar of ₹${amountVal.toStringAsFixed(0)} is due in $days days. Please make the payment at your convenience. Thank you!";
    _messageCtrl = TextEditingController(text: defaultMsg);
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final phone = widget.customer?['phone'] ?? widget.customer?['mobile'] ?? '';
    final cleanPhone = phone.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final msg = _messageCtrl.text.trim();

    if (_selectedChannel == 'whatsapp') {
      if (cleanPhone.isEmpty) {
        Helpers.showSnackBar(msg: "Customer phone number is required for WhatsApp");
        return;
      }
      final targetPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
      final uri = Uri.parse("https://wa.me/$targetPhone?text=${Uri.encodeComponent(msg)}");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Helpers.showSnackBar(msg: "Could not open WhatsApp");
      }
    } else if (_selectedChannel == 'sms') {
      if (cleanPhone.isEmpty) {
        Helpers.showSnackBar(msg: "Customer phone number is required for SMS");
        return;
      }
      final uri = Uri.parse("sms:$cleanPhone?body=${Uri.encodeComponent(msg)}");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Helpers.showSnackBar(msg: "Could not launch SMS app");
      }
    } else if (_selectedChannel == 'call') {
      if (cleanPhone.isEmpty) {
        Helpers.showSnackBar(msg: "Customer phone number is required for Call");
        return;
      }
      final uri = Uri.parse("tel:$cleanPhone");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Helpers.showSnackBar(msg: "Could not launch Phone dialer");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: "Send Reminder",
        isReverseIconBgColor: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            // Hero Graphic / Illustration
            Center(
              child: Container(
                width: 140.w,
                height: 140.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE6F7F5),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Phone Graphic
                    Container(
                      width: 70.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_rounded,
                              color: const Color(0xFF25D366),
                              size: 26.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bubble Overlay
                    Positioned(
                      top: 25.h,
                      right: 15.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_filled_rounded,
                                size: 12.sp, color: const Color(0xFFEF4444)),
                            SizedBox(width: 4.w),
                            Text(
                              "Due Soon",
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Headline
            Text(
              "Send Payment Reminder",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "Choose how you want to remind your customer about the due amount.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),

            // Channel Selector Options
            _buildChannelOption(
              channelKey: 'whatsapp',
              title: "WhatsApp",
              subtitle: "Fast & effective",
              icon: Icons.chat_bubble_rounded,
              iconColor: const Color(0xFF25D366),
              bgColor: const Color(0xFFE8F8EE),
              isDark: isDark,
            ),
            SizedBox(height: 12.h),
            _buildChannelOption(
              channelKey: 'sms',
              title: "SMS",
              subtitle: "Simple & reliable",
              icon: Icons.sms_rounded,
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              isDark: isDark,
            ),
            SizedBox(height: 12.h),
            _buildChannelOption(
              channelKey: 'call',
              title: "Call",
              subtitle: "Direct conversation",
              icon: Icons.phone_rounded,
              iconColor: const Color(0xFF0D9488),
              bgColor: const Color(0xFFE6F7F5),
              isDark: isDark,
            ),
            SizedBox(height: 24.h),

            // Custom Message Box
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Custom Message (optional)",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _messageCtrl,
                    maxLines: 4,
                    maxLength: 160,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      height: 1.4,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: "",
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "${_messageCtrl.text.length}/160",
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),

            // Primary CTA Button
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _handleSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  "Send Reminder",
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
  }

  Widget _buildChannelOption({
    required String channelKey,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required bool isDark,
  }) {
    final isSelected = _selectedChannel == channelKey;

    return InkWell(
      onTap: () => setState(() => _selectedChannel = channelKey),
      borderRadius: BorderRadius.circular(14.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected ? const Color(0xFF1E293B) : const Color(0xFF131C2E))
              : (isSelected ? Colors.white : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D9488)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isDark ? iconColor.withValues(alpha: 0.15) : bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22.r,
              height: 22.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0D9488)
                      : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, size: 14.sp, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
