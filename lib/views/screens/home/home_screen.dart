import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:paysecure/config/app_colors.dart';
import 'package:paysecure/config/dimensions.dart';
import 'package:paysecure/controllers/app_controller.dart';
import 'package:paysecure/controllers/auth_controller.dart';
import 'package:paysecure/notification_service/notification_controller.dart';
import 'package:paysecure/controllers/profile_controller.dart';
import 'package:paysecure/controllers/transaction_controller.dart';
import 'package:paysecure/controllers/udhar_controller.dart';
import 'package:paysecure/routes/routes_name.dart';
import 'package:paysecure/themes/themes.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:paysecure/views/screens/udhar/customer_ledger_screen.dart';
import 'package:paysecure/views/screens/udhar/select_user_sheet.dart';
import 'package:paysecure/views/widgets/custom_appbar.dart';
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

  Future<void> _sendWhatsAppReminder(String phone, String name, double amount) async {
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final formattedPhone = cleanPhone.startsWith('+') ? cleanPhone : '+91$cleanPhone';
    final msg = Uri.encodeComponent(
      "Namaste $name ji,\nYour total pending Udhar balance on Udhar Card is ₹${amount.toStringAsFixed(0)}.\nPlease clear your dues at the earliest via UPI or Cash.\nThank you! 🙏",
    );
    final url = "https://wa.me/$formattedPhone?text=$msg";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Helpers.showSnackBar(msg: "Could not launch WhatsApp for $phone", title: "Error");
    }
  }

  void _navigateToLedger(Map<String, dynamic> userMap) {
    final id = (userMap['id'] ?? userMap['user_id'] ?? '').toString();
    final name = (userMap['name'] ?? userMap['customer_name'] ?? 'Customer').toString();
    Get.to(() => CustomerLedgerScreen(customerId: id, customerName: name));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    final String fullName = (HiveHelp.read(Keys.userFullName) ?? '').toString().trim();
    final String userName = (HiveHelp.read(Keys.userName) ?? '').toString().trim();
    final String merchantDisplayName = fullName.isNotEmpty
        ? fullName
        : (userName.isNotEmpty ? userName : 'Merchant Store');

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF0C111D) : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        toolberHeight: 64.h,
        prefferSized: 64.h,
        bgColor: isDark ? const Color(0xFF0C111D) : Colors.white,
        isTitleMarginTop: false,
        titleWidget: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Image.asset(
                "$rootImageDir/app_logo.png",
                height: 28.h,
                fit: BoxFit.contain,
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
                    color: isDark ? Colors.white : const Color(0xFF101828),
                  ),
                ),
                Text(
                  _greetingMessage(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D2939) : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.menu_rounded,
              color: isDark ? Colors.white : const Color(0xFF344054),
              size: 20.sp,
            ),
          ),
        ),
        actions: [
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
                      color: isDark ? const Color(0xFF1D2939) : const Color(0xFFF2F4F7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: isDark ? Colors.white : const Color(0xFF344054),
                      size: 20.sp,
                    ),
                  ),
                ),
                if (!notiCtrl.isSeen.value)
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: CircleAvatar(
                      radius: 4.r,
                      backgroundColor: const Color(0xFFD92D20),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
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
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Udhar Summary Cards ─────────────────────────────────────
              GetBuilder<UdharController>(
                builder: (udharCtrl) {
                  double totalUdharGiven = 0.0;
                  int debtorCount = 0;
                  for (var u in udharCtrl.usersList) {
                    final b = double.tryParse((u['balance'] ?? u['udhar_balance'] ?? 0).toString()) ?? 0.0;
                    if (b > 0) {
                      totalUdharGiven += b;
                      debtorCount++;
                    }
                  }

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF101828), Color(0xFF1D2939)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
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
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD92D20).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Color(0xFFF04438),
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  "Total Udhar Diya (Pending)",
                                  style: TextStyle(
                                    color: const Color(0xFF98A2B3),
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.mainColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                "$debtorCount Customers",
                                style: TextStyle(
                                  color: const Color(0xFF53B1FD),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          "₹${totalUdharGiven.toStringAsFixed(0)}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Divider(color: Colors.white.withOpacity(0.1), height: 1),
                        SizedBox(height: 14.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Ledger Safety Status",
                              style: TextStyle(
                                color: const Color(0xFF98A2B3),
                                fontSize: 12.sp,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: const Color(0xFF12B76A), size: 14.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  "Active Monitoring",
                                  style: TextStyle(
                                    color: const Color(0xFF12B76A),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 20.h),

              // ── 2. Fintech Quick Actions (Udhar Diya / Vasooli / Add Customer) ──
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      context,
                      label: "Udhar Diya",
                      subLabel: "+ Give Credit",
                      color: const Color(0xFFD92D20),
                      icon: Icons.arrow_outward_rounded,
                      onTap: () async {
                        final selected = await SelectUserSheet.show(context);
                        if (selected != null) {
                          _navigateToLedger(selected);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildQuickActionButton(
                      context,
                      label: "Vasooli",
                      subLabel: "✓ Collect Payment",
                      color: const Color(0xFF12B76A),
                      icon: Icons.arrow_downward_rounded,
                      onTap: () async {
                        final selected = await SelectUserSheet.show(context);
                        if (selected != null) {
                          _navigateToLedger(selected);
                        }
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // ── 3. Udhar Leaderboard Section ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF79009).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFF79009), size: 18),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Udhar Leaderboard",
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF101828),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final selected = await SelectUserSheet.show(context);
                      if (selected != null) {
                        _navigateToLedger(selected);
                      }
                    },
                    icon: const Icon(Icons.people_alt_outlined, size: 16),
                    label: Text(
                      "All Customers",
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10.h),

              // Search Bar for Leaderboard
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D2939) : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF344054) : const Color(0xFFEAECF0),
                  ),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search customer by name or phone...",
                    hintStyle: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? const Color(0xFF667085) : const Color(0xFF98A2B3),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF667085)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Leaderboard List
              GetBuilder<UdharController>(
                builder: (udharCtrl) {
                  if (udharCtrl.isUsersLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  // Sort users by highest balance pending
                  List<dynamic> sortedList = List.from(udharCtrl.usersList);
                  sortedList.sort((a, b) {
                    double balA = double.tryParse((a['balance'] ?? a['udhar_balance'] ?? 0).toString()) ?? 0.0;
                    double balB = double.tryParse((b['balance'] ?? b['udhar_balance'] ?? 0).toString()) ?? 0.0;
                    return balB.compareTo(balA);
                  });

                  if (_searchQuery.isNotEmpty) {
                    sortedList = sortedList.where((u) {
                      final name = (u['name'] ?? u['customer_name'] ?? '').toString().toLowerCase();
                      final phone = (u['phone'] ?? u['mobile'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) || phone.contains(_searchQuery);
                    }).toList();
                  }

                  if (sortedList.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1D2939) : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.person_search_outlined, size: 40.sp, color: const Color(0xFF98A2B3)),
                          SizedBox(height: 10.h),
                          Text(
                            "No Udhar Customers Found",
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF101828),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Tap + Give Credit to add your first customer transaction.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedList.length > 10 ? 10 : sortedList.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final customer = sortedList[index];
                      final name = (customer['name'] ?? customer['customer_name'] ?? 'Customer').toString();
                      final phone = (customer['phone'] ?? customer['mobile'] ?? '').toString();
                      final balance = double.tryParse((customer['balance'] ?? customer['udhar_balance'] ?? 0).toString()) ?? 0.0;
                      final rank = index + 1;

                      // Badge Colors for Top 3
                      Color rankBgColor = const Color(0xFFF2F4F7);
                      Color rankTextColor = const Color(0xFF344054);
                      if (rank == 1) {
                        rankBgColor = const Color(0xFFFEF0C7);
                        rankTextColor = const Color(0xFFDC6803);
                      } else if (rank == 2) {
                        rankBgColor = const Color(0xFFF2F4F7);
                        rankTextColor = const Color(0xFF475467);
                      } else if (rank == 3) {
                        rankBgColor = const Color(0xFFFFEAD5);
                        rankTextColor = const Color(0xFFB54708);
                      }

                      return InkWell(
                        onTap: () => _navigateToLedger(Map<String, dynamic>.from(customer)),
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          padding: EdgeInsets.all(14.r),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1D2939) : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark ? const Color(0xFF344054) : const Color(0xFFEAECF0),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Rank Badge
                              Container(
                                width: 28.w,
                                height: 28.w,
                                decoration: BoxDecoration(
                                  color: rankBgColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "#$rank",
                                    style: TextStyle(
                                      color: rankTextColor,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              // Customer Avatar & Details
                              CircleAvatar(
                                radius: 20.r,
                                backgroundColor: AppColors.mainColor.withOpacity(0.12),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                  style: TextStyle(
                                    color: AppColors.mainColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
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
                                        color: isDark ? Colors.white : const Color(0xFF101828),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      phone.isNotEmpty ? phone : "No phone registered",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF667085),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Balance & Quick WhatsApp Reminder Action
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "₹${balance.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w900,
                                      color: balance > 0 ? const Color(0xFFD92D20) : const Color(0xFF12B76A),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  if (balance > 0 && phone.isNotEmpty)
                                    InkWell(
                                      onTap: () => _sendWhatsAppReminder(phone, name, balance),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF25D366).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.chat_bubble_outline_rounded, size: 10.sp, color: const Color(0xFF25D366)),
                                            SizedBox(width: 4.w),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required String subLabel,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.2), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 16.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF667085),
              ),
            ),
          ],
        ),
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
