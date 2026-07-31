import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paysecure/utils/services/helpers.dart';
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
import 'add_customer_sheet.dart';

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
                    showAddCustomerSheet(
                      context: context,
                      controller: controller,
                      storedLanguage: storedLanguage,
                    ),
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
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color:
                      Get.isDarkMode
                          ? AppColors.darkCardColor
                          : AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blackColor.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StripStat(
                        title: storedLanguage['You Will Get'] ?? 'You Will Get',
                        value: '₹${totalOutstanding.toStringAsFixed(0)}',
                        valueColor: AppColors.greenColor,
                        bgColor: AppColors.greenColor.withValues(alpha: 0.1),
                      ),
                    ),
                    HSpace(8.w),
                    Expanded(
                      child: _StripStat(
                        title:
                            storedLanguage['You Will Give'] ?? 'You Will Give',
                        value: '₹${totalAdvance.toStringAsFixed(0)}',
                        valueColor: AppColors.redColor,
                        bgColor: AppColors.redColor.withValues(alpha: 0.1),
                      ),
                    ),
                    HSpace(8.w),
                    Expanded(
                      child: _StripStat(
                        title:
                            storedLanguage['Active Accounts'] ??
                            'Active',
                        value: '$activeCount',
                        valueColor: AppColors.mainColor,
                        bgColor: AppColors.mainColor.withValues(alpha: 0.1),
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
                  height: 48.h,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color:
                        Get.isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.fillColorColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => setState(() => selectedFilter = 'active'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  selectedFilter == 'active'
                                      ? (Get.isDarkMode
                                          ? AppColors.scaffoldColor
                                          : AppColors.whiteColor)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow:
                                  selectedFilter == 'active'
                                      ? [
                                        BoxShadow(
                                          color: AppColors.blackColor
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Text(
                              storedLanguage['Active Ledgers'] ??
                                  'Active Ledgers',
                              style: TextStyle(
                                color:
                                    selectedFilter == 'active'
                                        ? (Get.isDarkMode
                                            ? AppColors.whiteColor
                                            : AppColors.mainColor)
                                        : AppColors.black50,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedFilter = 'all'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  selectedFilter == 'all'
                                      ? (Get.isDarkMode
                                          ? AppColors.scaffoldColor
                                          : AppColors.whiteColor)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow:
                                  selectedFilter == 'all'
                                      ? [
                                        BoxShadow(
                                          color: AppColors.blackColor
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Text(
                              storedLanguage['All Contacts'] ?? 'All Contacts',
                              style: TextStyle(
                                color:
                                    selectedFilter == 'all'
                                        ? (Get.isDarkMode
                                            ? AppColors.whiteColor
                                            : AppColors.mainColor)
                                        : AppColors.black50,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
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
                      vertical: 14.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
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
                              vertical: 12.h,
                            ),
                            itemCount: displayList.length,
                            separatorBuilder: (_, __) => VSpace(16.h),
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
                                    Icons.notifications_active_outlined,
                                    color: Colors.white,
                                    size: 24.sp,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    // Swipe Left: launch WhatsApp reminder or App reminder
                                    final double bal =
                                        double.tryParse(
                                          user['outstanding_balance']
                                                  ?.toString() ??
                                              '0',
                                        ) ??
                                        0.0;
                                    if (bal > 0) {
                                      _showReminderOptions(
                                        context,
                                        user['id'].toString(),
                                        user['name'].toString(),
                                        bal,
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 20.h,
              bottom: 20.h + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.black30,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                VSpace(20.h),
                Text(
                  storedLanguage['Upgrade Credit Limit'] ?? 'Upgrade Credit Limit',
                  style: context.t.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                  ),
                ),
                VSpace(4.h),
                Text(
                  customerName,
                  style: context.t.bodyMedium?.copyWith(
                    color: AppColors.black50,
                  ),
                ),
                VSpace(20.h),
                CustomTextField(
                  hintext: storedLanguage['Credit Limit'] ?? 'Credit Limit (₹)',
                  controller: controller.editLimitCtrl,
                  keyboardType: TextInputType.number,
                ),
                VSpace(24.h),
                GetBuilder<UdharController>(
                  builder: (ctrl) => AppButton(
                    text: storedLanguage['Update'] ?? 'Update',
                    isLoading: ctrl.isUpdatingLimit,
                    onTap: () async {
                      await ctrl.updateCustomerCreditLimit(
                        customerId: customerId,
                        creditLimit: ctrl.editLimitCtrl.text,
                      );
                      if (context.mounted) {
                        Get.back();
                      }
                    },
                  ),
                ),
                VSpace(10.h),
              ],
            ),
          ),
        );
      },
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

  void _showReminderOptions(
    BuildContext context,
    String customerId,
    String customerName,
    double balance,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: 20 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Send Reminder",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainColor,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.notifications, color: Colors.blue),
                title: Text("In-App Notification"),
                subtitle: Text("Send a push notification to their UdharCard app"),
                onTap: () {
                  Navigator.pop(context);
                  Get.find<UdharController>().sendPaymentReminder(customerId);
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.chat_bubble, color: Colors.green),
                title: Text("WhatsApp"),
                subtitle: Text("Send a personalized WhatsApp message"),
                onTap: () {
                  Navigator.pop(context);
                  Helpers.checkAndForcePhoneVerification(
                    context,
                    onVerified: () async {
                      final String message =
                          "Dear $customerName, this is a friendly reminder that you have an outstanding payment of ₹${balance.toStringAsFixed(2)} due with our shop. Please pay as soon as possible. Thank you!";
                      final String encodedMsg = Uri.encodeComponent(message);
                      await launchUrl(
                        Uri.parse("https://wa.me/?text=$encodedMsg"),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
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
    required this.bgColor,
  });

  final String title;
  final String value;
  final Color valueColor;
  final Color bgColor;

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
          boxShadow: [
            BoxShadow(
              color: AppColors.blackColor.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26.r,
                  backgroundColor: AppColors.mainColor.withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: TextStyle(
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
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
                  HSpace(12.w),
                  Text(
                    'Limit: ₹${creditLimit.toInt()}',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.black50, fontWeight: FontWeight.w500),
                  ),
                  HSpace(6.w),
                  GestureDetector(
                    onTap: onEditLimit,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 14.sp,
                        color: AppColors.mainColor,
                      ),
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
                    style: TextStyle(fontSize: 11.sp, color: AppColors.black50, fontWeight: FontWeight.w500),
                  ),
                  HSpace(6.w),
                  GestureDetector(
                    onTap: onEditLimit,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 14.sp,
                        color: AppColors.mainColor,
                      ),
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
