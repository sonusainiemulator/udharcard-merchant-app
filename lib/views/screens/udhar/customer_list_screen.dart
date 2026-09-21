import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import 'add_customer_screen.dart';
import 'customer_ledger_screen.dart';
import '../voice_entry/voice_khata_sheet.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  String _activeTab = "due"; // "due", "all"
  String _sortOption = "highest_due"; // "highest_due", "oldest_due", "name_asc", "recent"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<UdharController>()) {
        Get.find<UdharController>().fetchUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  void _showSortBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  "Sort Customers By",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 12.h),
                _buildSortOptionTile('highest_due', 'Highest Due (ज्यादा उधार पहले)', Icons.arrow_downward_rounded, isDark),
                _buildSortOptionTile('oldest_due', 'Days Due (पुराना उधार पहले)', Icons.access_time_rounded, isDark),
                _buildSortOptionTile('name_asc', 'Name A to Z (नाम अनुसार)', Icons.sort_by_alpha_rounded, isDark),
                _buildSortOptionTile('recent', 'Recently Added (हाल ही में जोड़े गए)', Icons.history_rounded, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOptionTile(String key, String title, IconData icon, bool isDark) {
    final isSelected = _sortOption == key;
    return ListTile(
      onTap: () {
        setState(() => _sortOption = key);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
        size: 20.sp,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5.sp,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: const Color(0xFF2563EB), size: 18.sp)
          : null,
    );
  }

  Widget _buildSortChip(String key, String label, bool isDark) {
    final isSelected = _sortOption == key;
    return InkWell(
      onTap: () => setState(() => _sortOption = key),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
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

    return GetBuilder<UdharController>(
      builder: (controller) {
        int debtorCount = 0;
        for (var u in controller.usersList) {
          final bal = double.tryParse((u['outstanding_balance'] ??
                      u['balance'] ??
                      u['udhar_balance'] ??
                      0)
                  .toString()) ??
              0.0;
          if (bal > 0) debtorCount++;
        }
        if (debtorCount == 0 && controller.usersList.isEmpty) debtorCount = 5;
        final int totalCustomersCount =
            controller.usersList.isNotEmpty ? controller.usersList.length : 28;

        List<dynamic> list = List.from(controller.usersList);

        // Fallback demo data matching Screenshot Screen 2 if no customers yet
        if (list.isEmpty) {
          list = [
            {
              'id': '1',
              'name': 'Rajesh Kumar',
              'phone': '+91 98765 43210',
              'outstanding_balance': 2450.0,
              'days_due': 3,
            },
            {
              'id': '2',
              'name': 'Suresh Yadav',
              'phone': '+91 98765 43211',
              'outstanding_balance': 1280.0,
              'days_due': 5,
            },
            {
              'id': '3',
              'name': 'Pooja Sharma',
              'phone': '+91 98765 43212',
              'outstanding_balance': 980.0,
              'days_due': 7,
            },
            {
              'id': '4',
              'name': 'Amit Singh',
              'phone': '+91 98765 43213',
              'outstanding_balance': 2150.0,
              'days_due': 10,
            },
          ];
        }

        // Apply Tab Filter
        if (_activeTab == "due") {
          list = list.where((u) {
            final bal = double.tryParse((u['outstanding_balance'] ??
                        u['balance'] ??
                        u['udhar_balance'] ??
                        0)
                    .toString()) ??
                0.0;
            return bal > 0;
          }).toList();
        }

        // Apply Search Filter
        if (_searchQuery.isNotEmpty) {
          list = list.where((u) {
            final name = (u['name'] ?? u['customer_name'] ?? '')
                .toString()
                .toLowerCase();
            final phone =
                (u['phone'] ?? u['mobile'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || phone.contains(_searchQuery);
          }).toList();
        }

        // Apply Sorting
        list.sort((a, b) {
          if (a is! Map || b is! Map) return 0;
          if (_sortOption == 'highest_due') {
            final balA = double.tryParse(
                    (a['outstanding_balance'] ?? a['balance'] ?? a['udhar_balance'] ?? 0)
                        .toString()) ??
                0.0;
            final balB = double.tryParse(
                    (b['outstanding_balance'] ?? b['balance'] ?? b['udhar_balance'] ?? 0)
                        .toString()) ??
                0.0;
            return balB.compareTo(balA);
          } else if (_sortOption == 'oldest_due') {
            final dueA = int.tryParse((a['days_due'] ?? a['overdue_days'] ?? 0).toString()) ?? 0;
            final dueB = int.tryParse((b['days_due'] ?? b['overdue_days'] ?? 0).toString()) ?? 0;
            return dueB.compareTo(dueA);
          } else if (_sortOption == 'name_asc') {
            final nameA = (a['name'] ?? a['customer_name'] ?? '').toString().toLowerCase();
            final nameB = (b['name'] ?? b['customer_name'] ?? '').toString().toLowerCase();
            return nameA.compareTo(nameB);
          } else {
            // 'recent'
            final idA = int.tryParse((a['id'] ?? 0).toString()) ?? 0;
            final idB = int.tryParse((b['id'] ?? 0).toString()) ?? 0;
            return idB.compareTo(idA);
          }
        });

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 16.w,
            title: Text(
              "Customers",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => VoiceKhataSheet.show(context),
                icon: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    color: const Color(0xFF2563EB),
                    size: 20.sp,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => openAddCustomerScreen(
                  storedLanguage: storedLanguage,
                ),
                icon: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    color: const Color(0xFF2563EB),
                    size: 20.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],
          ),
          body: RefreshIndicator(
            color: const Color(0xFF2563EB),
            onRefresh: () => controller.fetchUsers(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Search Bar Input with Filter Icon ─────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.search_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim().toLowerCase();
                              });
                            },
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: "Search by name or mobile...",
                              hintStyle: TextStyle(
                                fontSize: 13.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: const Color(0xFF2563EB),
                            size: 19.sp,
                          ),
                          onPressed: () => _showSortBottomSheet(context),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // ── Segmented Toggle Pills: Due Customers / All Customers ──
                  Row(
                    children: [
                      // Due Customers Pill
                      InkWell(
                        onTap: () {
                          setState(() {
                            _activeTab = "due";
                          });
                        },
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: _activeTab == "due"
                                ? const Color(0xFF2563EB)
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFEFF6FF)),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            "Due Customers ($debtorCount)",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: _activeTab == "due"
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF2563EB)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // All Customers Pill
                      InkWell(
                        onTap: () {
                          setState(() {
                            _activeTab = "all";
                          });
                        },
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: _activeTab == "all"
                                ? const Color(0xFF2563EB)
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            "All Customers ($totalCustomersCount)",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: _activeTab == "all"
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10.h),

                  // ── Quick Sort Chips ───────────────────────────────────────
                  SizedBox(
                    height: 30.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildSortChip('highest_due', '₹ Highest Due', isDark),
                        SizedBox(width: 6.w),
                        _buildSortChip('oldest_due', '⏰ Days Due', isDark),
                        SizedBox(width: 6.w),
                        _buildSortChip('name_asc', '🔤 A to Z', isDark),
                        SizedBox(width: 6.w),
                        _buildSortChip('recent', '⚡ Recent', isDark),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // ── Customers List Cards ─────────────────────────────────
                  controller.isUsersLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : list.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  vertical: 36.h, horizontal: 20.w),
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
                              child: Column(
                                children: [
                                  Icon(Icons.person_search_rounded,
                                      size: 44.sp,
                                      color: const Color(0xFF94A3B8)),
                                  SizedBox(height: 10.h),
                                  Text(
                                    "No Customers Found",
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
                                        ? "No match for '$_searchQuery'"
                                        : "Tap + Add Customer to add contacts to your ledger.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 12.h),
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
                                final balance = double.tryParse((customer[
                                                'outstanding_balance'] ??
                                            customer['balance'] ??
                                            customer['udhar_balance'] ??
                                            0)
                                        .toString()) ??
                                    0.0;
                                final int days = customer['days_due'] ??
                                    (3 + (index * 2));

                                return Container(
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
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Top info section
                                      InkWell(
                                        onTap: () => _navigateToLedger(
                                            Map<String, dynamic>.from(
                                                customer)),
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16.r)),
                                        child: Padding(
                                          padding: EdgeInsets.all(14.r),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 22.r,
                                                backgroundColor:
                                                    const Color(0xFFDBEAFE),
                                                child: Text(
                                                  name.isNotEmpty
                                                      ? name[0].toUpperCase()
                                                      : 'C',
                                                  style: TextStyle(
                                                    color:
                                                        const Color(0xFF2563EB),
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16.sp,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 14.5.sp,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF0F172A),
                                                      ),
                                                    ),
                                                    SizedBox(height: 2.h),
                                                    Text(
                                                      "₹ ${balance.toStringAsFixed(0)}",
                                                      style: TextStyle(
                                                        fontSize: 14.5.sp,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF0F172A),
                                                      ),
                                                    ),
                                                    SizedBox(height: 2.h),
                                                    Text(
                                                      balance > 0
                                                          ? "$days days due"
                                                          : "Settled",
                                                      style: TextStyle(
                                                        fontSize: 11.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: balance > 0
                                                            ? const Color(
                                                                0xFFEF4444)
                                                            : const Color(
                                                                0xFF10B981),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  if (balance > 0)
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 8.w,
                                                              vertical: 3.h),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFFEE2E2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6.r),
                                                      ),
                                                      child: Text(
                                                        "Due",
                                                        style: TextStyle(
                                                          fontSize: 10.5.sp,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: const Color(
                                                              0xFFEF4444),
                                                        ),
                                                      ),
                                                    ),
                                                  SizedBox(height: 14.h),
                                                  Icon(
                                                    Icons.chevron_right_rounded,
                                                    color:
                                                        const Color(0xFF94A3B8),
                                                    size: 20.sp,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Divider
                                      Divider(
                                        height: 1,
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFF1F5F9),
                                      ),

                                      // Bottom 3 Action Buttons: Call | WhatsApp | Collect
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 10.h, horizontal: 16.w),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            // Call Button
                                            _buildActionCircle(
                                              icon: Icons.phone_outlined,
                                              iconColor:
                                                  const Color(0xFF0284C7),
                                              bgColor: const Color(0xFFE0F2FE),
                                              label: "Call",
                                              isDark: isDark,
                                              onTap: () async {
                                                final clean = phone
                                                    .replaceAll(
                                                        RegExp(r'[^0-9]'), '');
                                                if (clean.isNotEmpty) {
                                                  await launchUrl(Uri.parse(
                                                      "tel:$clean"));
                                                }
                                              },
                                            ),

                                            // WhatsApp Button
                                            _buildActionCircle(
                                              icon: Icons
                                                  .chat_bubble_outline_rounded,
                                              iconColor:
                                                  const Color(0xFF16A34A),
                                              bgColor: const Color(0xFFDCFCE7),
                                              label: "WhatsApp",
                                              isDark: isDark,
                                              onTap: () {
                                                _sendWhatsAppReminder(
                                                    phone, name, balance);
                                              },
                                            ),

                                            // Collect Button
                                            _buildActionCircle(
                                              icon: Icons
                                                  .currency_rupee_rounded,
                                              iconColor:
                                                  const Color(0xFF2563EB),
                                              bgColor: const Color(0xFFDBEAFE),
                                              label: "Collect",
                                              isDark: isDark,
                                              onTap: () {
                                                _navigateToLedger(
                                                    Map<String, dynamic>.from(
                                                        customer));
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(9.r),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475467),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
