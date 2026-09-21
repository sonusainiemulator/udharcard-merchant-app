import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';
import 'select_user_sheet.dart';

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
  Map<String, dynamic>? _customer;
  late double _amount;
  int _daysDue = 3;
  String _selectedChannel = 'whatsapp'; // 'whatsapp', 'sms', 'call'
  String _selectedTemplate = 'polite'; // 'polite', 'due_today', 'urgent', 'english'
  bool _includeUpiLink = true;
  late TextEditingController _messageCtrl;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;

    // If no customer passed (e.g. opened from Home Quick Actions),
    // try to auto-preselect the first debtor from ledger
    if (_customer == null && Get.isRegistered<UdharController>()) {
      final users = Get.find<UdharController>().usersList;
      for (final u in users) {
        if (u is Map) {
          final bal = double.tryParse(
                (u['outstanding_balance'] ?? u['balance'] ?? 0).toString(),
              ) ??
              0.0;
          if (bal > 0) {
            _customer = Map<String, dynamic>.from(u);
            break;
          }
        }
      }
    }

    _amount = widget.amount ??
        double.tryParse(_customer?['outstanding_balance']?.toString() ??
                _customer?['balance']?.toString() ??
                '0') ??
        0.0;
    _daysDue = widget.daysDue ??
        (int.tryParse(_customer?['days_due']?.toString() ?? '3') ?? 3);

    _messageCtrl = TextEditingController(text: _generateReminderMessage());
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  void _onCustomerSelected(Map<String, dynamic>? newCustomer) {
    if (newCustomer == null) return;
    setState(() {
      _customer = newCustomer;
      _amount = double.tryParse(_customer?['outstanding_balance']?.toString() ??
              _customer?['balance']?.toString() ??
              '0') ??
          0.0;
      _daysDue = int.tryParse(_customer?['days_due']?.toString() ?? '3') ?? 3;
      _messageCtrl.text = _generateReminderMessage();
    });
  }

  String _generateReminderMessage() {
    final customerName = _customer?['name'] ??
        _customer?['customer_name'] ??
        'Customer';
    final amountVal = _amount > 0 ? _amount : 500.0;
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
        "upi://pay?pa=$merchantUpi&pn=$encodedShop&am=${amountVal.abs().toInt()}&cu=INR";

    String baseMsg = "";
    switch (_selectedTemplate) {
      case 'polite':
        baseMsg =
            "Namaste $customerName ji 🙏\n\n"
            "Aapka $shopName par kul udhar *₹${amountVal.abs().toStringAsFixed(0)}* baki hai. "
            "Kripya samay par bhuqtan karein.\n\n"
            "Kisi bhi jankari ke liye dukan par sampark karein. Dhanyawad! ✨";
        break;
      case 'due_today':
        baseMsg =
            "Namaste $customerName ji,\n\n"
            "Aapka *₹${amountVal.abs().toStringAsFixed(0)}* ka udhar hisab aaj deye hai. "
            "Kripya aaj hi payment karein.\n\n"
            "Dhanyawad - $shopName";
        break;
      case 'urgent':
        baseMsg =
            "⚠️ URGENT PAYMENT REMINDER\n\n"
            "$customerName ji, aapka *₹${amountVal.abs().toStringAsFixed(0)}* ka hisab overdue ho chuka hai. "
            "Kripya aaj hi payment clear karein.\n\n"
            "Sampark: $shopName";
        break;
      case 'english':
      default:
        baseMsg =
            "Hi $customerName,\n\n"
            "Your udhar balance of *₹${amountVal.abs().toStringAsFixed(0)}* at $shopName is due in $_daysDue days. "
            "Please make the payment at your earliest convenience. Thank you!";
        break;
    }

    if (_includeUpiLink && _amount > 0) {
      baseMsg +=
          "\n\n📲 *1-Click UPI Payment Link:*\n"
          "$upiUrl\n\n"
          "(Google Pay, PhonePe, Paytm kisi bhi app se payment kar sakte hain)";
    }

    return baseMsg;
  }

  Future<void> _handleSend() async {
    final phone = _customer?['phone'] ?? _customer?['mobile'] ?? '';
    final cleanPhone = phone.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final msg = _messageCtrl.text.trim();

    if (cleanPhone.isEmpty) {
      Helpers.showSnackBar(
        msg: "Please select a customer with a valid phone number.",
        title: "Phone Required",
      );
      return;
    }

    HapticFeedback.mediumImpact();

    if (_selectedChannel == 'whatsapp') {
      final targetPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
      final uri = Uri.parse("https://wa.me/$targetPhone?text=${Uri.encodeComponent(msg)}");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Helpers.showSnackBar(msg: "Could not open WhatsApp");
      }
    } else if (_selectedChannel == 'sms') {
      final uri = Uri.parse("sms:$cleanPhone?body=${Uri.encodeComponent(msg)}");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Helpers.showSnackBar(msg: "Could not launch SMS app");
      }
    } else if (_selectedChannel == 'call') {
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
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final subtleText = const Color(0xFF64748B);
    final primaryColor = const Color(0xFF0D9488);

    final customerName = _customer?['name'] ?? _customer?['customer_name'] ?? 'Select Customer';
    final customerPhone = _customer?['phone'] ?? _customer?['mobile'] ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: "Send Payment Reminder",
        isReverseIconBgColor: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Customer Selection Card ──────────────────────────────
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: primaryColor.withValues(alpha: 0.12),
                    child: Icon(Icons.person, color: primaryColor, size: 24.sp),
                  ),
                  HSpace(12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        VSpace(2.h),
                        Text(
                          customerPhone.isNotEmpty ? customerPhone : "No phone number",
                          style: TextStyle(fontSize: 12.sp, color: subtleText),
                        ),
                        if (_amount > 0) ...[
                          VSpace(4.h),
                          Text(
                            "Due: ₹${_amount.abs().toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await SelectUserSheet.show(context);
                      if (picked != null) {
                        _onCustomerSelected(picked);
                      }
                    },
                    icon: Icon(Icons.swap_horiz_rounded, size: 18.sp, color: primaryColor),
                    label: Text(
                      _customer != null ? "Change" : "Select",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            VSpace(18.h),

            // ── 2. Channel Selector Options ─────────────────────────────
            _buildChannelOption(
              channelKey: 'whatsapp',
              title: "WhatsApp",
              subtitle: "Instant 1-Click payment reminder",
              icon: Icons.chat_bubble_rounded,
              iconColor: const Color(0xFF25D366),
              bgColor: const Color(0xFFE8F8EE),
              isDark: isDark,
            ),
            VSpace(10.h),
            _buildChannelOption(
              channelKey: 'sms',
              title: "SMS",
              subtitle: "Direct mobile text reminder",
              icon: Icons.sms_rounded,
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              isDark: isDark,
            ),
            VSpace(10.h),
            _buildChannelOption(
              channelKey: 'call',
              title: "Call",
              subtitle: "Direct phone conversation",
              icon: Icons.phone_rounded,
              iconColor: primaryColor,
              bgColor: const Color(0xFFE6F7F5),
              isDark: isDark,
            ),
            VSpace(20.h),

            // ── 3. Template Selection Chips ─────────────────────────────
            Text(
              "Reminder Message Template",
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            VSpace(8.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTemplateChip(
                    templateKey: 'polite',
                    label: "🙏 विनम्र (Polite)",
                    isDark: isDark,
                    primaryColor: primaryColor,
                  ),
                  HSpace(8.w),
                  _buildTemplateChip(
                    templateKey: 'due_today',
                    label: "⏰ आज देय (Due Today)",
                    isDark: isDark,
                    primaryColor: primaryColor,
                  ),
                  HSpace(8.w),
                  _buildTemplateChip(
                    templateKey: 'urgent',
                    label: "⚠️ अति आवश्यक (Urgent)",
                    isDark: isDark,
                    primaryColor: primaryColor,
                  ),
                  HSpace(8.w),
                  _buildTemplateChip(
                    templateKey: 'english',
                    label: "🇬🇧 English",
                    isDark: isDark,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),
            VSpace(14.h),

            // ── 4. UPI Payment Link Toggle ──────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_rounded, color: primaryColor, size: 20.sp),
                  HSpace(10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Include 1-Click UPI Payment Link",
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "Customer can tap & pay via GPay / PhonePe / Paytm",
                          style: TextStyle(fontSize: 10.5.sp, color: subtleText),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _includeUpiLink,
                    activeTrackColor: primaryColor,
                    onChanged: (val) {
                      setState(() {
                        _includeUpiLink = val;
                        _messageCtrl.text = _generateReminderMessage();
                      });
                    },
                  ),
                ],
              ),
            ),
            VSpace(14.h),

            // ── 5. Message Editor Box ───────────────────────────────────
            Text(
              "Message Preview (Editable)",
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            VSpace(8.h),
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _messageCtrl,
                    maxLines: 6,
                    maxLength: 1000,
                    style: TextStyle(
                      fontSize: 13.sp,
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
                  VSpace(4.h),
                  Text(
                    "${_messageCtrl.text.length} characters",
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            VSpace(24.h),

            // ── 6. Primary CTA Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _handleSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedChannel == 'whatsapp'
                          ? Icons.chat_bubble_rounded
                          : _selectedChannel == 'sms'
                              ? Icons.sms_rounded
                              : Icons.phone_rounded,
                      size: 18.sp,
                      color: Colors.white,
                    ),
                    HSpace(8.w),
                    Text(
                      _selectedChannel == 'whatsapp'
                          ? "Send Reminder on WhatsApp"
                          : _selectedChannel == 'sms'
                              ? "Send Reminder via SMS"
                              : "Call Customer Now",
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VSpace(20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateChip({
    required String templateKey,
    required String label,
    required bool isDark,
    required Color primaryColor,
  }) {
    final isSelected = _selectedTemplate == templateKey;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTemplate = templateKey;
          _messageCtrl.text = _generateReminderMessage();
        });
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
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
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12.r),
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
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0D9488)
                      : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 12.sp, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
