import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/spacing.dart';
import '../../widgets/text_theme_extension.dart';
import 'customer_ledger_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String selectedFilter = 'all'; // active, all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<UdharController>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};

    return GetBuilder<UdharController>(
      builder: (controller) {
        // Calculate totals
        double totalOutstanding = 0.0;
        double totalAdvance = 0.0;
        int activeCount = 0;
        for (var u in controller.usersList) {
          double bal =
              double.tryParse(u['outstanding_balance']?.toString() ?? '0') ??
              0.0;
          if (bal > 0) totalOutstanding += bal;
          if (bal < 0) totalAdvance += bal.abs();
          if (bal != 0) activeCount++;
        }

        // Apply filter
        List<dynamic> displayList =
            controller.filteredUsers.where((u) {
              double bal =
                  double.tryParse(
                    u['outstanding_balance']?.toString() ?? '0',
                  ) ??
                  0.0;
              if (selectedFilter == 'active') return bal != 0;
              return true;
            }).toList();

        return Scaffold(
          backgroundColor:
              Get.isDarkMode ? AppColors.darkBgColor : AppColors.scaffoldColor,
          appBar: CustomAppBar(
            title: storedLanguage['Customers'] ?? 'Customers Ledger',
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed:
                () =>
                    _showAddCustomerSheet(context, controller, storedLanguage),
            backgroundColor: AppColors.mainColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(storedLanguage['Add Customer'] ?? 'Add Customer'),
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
              // ── Khatabook-style summary strip ─────────────────────
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color:
                      Get.isDarkMode
                          ? AppColors.darkCardColor
                          : AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StripStat(
                        title: storedLanguage['You Will Get'] ?? 'You Will Get',
                        value: '₹${totalOutstanding.toStringAsFixed(0)}',
                        valueColor: AppColors.greenColor,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 42.h,
                      color: AppColors.borderColor,
                    ),
                    HSpace(10.w),
                    Expanded(
                      child: _StripStat(
                        title:
                            storedLanguage['You Will Give'] ?? 'You Will Give',
                        value: '₹${totalAdvance.toStringAsFixed(0)}',
                        valueColor: AppColors.redColor,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 42.h,
                      color: AppColors.borderColor,
                    ),
                    HSpace(10.w),
                    Expanded(
                      child: _StripStat(
                        title:
                            storedLanguage['Active Accounts'] ??
                            'Active Accounts',
                        value: '$activeCount',
                        valueColor: AppColors.mainColor,
                      ),
                    ),
                  ],
                ),
              ),

              VSpace(4.h),

              // ── Segmented Directory Filter Tabs ───────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color:
                        Get.isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.fillColorColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => setState(() => selectedFilter = 'active'),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  selectedFilter == 'active'
                                      ? AppColors.mainColor
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              storedLanguage['Active Ledgers'] ??
                                  'Active Ledgers',
                              style: TextStyle(
                                color:
                                    selectedFilter == 'active'
                                        ? Colors.white
                                        : AppColors.black50,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedFilter = 'all'),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  selectedFilter == 'all'
                                      ? AppColors.mainColor
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              storedLanguage['All Contacts'] ?? 'All Contacts',
                              style: TextStyle(
                                color:
                                    selectedFilter == 'all'
                                        ? Colors.white
                                        : AppColors.black50,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              VSpace(8.h),

              // ── Search Bar ────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: TextField(
                  controller: controller.searchCtrl,
                  onChanged: controller.searchUsers,
                  decoration: InputDecoration(
                    hintText:
                        storedLanguage['Search by name/phone'] ??
                        'Search name or phone...',
                    hintStyle: context.t.bodySmall?.copyWith(
                      color: AppColors.textFieldHintColor,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.black50,
                      size: 20.sp,
                    ),
                    filled: true,
                    fillColor:
                        Get.isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.fillColorColor,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              VSpace(16.h),

              // ── Customer List ─────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.mainColor,
                  onRefresh: () => controller.fetchUsers(),
                  child:
                      controller.isUsersLoading
                          ? const Center(child: CircularProgressIndicator())
                          : displayList.isEmpty
                          ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 100.h),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 64.sp,
                                      color: AppColors.black30,
                                    ),
                                    VSpace(12.h),
                                    Text(
                                      storedLanguage['No customers found'] ??
                                          'No customers found',
                                      style: context.t.bodyLarge?.copyWith(
                                        color: AppColors.black50,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                          : ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 8.h,
                            ),
                            itemCount: displayList.length,
                            separatorBuilder: (_, __) => VSpace(12.h),
                            itemBuilder: (context, index) {
                              final Map<String, dynamic> user =
                                  Map<String, dynamic>.from(displayList[index]);
                              return Dismissible(
                                key: Key(user['id'].toString()),
                                background: Container(
                                  color: Colors.green,
                                  alignment: Alignment.centerLeft,
                                  padding: EdgeInsets.only(left: 20.w),
                                  child: Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.white,
                                    size: 24.sp,
                                  ),
                                ),
                                secondaryBackground: Container(
                                  color: Colors.green.shade600,
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20.w),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.white,
                                    size: 24.sp,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    // Swipe Left: launch WhatsApp reminder
                                    final double bal =
                                        double.tryParse(
                                          user['outstanding_balance']
                                                  ?.toString() ??
                                              '0',
                                        ) ??
                                        0.0;
                                    if (bal > 0) {
                                      final String message =
                                          "Dear ${user['name']}, this is a friendly reminder that you have an outstanding payment of ₹${bal.toStringAsFixed(2)} due with our shop. Please pay as soon as possible. Thank you!";
                                      final String encodedMsg =
                                          Uri.encodeComponent(message);
                                      await launchUrl(
                                        Uri.parse(
                                          "https://wa.me/?text=$encodedMsg",
                                        ),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      Get.snackbar(
                                        'Settled',
                                        'No outstanding balance to collect.',
                                      );
                                    }
                                    return false; // Don't dismiss card
                                  } else {
                                    // Swipe Right: Quick transaction page
                                    controller.selectUser(user);
                                    Get.toNamed('/addUdharScreen');
                                    return false; // Don't dismiss card
                                  }
                                },
                                child: _CustomerCard(
                                  user: user,
                                  onTap: () {
                                    Get.to(
                                      () => CustomerLedgerScreen(
                                        customerId: user['id'].toString(),
                                        customerName:
                                            (user['name'] ?? '').toString(),
                                      ),
                                    );
                                  },
                                  onDelete: () {
                                    _confirmDelete(
                                      context,
                                      controller,
                                      user['id'].toString(),
                                      user['name'].toString(),
                                      storedLanguage,
                                    );
                                  },
                                  onEditLimit: () {
                                    _showEditCreditLimitSheet(
                                      context,
                                      controller,
                                      user,
                                      storedLanguage,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditCreditLimitSheet(
    BuildContext context,
    UdharController controller,
    Map<String, dynamic> user,
    Map storedLanguage,
  ) {
    final String customerId = user['id']?.toString() ?? '';
    final String customerName = (user['name'] ?? '').toString();
    final String currentLimit =
        (user['credit_limit']?.toString().isNotEmpty == true)
            ? user['credit_limit'].toString()
            : '5000';

    controller.editLimitCtrl.text = currentLimit;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor:
                Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              storedLanguage['Upgrade Credit Limit'] ?? 'Upgrade Credit Limit',
              style: context.t.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: context.t.bodyMedium?.copyWith(
                    color: AppColors.black50,
                  ),
                ),
                VSpace(10.h),
                CustomTextField(
                  hintext: storedLanguage['Credit Limit'] ?? 'Credit Limit (₹)',
                  controller: controller.editLimitCtrl,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(storedLanguage['Cancel'] ?? 'Cancel'),
              ),
              GetBuilder<UdharController>(
                builder:
                    (ctrl) => TextButton(
                      onPressed:
                          ctrl.isUpdatingLimit
                              ? null
                              : () async {
                                await ctrl.updateCustomerCreditLimit(
                                  customerId: customerId,
                                  creditLimit: ctrl.editLimitCtrl.text,
                                );
                                if (context.mounted) {
                                  Get.back();
                                }
                              },
                      child:
                          ctrl.isUpdatingLimit
                              ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.mainColor,
                                ),
                              )
                              : Text(
                                storedLanguage['Update'] ?? 'Update',
                                style: TextStyle(color: AppColors.mainColor),
                              ),
                    ),
              ),
            ],
          ),
    );
  }

  // ── Show Add Customer Sheet ──────────────────────────────────────────
  void _showAddCustomerSheet(
    BuildContext context,
    UdharController controller,
    Map storedLanguage,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor:
                Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 10.h,
            ),
            titlePadding: EdgeInsets.only(left: 20.w, right: 10.w, top: 10.h),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  storedLanguage['Add Customer'] ?? 'New Customer',
                  style: context.t.bodyLarge?.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.black50,
                    size: 20.sp,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VSpace(10.h),
                    CustomTextField(
                      hintext: storedLanguage['Name'] ?? 'Customer Name *',
                      controller: controller.nameCtrl,
                    ),
                    VSpace(12.h),
                    CustomTextField(
                      hintext: storedLanguage['Phone'] ?? 'Phone Number *',
                      controller: controller.phoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    VSpace(12.h),
                    CustomTextField(
                      hintext:
                          storedLanguage['Email'] ?? 'Email Address (Optional)',
                      controller: controller.emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    VSpace(12.h),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            hintext:
                                storedLanguage['Credit Limit'] ??
                                'Credit Limit (₹)',
                            controller: controller.limitCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        HSpace(12.w),
                        Expanded(
                          child: CustomTextField(
                            hintext:
                                storedLanguage['Opening Balance'] ??
                                'Opening Bal (₹)',
                            controller: controller.openingBalanceCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    VSpace(10.h),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(bottom: 10.h, left: 10.w, right: 10.w),
                child: GetBuilder<UdharController>(
                  builder:
                      (ctrl) => AppButton(
                        text:
                            storedLanguage['Add Customer'] ?? 'Create Customer',
                        isLoading: ctrl.isAddingCustomer,
                        onTap: () => ctrl.addCustomer(),
                      ),
                ),
              ),
            ],
          ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    UdharController controller,
    String id,
    String name,
    Map storedLanguage,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor:
                Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
            title: Text(
              storedLanguage['Delete Customer'] ?? 'Delete Customer?',
            ),
            content: Text(
              '${storedLanguage['Are you sure you want to delete'] ?? 'Are you sure you want to delete'} $name?',
            ),
            actions: [
              TextButton(
                child: Text(
                  storedLanguage['Cancel'] ?? 'Cancel',
                  style: TextStyle(color: AppColors.black50),
                ),
                onPressed: () => Get.back(),
              ),
              TextButton(
                child: Text(
                  storedLanguage['Delete'] ?? 'Delete',
                  style: const TextStyle(color: AppColors.redColor),
                ),
                onPressed: () {
                  Get.back();
                  controller.deleteCustomer(id);
                },
              ),
            ],
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StripStat extends StatelessWidget {
  const _StripStat({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  final String title;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.t.bodySmall?.copyWith(
            fontSize: 11.sp,
            color: AppColors.black50,
          ),
        ),
        VSpace(4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.user,
    required this.onTap,
    required this.onDelete,
    required this.onEditLimit,
  });
  final Map<String, dynamic> user;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEditLimit;

  @override
  Widget build(BuildContext context) {
    final String name = (user['name'] ?? '').toString();
    final String phone = (user['phone'] ?? '').toString();
    final double balance =
        double.tryParse(user['outstanding_balance']?.toString() ?? '0') ?? 0.0;
    final double creditLimit =
        double.tryParse(user['credit_limit']?.toString() ?? '5000') ?? 5000.0;

    final Color balColor =
        balance > 0
            ? AppColors.redColor
            : (balance < 0 ? AppColors.greenColor : AppColors.black50);
    final String balLabel =
        balance > 0
            ? 'Due: ₹${balance.toStringAsFixed(2)}'
            : (balance < 0
                ? 'Advance: ₹${balance.abs().toStringAsFixed(2)}'
                : 'Settled');

    final double limitUsage =
        balance > 0 ? (balance / creditLimit).clamp(0.0, 1.0) : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color:
              Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: AppColors.mainColor.withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: TextStyle(
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                HSpace(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: context.t.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user['customer_user_id'] != null) ...[
                            HSpace(6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                               color: Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                "App User",
                                style: TextStyle(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      VSpace(2.h),
                      Text(
                        phone,
                        style: context.t.bodySmall?.copyWith(
                          color: AppColors.black50,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      balLabel,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: balColor,
                      ),
                    ),
                    VSpace(4.h),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(
                        Icons.delete_outline,
                        color: AppColors.black30,
                        size: 18.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (balance > 0) ...[
              VSpace(12.h),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: limitUsage,
                        minHeight: 4.h,
                        backgroundColor: AppColors.borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          limitUsage > 0.8
                              ? AppColors.redColor
                              : AppColors.mainColor,
                        ),
                      ),
                    ),
                  ),
                  HSpace(8.w),
                  Text(
                    'Limit: ₹${creditLimit.toInt()}',
                    style: TextStyle(fontSize: 10.sp, color: AppColors.black50),
                  ),
                  HSpace(8.w),
                  GestureDetector(
                    onTap: onEditLimit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 14.sp,
                      color: AppColors.mainColor,
                    ),
                  ),
                ],
              ),
            ],
            if (balance <= 0) ...[
              VSpace(10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Limit: ₹${creditLimit.toInt()}',
                    style: TextStyle(fontSize: 10.sp, color: AppColors.black50),
                  ),
                  HSpace(8.w),
                  GestureDetector(
                    onTap: onEditLimit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 14.sp,
                      color: AppColors.mainColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
