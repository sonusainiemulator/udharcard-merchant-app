import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/custom_appbar.dart';
import 'add_customer_screen.dart';
import 'customer_ledger_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
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

    return GetBuilder<UdharController>(
      builder: (controller) {
        // Calculate totals
        double totalOutstanding = 0.0;
        double totalAdvance = 0.0;
        int debtorCount = 0;

        for (var u in controller.usersList) {
          double bal = double.tryParse((u['outstanding_balance'] ??
                      u['balance'] ??
                      u['udhar_balance'] ??
                      0)
                  .toString()) ??
              0.0;
          if (bal > 0) {
            totalOutstanding += bal;
            debtorCount++;
          } else if (bal < 0) {
            totalAdvance += bal.abs();
          }
        }

        // Apply Filter Tab & Search Query
        List<dynamic> list = List.from(controller.usersList);

        if (_activeFilterTab == "Get") {
          list = list.where((u) {
            double bal = double.tryParse((u['outstanding_balance'] ??
                        u['balance'] ??
                        u['udhar_balance'] ??
                        0)
                    .toString()) ??
                0.0;
            return bal > 0;
          }).toList();
        } else if (_activeFilterTab == "Give") {
          list = list.where((u) {
            double bal = double.tryParse((u['outstanding_balance'] ??
                        u['balance'] ??
                        u['udhar_balance'] ??
                        0)
                    .toString()) ??
                0.0;
            return bal < 0;
          }).toList();
        } else if (_activeFilterTab == "Settled") {
          list = list.where((u) {
            double bal = double.tryParse((u['outstanding_balance'] ??
                        u['balance'] ??
                        u['udhar_balance'] ??
                        0)
                    .toString()) ??
                0.0;
            return bal == 0;
          }).toList();
        }

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

        // Sort by highest pending balance first
        list.sort((a, b) {
          double balA = double.tryParse((a['outstanding_balance'] ??
                      a['balance'] ??
                      a['udhar_balance'] ??
                      0)
                  .toString()) ??
              0.0;
          double balB = double.tryParse((b['outstanding_balance'] ??
                      b['balance'] ??
                      b['udhar_balance'] ??
                      0)
                  .toString()) ??
              0.0;
          return balB.compareTo(balA);
        });

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
          appBar: CustomAppBar(
            title: storedLanguage['Customers'] ?? 'Customer Directory',
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => openAddCustomerScreen(
              storedLanguage: storedLanguage,
            ),
            backgroundColor: AppColors.mainColor,
            elevation: 6,
            icon: const Icon(Icons.person_add_alt_1_rounded,
                color: Colors.white),
            label: Text(
              storedLanguage['Add Customer'] ?? 'Add Customer',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.mainColor,
            onRefresh: () => controller.fetchUsers(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Subscription Plan Usage Banner ─────────────────────
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: controller.customerLimitState.isAtOrOverLimit
                          ? const Color(0xFFFEF3C7)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: controller.customerLimitState.isAtOrOverLimit
                            ? const Color(0xFFF59E0B)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.customerLimitState.summaryLabel,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                          ),
                        ),
                        if (controller.customerLimitState.isNearLimit)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              controller.customerLimitState.isAtOrOverLimit
                                  ? 'Soft-gating active: Add is still enabled. Upgrade before hard limits go live.'
                                  : 'You are near plan limit. Upgrade recommended before hard limits are enabled.',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Offline Warning Banner ──────────────────────────────
                  if (controller.isOffline)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.symmetric(
                          vertical: 8.h, horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              color: Colors.white, size: 16.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Offline Mode — Showing Cached Directory',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Hero Dual Summary Banner ────────────────────────────
                  Container(
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
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.35)
                              : const Color(0xFF312E81).withValues(alpha: 0.2),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.arrow_upward_rounded,
                                      color: Color(0xFFF87171), size: 14),
                                  SizedBox(width: 4.w),
                                  Text(
                                    "Aapko Milega",
                                    style: TextStyle(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                "₹${totalOutstanding.toStringAsFixed(0)}",
                                style: TextStyle(
                                  color: const Color(0xFFF87171),
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                "$debtorCount Debtors Pending",
                                style: TextStyle(
                                  color: const Color(0xFF64748B),
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 44.h,
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.15),
                          margin: EdgeInsets.symmetric(horizontal: 12.w),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.arrow_downward_rounded,
                                      color: Color(0xFF34D399), size: 14),
                                  SizedBox(width: 4.w),
                                  Text(
                                    "Aapko Dena",
                                    style: TextStyle(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                "₹${totalAdvance.toStringAsFixed(0)}",
                                style: TextStyle(
                                  color: const Color(0xFF34D399),
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                "Advance Credit",
                                style: TextStyle(
                                  color: const Color(0xFF64748B),
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // ── Search Bar Input ──────────────────────────────────
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
                        hintText: "Search customer by name or phone...",
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

                  // ── Segmented Filter Chips ─────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip("All", "All Customers (${controller.usersList.length})"),
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

                  // ── Customer Directory List ─────────────────────────────
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
                                  vertical: 32.h, horizontal: 20.w),
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
                                        (customer['outstanding_balance'] ??
                                                customer['balance'] ??
                                                customer['udhar_balance'] ??
                                                0)
                                            .toString()) ??
                                    0.0;
                                final creditLimit = double.tryParse(
                                        (customer['credit_limit'] ?? 0)
                                            .toString()) ??
                                    0.0;
                                final rank = index + 1;

                                // Rank styling for top 3
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

                                        // Customer Avatar
                                        CircleAvatar(
                                          radius: 19.r,
                                          backgroundColor: AppColors.mainColor
                                              .withValues(alpha: 0.12),
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

                                        // Name & Phone & Credit Limit
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                              Row(
                                                children: [
                                                  Text(
                                                    phone.isNotEmpty
                                                        ? phone
                                                        : "No phone registered",
                                                    style: TextStyle(
                                                      fontSize: 11.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          const Color(0xFF64748B),
                                                    ),
                                                  ),
                                                  if (creditLimit > 0) ...[
                                                    SizedBox(width: 6.w),
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 5.w,
                                                              vertical: 1.h),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .mainColor
                                                            .withValues(
                                                                alpha: 0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                4.r),
                                                      ),
                                                      child: Text(
                                                        "Limit: ₹${creditLimit.toInt()}",
                                                        style: TextStyle(
                                                          fontSize: 9.sp,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .mainColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Balance & Action Button
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
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
                                                onTap: () =>
                                                    _sendWhatsAppReminder(
                                                        phone, name, balance),
                                                borderRadius:
                                                    BorderRadius.circular(6.r),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 7.w,
                                                      vertical: 3.h),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF25D366)
                                                            .withValues(
                                                                alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6.r),
                                                    border: Border.all(
                                                      color:
                                                          const Color(0xFF25D366)
                                                              .withValues(
                                                                  alpha: 0.3),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .chat_bubble_rounded,
                                                        size: 10.sp,
                                                        color: const Color(
                                                            0xFF25D366),
                                                      ),
                                                      SizedBox(width: 3.w),
                                                      Text(
                                                        "Remind",
                                                        style: TextStyle(
                                                          color: const Color(
                                                              0xFF25D366),
                                                          fontSize: 10.sp,
                                                          fontWeight:
                                                              FontWeight.w800,
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
                  SizedBox(height: 70.h), // Spacing for FAB
                ],
              ),
            ),
          ),
        );
      },
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
}
