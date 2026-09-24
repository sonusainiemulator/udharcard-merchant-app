import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import 'add_customer_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "all"; // "all", "supplier", "dealer", "wholesaler", "due"

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

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleanPhone.isEmpty) {
      Helpers.showSnackBar(msg: "No phone number available", title: "Error");
      return;
    }
    final Uri url = Uri.parse("tel:$cleanPhone");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch phone call: $e");
    }
  }

  Future<void> _openWhatsApp(String phone, String name, double amount) async {
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final formattedPhone =
        cleanPhone.startsWith('+') ? cleanPhone.replaceAll('+', '') : '91$cleanPhone';
    final String shopName =
        (HiveHelp.read('shop_name') ?? 'Udhar Card Merchant').toString().trim();

    final String messageText =
        "Namaste $name ji 🙏\n\n"
        "Regarding our purchase ledger for $shopName.\n"
        "Recorded payable balance: ₹${amount.toStringAsFixed(0)}.\n\n"
        "Thank you for your partnership!";

    final String whatsappUrl =
        "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(messageText)}";
    final Uri uri = Uri.parse(whatsappUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(Uri.parse("https://api.whatsapp.com/send?phone=$formattedPhone&text=${Uri.encodeComponent(messageText)}"),
            mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch WhatsApp: $e");
    }
  }

  void _showRecordPaymentBottomSheet(
      BuildContext context, Map<String, dynamic> supplier, UdharController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = (supplier['name'] ?? supplier['customer_name'] ?? 'Supplier').toString();
    final supplierId = (supplier['id'] ?? '').toString();
    final double payable = double.tryParse((supplier['payable_amount'] ??
                supplier['outstanding_balance'] ??
                supplier['opening_balance'] ??
                0)
            .toString()) ??
        0.0;

    final TextEditingController paymentAmountCtrl = TextEditingController(
      text: payable > 0 ? payable.toStringAsFixed(0) : '',
    );
    final TextEditingController noteCtrl = TextEditingController();
    String selectedMethod = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_circle_outline_rounded,
                              color: const Color(0xFF10B981), size: 24.sp),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Record Payment to Supplier",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Pending Payable:",
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                          Text(
                            "₹${payable.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Amount Paid (₹)",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: paymentAmountCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20.sp),
                        hintText: "Enter amount",
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      "Payment Mode",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        _buildPaymentMethodOption(
                          label: "Cash",
                          value: "cash",
                          icon: Icons.money_rounded,
                          selected: selectedMethod == "cash",
                          onTap: () => setModalState(() => selectedMethod = "cash"),
                          isDark: isDark,
                        ),
                        SizedBox(width: 10.w),
                        _buildPaymentMethodOption(
                          label: "UPI / Online",
                          value: "upi",
                          icon: Icons.qr_code_rounded,
                          selected: selectedMethod == "upi",
                          onTap: () => setModalState(() => selectedMethod = "upi"),
                          isDark: isDark,
                        ),
                        SizedBox(width: 10.w),
                        _buildPaymentMethodOption(
                          label: "Bank Transfer",
                          value: "bank",
                          icon: Icons.account_balance_rounded,
                          selected: selectedMethod == "bank",
                          onTap: () => setModalState(() => selectedMethod = "bank"),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      "Note / Bill No. (Optional)",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: noteCtrl,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: "e.g. Paid weekly bill #402",
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () async {
                          final double? amt = double.tryParse(paymentAmountCtrl.text.trim());
                          if (amt == null || amt <= 0) {
                            Helpers.showSnackBar(
                              msg: "Please enter a valid payment amount",
                              title: "Invalid Amount",
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          await controller.recordSupplierPayment(
                            supplierId: supplierId,
                            amountPaid: amt,
                            paymentMethod: selectedMethod,
                            note: noteCtrl.text.trim(),
                          );
                        },
                        child: Text(
                          "Confirm Payment",
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentMethodOption({
    required String label,
    required String value,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF10B981).withOpacity(0.12)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected ? const Color(0xFF10B981) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: selected
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white : const Color(0xFF334155)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Map storedLanguage = HiveHelp.read(Keys.languageData) ?? {};

    return GetBuilder<UdharController>(
      builder: (controller) {
        final List<dynamic> baseSuppliers = controller.suppliersList;
        final double totalPayable = controller.totalPayableToSuppliers;

        int pendingDueCount = 0;
        for (var s in baseSuppliers) {
          if (s is Map) {
            final amt = double.tryParse((s['payable_amount'] ??
                        s['outstanding_balance'] ??
                        s['opening_balance'] ??
                        0)
                    .toString()) ??
                0.0;
            if (amt > 0) pendingDueCount++;
          }
        }

        List<dynamic> list = List.from(baseSuppliers);

        // Filter by Category
        if (_selectedCategory == "supplier") {
          list = list.where((s) => (s['type'] ?? s['party_type'] ?? '').toString().toLowerCase() == 'supplier').toList();
        } else if (_selectedCategory == "dealer") {
          list = list.where((s) => (s['type'] ?? s['party_type'] ?? '').toString().toLowerCase() == 'dealer').toList();
        } else if (_selectedCategory == "wholesaler") {
          list = list.where((s) => (s['type'] ?? s['party_type'] ?? '').toString().toLowerCase() == 'wholesaler').toList();
        } else if (_selectedCategory == "due") {
          list = list.where((s) {
            final amt = double.tryParse((s['payable_amount'] ?? s['outstanding_balance'] ?? 0).toString()) ?? 0.0;
            return amt > 0;
          }).toList();
        }

        // Filter by Search Query
        if (_searchQuery.isNotEmpty) {
          list = list.where((s) {
            final name = (s['name'] ?? s['customer_name'] ?? '').toString().toLowerCase();
            final phone = (s['phone'] ?? s['mobile'] ?? '').toString().toLowerCase();
            final type = (s['type'] ?? s['party_type'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || phone.contains(_searchQuery) || type.contains(_searchQuery);
          }).toList();
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                size: 18.sp,
              ),
              onPressed: () => Get.back(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Suppliers & Dealers",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "Payables Ledger (Dene Hain)",
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => openAddCustomerScreen(
                  storedLanguage: storedLanguage,
                  initialType: 'Supplier',
                ),
                icon: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_business_rounded,
                    color: const Color(0xFFDC2626),
                    size: 20.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],
          ),
          body: RefreshIndicator(
            color: const Color(0xFFDC2626),
            onRefresh: () => controller.fetchUsers(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Segmented Toggle: Customers (Lene Hain) vs Suppliers (Dene Hain) ──
                  Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Get.offNamed(RoutesName.customerListScreen);
                            },
                            borderRadius: BorderRadius.circular(10.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              alignment: Alignment.center,
                              child: Text(
                                "👤 Customers (${controller.customersOnlyList.length})",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFDC2626).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              "🏢 Suppliers & Dealers (${baseSuppliers.length})",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Hero Summary Card: Total Payable to Suppliers ──
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.35),
                          blurRadius: 12,
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
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(5.r),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Colors.white,
                                      size: 15.sp,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Flexible(
                                    child: Text(
                                      "Total You Owe (कुल देने हैं)",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.92),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            InkWell(
                              onTap: () => openAddCustomerScreen(
                                storedLanguage: storedLanguage,
                                initialType: 'Supplier',
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  "+ Add Credit",
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          "₹${totalPayable.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Divider(color: Colors.white.withOpacity(0.2), height: 1),
                        SizedBox(height: 10.h),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12.w,
                          runSpacing: 4.h,
                          children: [
                            Text(
                              "Pending Payments: $pendingDueCount",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Total Suppliers: ${baseSuppliers.length}",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // ── Search Input ──
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: "Search supplier, dealer or phone...",
                              hintStyle: TextStyle(
                                fontSize: 13.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 18.sp, color: const Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = "");
                            },
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // ── Category Filter Chips ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip("All", "all", isDark),
                        SizedBox(width: 8.w),
                        _buildFilterChip("Payment Due", "due", isDark),
                        SizedBox(width: 8.w),
                        _buildFilterChip("Wholesalers", "wholesaler", isDark),
                        SizedBox(width: 8.w),
                        _buildFilterChip("Dealers", "dealer", isDark),
                        SizedBox(width: 8.w),
                        _buildFilterChip("Suppliers", "supplier", isDark),
                      ],
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // ── Supplier List or Empty State ──
                  if (list.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 48.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            "No Suppliers or Dealers Found",
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            _searchQuery.isNotEmpty
                                ? "No supplier matching '$_searchQuery'"
                                : "Add wholesalers and suppliers from whom you purchase goods on credit.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            onPressed: () => openAddCustomerScreen(
                              storedLanguage: storedLanguage,
                              initialType: 'Supplier',
                            ),
                            icon: Icon(Icons.add_business_rounded, size: 16.sp, color: Colors.white),
                            label: Text(
                              "+ Add First Supplier",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final supplier = list[index];
                        final name = (supplier['name'] ?? supplier['customer_name'] ?? 'Supplier').toString();
                        final phone = (supplier['phone'] ?? supplier['mobile'] ?? '').toString();
                        final type = (supplier['type'] ?? supplier['party_type'] ?? 'Supplier').toString();
                        final double payable = double.tryParse((supplier['payable_amount'] ??
                                    supplier['outstanding_balance'] ??
                                    supplier['opening_balance'] ??
                                    0)
                                .toString()) ??
                            0.0;
                        final dueDate = supplier['due_date']?.toString();

                        return Container(
                          padding: EdgeInsets.all(14.r),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar
                                  Container(
                                    width: 44.r,
                                    height: 44.r,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  // Name & Type
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 3.h),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(4.r),
                                              ),
                                              child: Text(
                                                type.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9.5.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF92400E),
                                                ),
                                              ),
                                            ),
                                            if (phone.isNotEmpty) ...[
                                              SizedBox(width: 6.w),
                                              Flexible(
                                                child: Text(
                                                  phone,
                                                  style: TextStyle(
                                                    fontSize: 11.sp,
                                                    color: const Color(0xFF64748B),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // BIG BOLD RED PAYABLE AMOUNT
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "₹${payable.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                      Text(
                                        "Dene Hain",
                                        style: TextStyle(
                                          fontSize: 10.5.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF991B1B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Due Date banner if present
                              if (dueDate != null && dueDate.isNotEmpty) ...[
                                SizedBox(height: 10.h),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 13.sp,
                                        color: const Color(0xFFDC2626),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        "Due: $dueDate",
                                        style: TextStyle(
                                          fontSize: 11.5.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              SizedBox(height: 12.h),
                              Divider(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                height: 1,
                              ),
                              SizedBox(height: 8.h),

                              // Action Buttons: Call, WhatsApp, Pay
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                alignment: WrapAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (phone.isNotEmpty) ...[
                                        InkWell(
                                          onTap: () => _makePhoneCall(phone),
                                          borderRadius: BorderRadius.circular(8.r),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(8.r),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.call_rounded, size: 13.sp, color: const Color(0xFF2563EB)),
                                                SizedBox(width: 3.w),
                                                Text(
                                                  "Call",
                                                  style: TextStyle(
                                                    fontSize: 11.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? Colors.white : const Color(0xFF334155),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        InkWell(
                                          onTap: () => _openWhatsApp(phone, name, payable),
                                          borderRadius: BorderRadius.circular(8.r),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8.r),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.chat_bubble_outline_rounded,
                                                    size: 13.sp, color: const Color(0xFF16A34A)),
                                                SizedBox(width: 3.w),
                                                Text(
                                                  "WhatsApp",
                                                  style: TextStyle(
                                                    fontSize: 11.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF16A34A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                    ),
                                    onPressed: () => _showRecordPaymentBottomSheet(
                                      context,
                                      supplier,
                                      controller,
                                    ),
                                    child: Text(
                                      "✓ Pay / Settle",
                                      style: TextStyle(
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
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

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final bool isSelected = _selectedCategory == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedCategory = value);
      },
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFDC2626)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
