import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:paysecure/config/app_colors.dart';
import 'package:paysecure/config/dimensions.dart';
import 'package:paysecure/controllers/app_controller.dart';
import 'package:paysecure/controllers/bottom_nav_controller.dart';
import 'package:paysecure/controllers/udhar_controller.dart';
import 'package:paysecure/notification_service/notification_controller.dart';
import 'package:paysecure/routes/routes_name.dart';
import 'package:paysecure/themes/themes.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:paysecure/views/screens/udhar/add_customer_screen.dart';
import 'package:paysecure/views/screens/udhar/customer_ledger_screen.dart';
import 'package:paysecure/views/screens/udhar/select_user_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paysecure/utils/services/subscription_gate_service.dart';
import 'package:paysecure/views/screens/subscription/widgets/upgrade_feature_sheet.dart';
import 'package:paysecure/views/screens/voice_entry/voice_khata_sheet.dart';
import 'package:paysecure/views/widgets/custom_appbar.dart';
import 'package:paysecure/views/widgets/language_selection_sheet.dart';
import 'package:paysecure/views/widgets/spacing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  String _activeFilterTab = "All"; // "All", "Get", "Give", "Settled"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<UdharController>()) {
        Get.find<UdharController>().fetchUsers();
        Get.find<UdharController>().fetchReports(silent: true);
      }
      if (Get.isRegistered<AppController>()) {
        Get.find<AppController>().getDashboard();
      }
      final bool onboardingCompleted =
          HiveHelp.read('onboarding_completed') ?? false;
      if (!onboardingCompleted) {
        Get.toNamed(RoutesName.merchantOnboardingWizardScreen);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _greetingMessage() {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning 👋";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon ☀️";
    } else {
      return "Good Evening 🌙";
    }
  }

  Future<void> _sendWhatsAppReminder(
      String phone, String name, double amount) async {
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final formattedPhone =
        cleanPhone.startsWith('+') ? cleanPhone : '+91$cleanPhone';
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
        "upi://pay?pa=$merchantUpi&pn=$encodedShop&am=${amount.abs()}&cu=INR";

    final String messageText =
        "Namaste $name ji 🙏\n\n"
        "Aapka kul udhar hisab *$shopName* par *₹${amount.abs().toStringAsFixed(0)}* baki hai.\n\n"
        "📲 *Abhi 1-Click me UPI se payment karne ke liye yahan tap karein:*\n"
        "$upiUrl\n\n"
        "(GPay / PhonePe / Paytm kisi bhi app se payment kar sakte hain)\n\n"
        "Kisi bhi jankari ke liye dukan par sampark karein. Dhanyawad! ✨";

    final url =
        "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(messageText)}";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Helpers.showSnackBar(
          msg: "Could not launch WhatsApp for $phone", title: "Error");
    }
  }

  void _navigateToLedger(Map<String, dynamic> userMap) {
    final rawId = userMap['id'] ??
        userMap['source_id'] ??
        userMap['customer_id'] ??
        userMap['user_id'];
    String id = (rawId ?? '').toString().trim();
    if (id.isEmpty && userMap['contact_identifier'] != null) {
      id = userMap['contact_identifier']
          .toString()
          .replaceAll(RegExp(r'[^0-9]'), '');
    }
    final name =
        (userMap['name'] ?? userMap['customer_name'] ?? 'Customer').toString();
    if (id.isEmpty) {
      Helpers.showSnackBar(msg: "Customer details unavailable.");
      return;
    }
    Get.to(() => CustomerLedgerScreen(customerId: id, customerName: name));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    final String fullName =
        (HiveHelp.read(Keys.userFullName) ?? '').toString().trim();
    final String userName =
        (HiveHelp.read(Keys.userName) ?? '').toString().trim();
    final String merchantDisplayName = fullName.isNotEmpty
        ? fullName
        : (userName.isNotEmpty ? userName : 'Merchant Store');

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      drawer: _buildNavDrawer(context, isDark, merchantDisplayName),
      appBar: CustomAppBar(
        leading: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              Icons.menu_rounded,
              color: isDark ? Colors.white : const Color(0xFF334155),
              size: 19.sp,
            ),
          ),
        ),
        toolberHeight: 68.h,
        prefferSized: 68.h,
        bgColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
        isTitleMarginTop: false,
        titleWidget: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: const Color(0xFF0857E6), // solid brand blue
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Image.asset(
                "$rootImageDir/app_logo.png",
                height: 24.h,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  merchantDisplayName,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      _greetingMessage(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Language Switcher Shortcut
          IconButton(
            onPressed: () => LanguageSelectionSheet.show(context),
            icon: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                Icons.translate_rounded,
                color: isDark ? const Color(0xFF38BDF8) : AppColors.mainColor,
                size: 19.sp,
              ),
            ),
          ),
          // Merchant QR Shortcut Button
          IconButton(
            onPressed: () => Get.toNamed(RoutesName.qrCodeScreen),
            icon: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                color: isDark ? const Color(0xFF38BDF8) : AppColors.mainColor,
                size: 19.sp,
              ),
            ),
          ),
          // Notification Bell
          GetBuilder<PushNotificationController>(
            builder: (notiCtrl) => Stack(
              children: [
                IconButton(
                  onPressed: () {
                    notiCtrl.isNotiSeen();
                    Get.toNamed(RoutesName.notificationScreen);
                  },
                  icon: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF334155),
                      size: 19.sp,
                    ),
                  ),
                ),
                if (!notiCtrl.isSeen.value)
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF0B0F19)
                              : Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.mainColor,
        onRefresh: () async {
          if (Get.isRegistered<UdharController>()) {
            await Get.find<UdharController>().fetchUsers();
            await Get.find<UdharController>().fetchReports(silent: true);
          }
          if (Get.isRegistered<AppController>()) {
            await Get.find<AppController>().getDashboard();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Subscription Plan Usage Banner ─────────────────────
              GetBuilder<UdharController>(
                builder: (udharCtrl) {
                  final limitState = udharCtrl.customerLimitState;
                  return Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.symmetric(
                      vertical: 10.h,
                      horizontal: 12.w,
                    ),
                    decoration: BoxDecoration(
                      color: limitState.isAtOrOverLimit
                          ? const Color(0xFFFEF3C7)
                          : (isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFEFF6FF)),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: limitState.isAtOrOverLimit
                            ? const Color(0xFFF59E0B)
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFBFDBFE)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          limitState.summaryLabel,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E3A8A),
                          ),
                        ),
                        if (limitState.isNearLimit)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              limitState.isAtOrOverLimit
                                  ? 'Soft-gating active: Add customer remains enabled temporarily.'
                                  : 'You are near plan limit. Upgrade recommended.',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // ── 1. Hero 3-Metric Balance Ledger Banner ────────────────────
              GetBuilder<UdharController>(
                builder: (udharCtrl) {
                  int customerCount = udharCtrl.usersList.length;

                  // 1. Calculate totals directly from customer balances (always accurate)
                  double totalCustomerOutstanding = 0.0;
                  double totalCustomerAdvance = 0.0;

                  for (var u in udharCtrl.usersList) {
                    final rawBal = u['outstanding_balance'] ??
                        u['net_balance'] ??
                        u['stored_balance'] ??
                        u['balance'] ??
                        u['udhar_balance'] ??
                        0;
                    final b = double.tryParse(rawBal.toString()) ?? 0.0;
                    if (b > 0) {
                      totalCustomerOutstanding += b;
                    } else if (b < 0) {
                      totalCustomerAdvance += b.abs();
                    }
                  }

                  // 2. Check if reportsSummary has transaction aggregates
                  double totalDiya = 0.0;
                  double totalMila = 0.0;
                  if (udharCtrl.reportsSummary.isNotEmpty &&
                      udharCtrl.reportsSummary['total_credit_given'] != null) {
                    totalDiya = double.tryParse(
                            udharCtrl.reportsSummary['total_credit_given']
                                .toString()) ??
                        0.0;
                    totalMila = double.tryParse(
                            udharCtrl.reportsSummary['total_debit_received']
                                .toString()) ??
                        0.0;
                  }

                  // If reportsSummary has no totals yet but customers have balances, fallback to customer sums
                  if (totalDiya == 0.0 &&
                      totalMila == 0.0 &&
                      totalCustomerOutstanding > 0) {
                    totalDiya = totalCustomerOutstanding;
                    totalMila = totalCustomerAdvance;
                  }

                  final double pendingBalance = totalDiya > totalMila
                      ? (totalDiya - totalMila)
                      : totalCustomerOutstanding;

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF17212B) : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF25303D)
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Color(0xFF0F5BD8),
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Digital Merchant Ledger",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      "Real-time business balance",
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 5.h),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF25303D)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6.r,
                                    height: 6.r,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    "$customerCount Customers",
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFE2E8F0)
                                          : const Color(0xFF334155),
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 14.h),
                        Divider(
                          color: isDark
                              ? const Color(0xFF25303D)
                              : const Color(0xFFF1F5F9),
                          height: 1,
                          thickness: 1,
                        ),
                        SizedBox(height: 14.h),

                        // 3-Metrics Columns Row
                        Row(
                          children: [
                            // 1. Total Diya (You Gave)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(3.r),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF450A0A)
                                              : const Color(0xFFFEF2F2),
                                          borderRadius:
                                              BorderRadius.circular(5.r),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_upward_rounded,
                                          color: Color(0xFFDC2626),
                                          size: 11,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        "Total Diya",
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    "₹${totalDiya.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFF87171)
                                          : const Color(0xFFDC2626),
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              height: 38.h,
                              width: 1,
                              color: isDark
                                  ? const Color(0xFF25303D)
                                  : const Color(0xFFF1F5F9),
                              margin: EdgeInsets.symmetric(horizontal: 6.w),
                            ),

                            // 2. Total Mila (You Received)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(3.r),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF052E16)
                                              : const Color(0xFFF0FDF4),
                                          borderRadius:
                                              BorderRadius.circular(5.r),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_downward_rounded,
                                          color: Color(0xFF16A34A),
                                          size: 11,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        "Total Mila",
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    "₹${totalMila.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF4ADE80)
                                          : const Color(0xFF16A34A),
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              height: 38.h,
                              width: 1,
                              color: isDark
                                  ? const Color(0xFF25303D)
                                  : const Color(0xFFF1F5F9),
                              margin: EdgeInsets.symmetric(horizontal: 6.w),
                            ),

                            // 3. Pending (Net Balance)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(3.r),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF172554)
                                              : const Color(0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius.circular(5.r),
                                        ),
                                        child: const Icon(
                                          Icons.pending_actions_rounded,
                                          color: Color(0xFF2563EB),
                                          size: 11,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        "Pending",
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    "₹${pendingBalance.abs().toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF60A5FA)
                                          : const Color(0xFF0F5BD8),
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.h),

                        // Action Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (Get.isRegistered<BottomNavController>()) {
                                    Get.find<BottomNavController>()
                                        .changeScreen(1);
                                  } else {
                                    Get.toNamed(RoutesName.customerListScreen);
                                  }
                                },
                                icon: const Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text('Open ledgers'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F5BD8),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      EdgeInsets.symmetric(vertical: 11.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final newCust = await openAddCustomerScreen(
                                    storedLanguage: storedLanguage,
                                  );
                                  if (newCust != null &&
                                      Get.isRegistered<UdharController>()) {
                                    Get.find<UdharController>()
                                        .fetchUsers(force: true);
                                  }
                                },
                                icon: Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF0F5BD8),
                                ),
                                label: Text(
                                  'Add customer',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFF0F5BD8),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFEFF6FF),
                                  side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF3B82F6)
                                            .withValues(alpha: 0.4)
                                        : const Color(0xFFBFDBFE),
                                    width: 1.1,
                                  ),
                                  padding:
                                      EdgeInsets.symmetric(vertical: 11.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 16.h),

              // ── Trial Active Banner (Discreet & Elegant) ──────────────────
              if (SubscriptionGateService.isTrialActive())
                Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: InkWell(
                    onTap: () => Get.toNamed(RoutesName.subscriptionPlansScreen),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                              : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.stars_rounded, color: const Color(0xFF2563EB), size: 20.r),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              '✨ ${SubscriptionGateService.currentPlanName()} Trial: ${SubscriptionGateService.trialDaysRemaining()} days left • AI Voice Khata unlocked',
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Upgrade',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── 3. Quick Merchant Action Grid (4 Actions) ──────────────────
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 2.2,
                children: [
                  // Action 1: Udhar Diya (+ Give Credit)
                  _buildQuickCard(
                    context,
                    title: "Udhar Diya",
                    subtitle: "+ Give Credit",
                    bgColor: isDark
                        ? const Color(0xFF2D1619)
                        : const Color(0xFFFEF2F2),
                    borderColor: isDark
                        ? const Color(0xFF7F1D1D)
                        : const Color(0xFFFECACA),
                    iconColor: const Color(0xFFEF4444),
                    icon: Icons.arrow_outward_rounded,
                    onTap: () async {
                      final selected = await SelectUserSheet.show(context);
                      if (selected != null) {
                        _navigateToLedger(selected);
                      }
                    },
                  ),

                  // Action 2: Vasooli (✓ Collect Payment)
                  _buildQuickCard(
                    context,
                    title: "Vasooli",
                    subtitle: "✓ Collect Payment",
                    bgColor: isDark
                        ? const Color(0xFF062C1B)
                        : const Color(0xFFECFDF5),
                    borderColor: isDark
                        ? const Color(0xFF065F46)
                        : const Color(0xFFA7F3D0),
                    iconColor: const Color(0xFF10B981),
                    icon: Icons.south_west_rounded,
                    onTap: () async {
                      final selected = await SelectUserSheet.show(context);
                      if (selected != null) {
                        _navigateToLedger(selected);
                      }
                    },
                  ),

                  // Action 3: Voice Entry (Hands-free Udhar)
                  _buildQuickCard(
                    context,
                    title: "Voice Entry",
                    subtitle: "🎙️ Talk & Post",
                    bgColor: isDark
                        ? const Color(0xFF1E1B4B)
                        : const Color(0xFFEEF2FF),
                    borderColor: isDark
                        ? const Color(0xFF3730A3)
                        : const Color(0xFFC7D2FE),
                    iconColor: const Color(0xFF6366F1),
                    icon: Icons.mic_rounded,
                    onTap: () {
                      if (Get.isRegistered<UdharController>()) {
                        Get.find<UdharController>().openVoiceEntryWithSoftGate();
                      } else {
                        Get.toNamed(RoutesName.voiceEntryScreen);
                      }
                    },
                  ),

                  // Action 4: Add Customer (+ New Customer)
                  _buildQuickCard(
                    context,
                    title: "Add Customer",
                    subtitle: "+ New Contact",
                    bgColor: isDark
                        ? const Color(0xFF0C2A3A)
                        : const Color(0xFFF0F9FF),
                    borderColor: isDark
                        ? const Color(0xFF075985)
                        : const Color(0xFFBAE6FD),
                    iconColor: const Color(0xFF0284C7),
                    icon: Icons.person_add_alt_1_rounded,
                    onTap: () async {
                      final newCust = await openAddCustomerScreen(
                        storedLanguage: storedLanguage,
                      );
                      if (newCust != null &&
                          Get.isRegistered<UdharController>()) {
                        Get.find<UdharController>().fetchUsers(force: true);
                      }
                    },
                  ),
                ],
              ),

              SizedBox(height: 22.h),

              // ── 4. Customer Ledger Section & Filter Tabs ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Customer Ledgers",
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final newCust = await openAddCustomerScreen(
                        storedLanguage: storedLanguage,
                      );
                      if (newCust != null &&
                          Get.isRegistered<UdharController>()) {
                        Get.find<UdharController>().fetchUsers(force: true);
                      }
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              size: 16.sp, color: AppColors.mainColor),
                          SizedBox(width: 4.w),
                          Text(
                            "+ Add Customer",
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mainColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10.h),

              // Search Bar Input
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: "Search by customer name or mobile number...",
                    hintStyle: TextStyle(
                      fontSize: 13.sp,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      size: 20.sp,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.cancel_rounded,
                                color: const Color(0xFF94A3B8), size: 18.sp),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 12.h, horizontal: 16.w),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              // Horizontal Segmented Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip("All", "All Customers"),
                    SizedBox(width: 8.w),
                    _buildFilterChip("Get", "Aapko Milega 🔴"),
                    SizedBox(width: 8.w),
                    _buildFilterChip("Give", "Aapko Dena 🟢"),
                    SizedBox(width: 8.w),
                    _buildFilterChip("Settled", "Settled (₹0)"),
                  ],
                ),
              ),

              SizedBox(height: 14.h),

              // ── 5. Customer Ledger List View ──────────────────────────────
              GetBuilder<UdharController>(
                builder: (udharCtrl) {
                  if (udharCtrl.isUsersLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  // 1. Filter & Sort users
                  List<dynamic> list = List.from(udharCtrl.usersList);

                  // Apply Filter Tab
                  if (_activeFilterTab == "Get") {
                    list = list.where((u) {
                      final b = double.tryParse(
                              (u['balance'] ?? u['udhar_balance'] ?? 0)
                                  .toString()) ??
                          0.0;
                      return b > 0;
                    }).toList();
                  } else if (_activeFilterTab == "Give") {
                    list = list.where((u) {
                      final b = double.tryParse(
                              (u['balance'] ?? u['udhar_balance'] ?? 0)
                                  .toString()) ??
                          0.0;
                      return b < 0;
                    }).toList();
                  } else if (_activeFilterTab == "Settled") {
                    list = list.where((u) {
                      final b = double.tryParse(
                              (u['balance'] ?? u['udhar_balance'] ?? 0)
                                  .toString()) ??
                          0.0;
                      return b == 0;
                    }).toList();
                  }

                  // Apply Search Query
                  if (_searchQuery.isNotEmpty) {
                    list = list.where((u) {
                      final name = (u['name'] ?? u['customer_name'] ?? '')
                          .toString()
                          .toLowerCase();
                      final phone = (u['phone'] ?? u['mobile'] ?? '')
                          .toString()
                          .toLowerCase();
                      return name.contains(_searchQuery) ||
                          phone.contains(_searchQuery);
                    }).toList();
                  }

                  // Sort by highest pending balance first
                  list.sort((a, b) {
                    double balA = double.tryParse(
                            (a['balance'] ?? a['udhar_balance'] ?? 0)
                                .toString()) ??
                        0.0;
                    double balB = double.tryParse(
                            (b['balance'] ?? b['udhar_balance'] ?? 0)
                                .toString()) ??
                        0.0;
                    return balB.compareTo(balA);
                  });

                  if (list.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          vertical: 28.h, horizontal: 20.w),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.person_search_rounded,
                              size: 44.sp, color: const Color(0xFF94A3B8)),
                          SizedBox(height: 10.h),
                          Text(
                            "No Udhar Customers Found",
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _searchQuery.isNotEmpty
                                ? "No customer matching '$_searchQuery'"
                                : "Tap + Add Customer to start managing credit ledgers.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 14.h),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final newCust = await openAddCustomerScreen(
                                storedLanguage: storedLanguage,
                              );
                              if (newCust != null &&
                                  Get.isRegistered<UdharController>()) {
                                Get.find<UdharController>().fetchUsers(force: true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                            ),
                            icon: Icon(Icons.add,
                                color: Colors.white, size: 16.sp),
                            label: Text(
                              "Add First Customer",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final displayList = (_searchQuery.isEmpty && list.length > 25)
                      ? list.take(25).toList()
                      : list;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayList.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final customer = displayList[index];
                      final name = (customer['name'] ??
                              customer['customer_name'] ??
                              'Customer')
                          .toString();
                      final phone = (customer['phone'] ??
                              customer['mobile'] ??
                              '')
                          .toString();
                      final balance = double.tryParse(
                              (customer['balance'] ??
                                      customer['udhar_balance'] ??
                                      0)
                                  .toString()) ??
                          0.0;
                      final rank = index + 1;

                      // Badge Rank Top 3 styling
                      Color rankBg = isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9);
                      Color rankText = isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF475467);
                      if (rank == 1) {
                        rankBg = const Color(0xFFFEF3C7);
                        rankText = const Color(0xFFD97706);
                      } else if (rank == 2) {
                        rankBg = const Color(0xFFE2E8F0);
                        rankText = const Color(0xFF475467);
                      } else if (rank == 3) {
                        rankBg = const Color(0xFFFFEDD5);
                        rankText = const Color(0xFFC2410C);
                      }

                      return InkWell(
                        onTap: () => _navigateToLedger(
                            Map<String, dynamic>.from(customer)),
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          padding: EdgeInsets.all(13.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Rank Badge
                              Container(
                                width: 26.w,
                                height: 26.w,
                                decoration: BoxDecoration(
                                  color: rankBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "#$rank",
                                    style: TextStyle(
                                      color: rankText,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),

                              // Customer Initial Avatar
                              CircleAvatar(
                                radius: 19.r,
                                backgroundColor:
                                    AppColors.mainColor.withValues(alpha: 0.12),
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : 'C',
                                  style: TextStyle(
                                    color: AppColors.mainColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),

                              // Name & Phone
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      phone.isNotEmpty
                                          ? phone
                                          : "No mobile number",
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Balance & Action Button
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    balance > 0
                                        ? "₹${balance.toStringAsFixed(0)}"
                                        : balance < 0
                                            ? "₹${balance.abs().toStringAsFixed(0)} (Adv)"
                                            : "₹0 (Settled)",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                      color: balance > 0
                                          ? const Color(0xFFEF4444)
                                          : balance < 0
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF64748B),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  if (balance > 0 && phone.isNotEmpty)
                                    InkWell(
                                      onTap: () => _sendWhatsAppReminder(
                                          phone, name, balance),
                                      borderRadius: BorderRadius.circular(6.r),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 7.w, vertical: 3.h),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF25D366)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6.r),
                                          border: Border.all(
                                            color: const Color(0xFF25D366)
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_rounded,
                                              size: 10.sp,
                                              color: const Color(0xFF25D366),
                                            ),
                                            SizedBox(width: 3.w),
                                            Text(
                                              "Remind",
                                              style: TextStyle(
                                                color: const Color(0xFF25D366),
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (list.length > 25 && _searchQuery.isEmpty) ...[
                        SizedBox(height: 10.h),
                        OutlinedButton.icon(
                          onPressed: () {
                            Get.toNamed(RoutesName.customerListScreen);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.mainColor,
                            side: BorderSide(
                              color:
                                  AppColors.mainColor.withValues(alpha: 0.35),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            minimumSize: Size(double.infinity, 44.h),
                          ),
                          icon: Icon(Icons.people_alt_outlined, size: 18.sp),
                          label: Text(
                            "View All ${list.length} Customers (Khata Book)  ➔",
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_home_voice_khata',
        onPressed: () {
          if (!SubscriptionGateService.isVoiceEntryIncluded()) {
            UpgradeFeatureSheet.show(
              title: 'Unlock AI VoiceKhata',
              subtitle: 'Manage credit 10x faster using simple voice commands — no typing needed.',
            );
            return;
          }
          VoiceKhataSheet.show(context);
        },
        backgroundColor: const Color(0xFF00A86B),
        elevation: 6,
        icon: Container(
          padding: EdgeInsets.all(4.r),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mic,
            color: Color(0xFF00A86B),
            size: 18,
          ),
        ),
        label: Text(
          "VoiceKhata",
          style: GoogleFonts.outfit(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _activeFilterTab == key;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected
              ? Colors.white
              : isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF475467),
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _activeFilterTab = key;
          });
        }
      },
      selectedColor: AppColors.mainColor,
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: isSelected
            ? AppColors.mainColor
            : isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      showCheckmark: false,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    );
  }

  Widget _buildQuickCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavDrawer(
      BuildContext context, bool isDark, String merchantDisplayName) {
    final String phone =
        (HiveHelp.read(Keys.userPhone) ?? '').toString().trim();

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drawer Header ────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: const Color(0xFF0857E6), // solid brand blue
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    merchantDisplayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      phone,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── Nav Items ────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                children: [
                  _buildDrawerItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.home_rounded,
                    label: 'Home Dashboard',
                    color: AppColors.mainColor,
                    onTap: () {
                      Navigator.pop(context);
                      if (Get.isRegistered<BottomNavController>()) {
                        Get.find<BottomNavController>().changeScreen(0);
                      }
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.people_alt_rounded,
                    label: 'Customer Directory',
                    color: const Color(0xFF0284C7),
                    onTap: () {
                      Navigator.pop(context);
                      if (Get.isRegistered<BottomNavController>()) {
                        Get.find<BottomNavController>().changeScreen(1);
                      } else {
                        Get.toNamed(RoutesName.customerListScreen);
                      }
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Add Customer',
                    color: const Color(0xFF10B981),
                    onTap: () async {
                      Navigator.pop(context);
                      final storedLanguage =
                          HiveHelp.read(Keys.languageData) ?? {};
                      final newCust = await openAddCustomerScreen(
                          storedLanguage: storedLanguage);
                      if (newCust != null &&
                          Get.isRegistered<UdharController>()) {
                        Get.find<UdharController>().fetchUsers(force: true);
                      }
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.mic_rounded,
                    label: 'Voice Entry',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(context);
                      if (Get.isRegistered<UdharController>()) {
                        Get.find<UdharController>()
                            .openVoiceEntryWithSoftGate();
                      } else {
                        Get.toNamed(RoutesName.voiceEntryScreen);
                      }
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(RoutesName.udharReportsScreen);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.checklist_rounded,
                    label: 'Work List',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(RoutesName.workListScreen);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.receipt_long_rounded,
                    label: 'Transactions',
                    color: const Color(0xFF0891B2),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(RoutesName.transactionScreen);
                    },
                  ),
                  Divider(
                    height: 24.h,
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    indent: 16.w,
                    endIndent: 16.w,
                  ),
                  _buildDrawerItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'My QR Code',
                    color: const Color(0xFF7C3AED),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(RoutesName.qrCodeScreen);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.support_agent_rounded,
                    label: 'Support',
                    color: const Color(0xFF64748B),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(RoutesName.supportTicketListScreen);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    color: const Color(0xFFF97316),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(RoutesName.notificationScreen);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.settings_rounded,
                    label: 'Merchant Settings',
                    color: const Color(0xFF475467),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(RoutesName.merchantSettingScreen);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    color: const Color(0xFF0F172A),
                    onTap: () {
                      Navigator.pop(context);
                      if (Get.isRegistered<BottomNavController>()) {
                        Get.find<BottomNavController>().changeScreen(3);
                      }
                    },
                  ),
                ],
              ),
            ),
            // ── App Version Footer ───────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Text(
                'PaySecure Merchant App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isDark
                      ? const Color(0xFF475467)
                      : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: color, size: 18.sp),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
    );
  }
}

Widget buildTransactionLoader({
  int? itemCount = 5,
  bool? isReverseColor = false,
}) {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: itemCount,
    itemBuilder: (context, i) {
      return Container(
        width: double.maxFinite,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isReverseColor == true
              ? AppThemes.getFillColor()
              : AppThemes.getDarkCardColor(),
          borderRadius: Dimensions.kBorderRadius,
          border: Border.all(
            color: AppThemes.borderColor(),
            width: Dimensions.appThinBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40.h,
              height: 40.h,
              padding: EdgeInsets.all(10.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: Get.isDarkMode
                    ? AppColors.darkBgColor
                    : isReverseColor == true
                        ? AppColors.whiteColor
                        : AppColors.fillColorColor,
              ),
            ),
            HSpace(10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10.h,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: Get.isDarkMode
                          ? AppColors.darkBgColor
                          : isReverseColor == true
                              ? AppColors.whiteColor
                              : AppColors.fillColorColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  VSpace(5.h),
                  Container(
                    height: 10.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Get.isDarkMode
                          ? AppColors.darkBgColor
                          : isReverseColor == true
                              ? AppColors.whiteColor
                              : AppColors.fillColorColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
