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
    final msg = Uri.encodeComponent(
      "Namaste $name ji,\nYour total pending Udhar balance on Udhar Card is ₹${amount.toStringAsFixed(0)}.\nPlease clear your dues at the earliest via UPI or Cash.\nThank you! 🙏",
    );
    final url = "https://wa.me/$formattedPhone?text=$msg";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Helpers.showSnackBar(
          msg: "Could not launch WhatsApp for $phone", title: "Error");
    }
  }

  void _navigateToLedger(Map<String, dynamic> userMap) {
    final id = (userMap['id'] ?? userMap['user_id'] ?? '').toString();
    final name =
        (userMap['name'] ?? userMap['customer_name'] ?? 'Customer').toString();
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
      appBar: CustomAppBar(
        leading: const SizedBox.shrink(),
        toolberHeight: 68.h,
        prefferSized: 68.h,
        bgColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
        isTitleMarginTop: false,
        titleWidget: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
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
              // ── 1. Hero 3-Metric Balance Ledger Banner ────────────────────
              GetBuilder<UdharController>(
                builder: (udharCtrl) {
                  double totalDiya = 0.0;
                  double totalMila = 0.0;
                  int customerCount = udharCtrl.usersList.length;

                  for (var u in udharCtrl.usersList) {
                    final b = double.tryParse(
                            (u['balance'] ?? u['udhar_balance'] ?? 0)
                                .toString()) ??
                        0.0;
                    final given = double.tryParse(
                            (u['total_given'] ?? u['total_diya'] ?? (b > 0 ? b : 0))
                                .toString()) ??
                        0.0;
                    final received = double.tryParse(
                            (u['total_received'] ?? u['total_mila'] ?? (b < 0 ? b.abs() : 0))
                                .toString()) ??
                        0.0;

                    totalDiya += given;
                    totalMila += received;
                  }
                  final double pendingBalance = totalDiya - totalMila;

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [const Color(0xFF1E1B4B), const Color(0xFF312E81)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22.r),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : const Color(0xFF312E81).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 16,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  "Digital Merchant Ledger",
                                  style: TextStyle(
                                    color: const Color(0xFFCBD5E1),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6.r,
                                    height: 6.r,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF38BDF8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    "$customerCount Customers",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.h),

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
                                      const Icon(
                                        Icons.call_made_rounded,
                                        color: Color(0xFFF87171),
                                        size: 13,
                                      ),
                                      SizedBox(width: 3.w),
                                      Text(
                                        "Total Diya",
                                        style: TextStyle(
                                          color: const Color(0xFF94A3B8),
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    "₹${totalDiya.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: const Color(0xFFF87171),
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              height: 38.h,
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.15),
                              margin: EdgeInsets.symmetric(horizontal: 6.w),
                            ),

                            // 2. Total Mila (You Received)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.call_received_rounded,
                                        color: Color(0xFF34D399),
                                        size: 13,
                                      ),
                                      SizedBox(width: 3.w),
                                      Text(
                                        "Total Mila",
                                        style: TextStyle(
                                          color: const Color(0xFF94A3B8),
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    "₹${totalMila.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: const Color(0xFF34D399),
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              height: 38.h,
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.15),
                              margin: EdgeInsets.symmetric(horizontal: 6.w),
                            ),

                            // 3. Pending (Net Balance)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.pending_actions_rounded,
                                        color: Color(0xFF38BDF8),
                                        size: 13,
                                      ),
                                      SizedBox(width: 3.w),
                                      Text(
                                        "Pending",
                                        style: TextStyle(
                                          color: const Color(0xFF94A3B8),
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    "₹${pendingBalance.abs().toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: const Color(0xFF38BDF8),
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 20.h),

              // ── 2. Home to Dashboard Bridge ───────────────────────────────
              GetBuilder<AppController>(
                builder: (appCtrl) {
                  final recipientCount = appCtrl.recipientList.length;
                  final walletCount = appCtrl.walletList.length;
                  final primaryWalletBalance = appCtrl.walletList.isNotEmpty
                      ? double.tryParse(
                          appCtrl.walletList.first.totalBalance.toString()) ??
                          0.0
                      : 0.0;

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111827) : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: AppColors.mainColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.dashboard_customize_rounded,
                                size: 15.sp,
                                color: AppColors.mainColor,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                "Business Dashboard",
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                if (Get.isRegistered<BottomNavController>()) {
                                  Get.find<BottomNavController>().changeScreen(1);
                                }
                              },
                              child: Text(
                                "Open",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.mainColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDashboardMetric(
                                title: "Recipients",
                                value: recipientCount.toString(),
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildDashboardMetric(
                                title: "Wallets",
                                value: walletCount.toString(),
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildDashboardMetric(
                                title: "Balance",
                                value: "₹${primaryWalletBalance.toStringAsFixed(0)}",
                                isDark: isDark,
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
                      if (Get.isRegistered<UdharController>()) {
                        await openAddCustomerScreen(
                          storedLanguage: storedLanguage,
                        );
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
                      if (Get.isRegistered<UdharController>()) {
                        await openAddCustomerScreen(
                          storedLanguage: storedLanguage,
                        );
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
                              if (Get.isRegistered<UdharController>()) {
                                await openAddCustomerScreen(
                                  storedLanguage: storedLanguage,
                                );
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

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final customer = list[index];
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
                  );
                },
              ),
              SizedBox(height: 16.h),
            ],
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

  Widget _buildDashboardMetric({
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
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
