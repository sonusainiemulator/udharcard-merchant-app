import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/controllers/bindings/controller_index.dart';
import 'package:paysecure/routes/routes_name.dart';
import 'package:paysecure/views/screens/merchant-settings/merchant_settings_screen.dart';
import 'package:paysecure/views/widgets/mediaquery_extension.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../themes/themes.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';
import '../udhar/select_user_sheet.dart';
import '../udhar/customer_ledger_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<UdharController>().fetchUsers();
    });
  }

  var scaffoldKey = GlobalKey<ScaffoldState>();
  bool isCollapsed1 = false;
  bool isCollapsed2 = false;
  bool isCollapsed3 = false;

  final int hour = DateTime.now().hour;
  String greetingMessage() {
    if (hour >= 5 && hour < 12) {
      return "Good Morning,";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon,";
    } else {
      return "Good Evening,";
    }
  }

  @override
  Widget build(BuildContext context) {
    Get.put(TransactionController());
    TextTheme t = Theme.of(context).textTheme;
    final String fullName =
        (HiveHelp.read(Keys.userFullName) ?? '').toString().trim();
    final String userName =
        (HiveHelp.read(Keys.userName) ?? '').toString().trim();
    final String merchantDisplayName =
        fullName.isNotEmpty
            ? fullName
            : (userName.isNotEmpty ? userName : 'Merchant');
    return GetBuilder<AppController>(
      builder: (appCtrl) {
        var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
        return GetBuilder<AuthController>(
          builder: (authController) {
            return GetBuilder<TransactionController>(
              builder: (transactionCtrl) {
                return GetBuilder<ProfileController>(
                  builder: (profileCtrl) {
                    return Scaffold(
                      backgroundColor:
                          Get.isDarkMode
                              ? AppColors.darkBgColor
                              : AppColors.scaffoldColor,
                      key: scaffoldKey,
                      appBar: CustomAppBar(
                        toolberHeight: 60.h,
                        prefferSized: 60.h,
                        bgColor:
                            Get.isDarkMode
                                ? AppColors.darkBgColor
                                : AppColors.fillColorColor,
                        isTitleMarginTop: false,
                        title: storedLanguage['Udhar Card'] ?? 'Udhar Card',
                        leading: Padding(
                          padding: EdgeInsets.only(left: 7.w),
                          child: IconButton(
                            onPressed: () {
                              scaffoldKey.currentState?.openDrawer();
                            },
                            icon: Container(
                              width: 34.h,
                              height: 34.h,
                              padding: EdgeInsets.all(8.5.h),
                              decoration: BoxDecoration(
                                color:
                                    Get.isDarkMode
                                        ? AppColors.darkCardColor
                                        : AppColors.whiteColor,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppColors.mainColor,
                                  width: Dimensions.appThinBorder,
                                ),
                              ),
                              child: Image.asset(
                                "$rootImageDir/menu.png",
                                height: 32.h,
                                width: 32.h,
                                color: AppThemes.getIconBlackColor(),
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                          ),
                        ),
                        actions: [
                          Stack(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Get.put(
                                    PushNotificationController(),
                                  ).isNotiSeen();
                                },
                                icon: Container(
                                  height: 33.h,
                                  width: 33.h,
                                  padding: EdgeInsets.all(8.h),
                                  decoration: BoxDecoration(
                                    color:
                                        Get.isDarkMode
                                            ? AppColors.darkCardColor
                                            : AppColors.whiteColor,
                                    border: Border.all(
                                      color: AppColors.mainColor,
                                      width: .02,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.asset(
                                    "$rootImageDir/notification.png",
                                    color: AppThemes.getIconBlackColor(),
                                    fit: BoxFit.fitHeight,
                                  ),
                                ),
                              ),
                              Obx(
                                () => Positioned(
                                  top: 15.h,
                                  right: 17.w,
                                  child: InkWell(
                                    onTap: () {
                                      Get.put(
                                        PushNotificationController(),
                                      ).isNotiSeen();
                                    },
                                    child: CircleAvatar(
                                      radius:
                                          Get.put(PushNotificationController())
                                                      .isSeen
                                                      .value ==
                                                  false
                                              ? 5.r
                                              : 0,
                                      backgroundColor:
                                          Get.put(PushNotificationController())
                                                      .isSeen
                                                      .value ==
                                                  false
                                              ? AppColors.redColor
                                              : Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          HSpace(20.w),
                        ],
                      ),
                      body: RefreshIndicator(
                        color: AppColors.mainColor,
                        onRefresh: () async {
                          transactionCtrl.resetDataAfterSearching();
                          await transactionCtrl.getTransactionList(
                            page: 1,

                            created_at: "",
                            utr: "",
                          );
                          await appCtrl.getDashboard();
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: Dimensions.kDefaultPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${greetingMessage()} $merchantDisplayName',
                                          style: t.displayMedium?.copyWith(
                                            fontSize: 14.sp,
                                            color: AppColors.black50,
                                          ),
                                        ),
                                        VSpace(2.h),
                                        Text(
                                          'Welcome!',
                                          style: t.bodyMedium?.copyWith(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Soft-designed sync indicator or offline indicator
                                    GetBuilder<UdharController>(
                                      builder: (udharCtrl) {
                                        return Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                udharCtrl.isOffline
                                                    ? AppColors.redColor
                                                        .withValues(alpha: 0.1)
                                                    : AppColors.greenColor
                                                        .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                udharCtrl.isOffline
                                                    ? Icons.wifi_off
                                                    : Icons.wifi,
                                                size: 12.sp,
                                                color:
                                                    udharCtrl.isOffline
                                                        ? AppColors.redColor
                                                        : AppColors.greenColor,
                                              ),
                                              HSpace(4.w),
                                              Text(
                                                udharCtrl.isOffline
                                                    ? "Offline"
                                                    : "Online",
                                                style: TextStyle(
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      udharCtrl.isOffline
                                                          ? AppColors.redColor
                                                          : AppColors
                                                              .greenColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                VSpace(20.h),

                                // ── Premium Udhar Card Summary Panel ──
                                GetBuilder<UdharController>(
                                  builder: (udharCtrl) {
                                    double totalOutstanding = 0.0;
                                    double totalReceived = 0.0;
                                    int activeAccounts = 0;

                                    for (var u in udharCtrl.usersList) {
                                      double bal =
                                          double.tryParse(
                                            u['outstanding_balance']
                                                    ?.toString() ??
                                                '0.0',
                                          ) ??
                                          0.0;
                                      if (bal > 0) {
                                        totalOutstanding += bal;
                                        activeAccounts++;
                                      } else if (bal < 0) {
                                        totalReceived += bal.abs();
                                      }
                                    }

                                    return Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(20.r),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors:
                                              Get.isDarkMode
                                                  ? [
                                                    const Color(0xFF1E293B),
                                                    const Color(0xFF0F172A),
                                                  ]
                                                  : [
                                                    const Color(0xFFF8FAFC),
                                                    Colors.white,
                                                  ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color:
                                              Get.isDarkMode
                                                  ? Colors.white12
                                                  : Colors.black.withValues(
                                                    alpha: 0.05,
                                                  ),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha:
                                                  Get.isDarkMode ? 0.2 : 0.04,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 6.w,
                                                          height: 12.h,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                AppColors
                                                                    .redColor,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  2.r,
                                                                ),
                                                          ),
                                                        ),
                                                        HSpace(6.w),
                                                        Text(
                                                          storedLanguage['Total Udhar Gya'] ??
                                                              'Total Udhar Gya',
                                                          style: TextStyle(
                                                            color:
                                                                Get.isDarkMode
                                                                    ? Colors
                                                                        .white70
                                                                    : AppColors
                                                                        .black50,
                                                            fontSize: 12.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    VSpace(6.h),
                                                    Text(
                                                      '₹${totalOutstanding.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 22.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            AppColors.redColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 1,
                                                height: 44.h,
                                                color:
                                                    Get.isDarkMode
                                                        ? Colors.white10
                                                        : AppColors.borderColor,
                                              ),
                                              HSpace(16.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 6.w,
                                                          height: 12.h,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                AppColors
                                                                    .greenColor,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  2.r,
                                                                ),
                                                          ),
                                                        ),
                                                        HSpace(6.w),
                                                        Text(
                                                          storedLanguage['Total Udhar Aaya'] ??
                                                              'Total Udhar Aaya',
                                                          style: TextStyle(
                                                            color:
                                                                Get.isDarkMode
                                                                    ? Colors
                                                                        .white70
                                                                    : AppColors
                                                                        .black50,
                                                            fontSize: 12.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    VSpace(6.h),
                                                    Text(
                                                      '₹${totalReceived.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 22.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            AppColors
                                                                .greenColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          VSpace(16.h),
                                          Divider(
                                            height: 1,
                                            color:
                                                Get.isDarkMode
                                                    ? Colors.white10
                                                    : AppColors.borderColor,
                                          ),
                                          VSpace(12.h),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                  vertical: 4.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.mainColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.r,
                                                      ),
                                                ),
                                                child: Text(
                                                  '${storedLanguage['Active Customers'] ?? 'Active Customers'}: $activeAccounts',
                                                  style: TextStyle(
                                                    fontSize: 11.sp,
                                                    color: AppColors.mainColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap:
                                                    () => Get.toNamed(
                                                      '/customerListScreen',
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 4.w,
                                                    vertical: 2.h,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        storedLanguage['View Reports'] ??
                                                            'View Reports',
                                                        style: TextStyle(
                                                          fontSize: 11.sp,
                                                          color:
                                                              AppColors
                                                                  .mainColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons
                                                            .chevron_right_rounded,
                                                        size: 14.sp,
                                                        color:
                                                            AppColors.mainColor,
                                                      ),
                                                    ],
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

                                VSpace(20.h),

                                // ── Quick LEN DEN Action Buttons ──
                                GetBuilder<UdharController>(
                                  builder: (udharCtrl) {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () async {
                                              final picked =
                                                  await SelectUserSheet.show(
                                                    context,
                                                  );
                                              if (picked != null) {
                                                udharCtrl.selectUser(picked);
                                                udharCtrl.setType('given');
                                                Get.toNamed('/addUdharScreen');
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 16.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.redColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(16.r),
                                                border: Border.all(
                                                  color: AppColors.redColor
                                                      .withValues(alpha: 0.25),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .remove_circle_outline_rounded,
                                                    size: 20.sp,
                                                    color: AppColors.redColor,
                                                  ),
                                                  HSpace(8.w),
                                                  Text(
                                                    storedLanguage['YOU GAVE'] ??
                                                        'YOU GAVE (₹)',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.redColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        HSpace(16.w),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () async {
                                              final picked =
                                                  await SelectUserSheet.show(
                                                    context,
                                                  );
                                              if (picked != null) {
                                                udharCtrl.selectUser(picked);
                                                udharCtrl.setType('received');
                                                Get.toNamed('/addUdharScreen');
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 16.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.greenColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(16.r),
                                                border: Border.all(
                                                  color: AppColors.greenColor
                                                      .withValues(alpha: 0.25),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .add_circle_outline_rounded,
                                                    size: 20.sp,
                                                    color: AppColors.greenColor,
                                                  ),
                                                  HSpace(8.w),
                                                  Text(
                                                    storedLanguage['YOU GOT'] ??
                                                        'YOU GOT (₹)',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppColors.greenColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                VSpace(20.h),

                                // ── NFC Tap & Pay (Coming Soon) ──
                                InkWell(
                                  onTap: () {
                                    Get.snackbar(
                                      'Coming Soon',
                                      'NFC Payments are coming soon! We are working hard to bring this feature to you.',
                                      backgroundColor: AppColors.mainColor,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                      margin: EdgeInsets.all(16.r),
                                      borderRadius: 12.r,
                                      icon: const Icon(Icons.nfc_rounded, color: Colors.white),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 16.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.mainColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: AppColors.mainColor.withValues(alpha: 0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.nfc_rounded,
                                          size: 24.sp,
                                          color: AppColors.mainColor,
                                        ),
                                        HSpace(12.w),
                                        Text(
                                          storedLanguage['NFC Tap & Pay'] ?? 'NFC Tap & Pay',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.mainColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                VSpace(28.h),

                                // ── Everyday Directory Search Bar ──
                                GetBuilder<UdharController>(
                                  builder: (udharCtrl) {
                                    return TextField(
                                      controller: udharCtrl.searchCtrl,
                                      onChanged: udharCtrl.searchUsers,
                                      decoration: InputDecoration(
                                        hintText:
                                            storedLanguage['Search name or phone...'] ??
                                            'Search name or phone...',
                                        hintStyle: context.t.bodySmall
                                            ?.copyWith(
                                              color:
                                                  AppColors.textFieldHintColor,
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
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                VSpace(20.h),

                                // ── Active Customer Directory List ──
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      storedLanguage['Customer Directory'] ??
                                          'Customer Directory',
                                      style: t.bodyLarge?.copyWith(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    InkWell(
                                      onTap:
                                          () => Get.toNamed(
                                            '/customerListScreen',
                                          ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 4.h,
                                          horizontal: 8.w,
                                        ),
                                        child: Text(
                                          storedLanguage['See All'] ??
                                              'See All',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.mainColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                VSpace(12.h),

                                GetBuilder<UdharController>(
                                  builder: (udharCtrl) {
                                    final displayList = udharCtrl.filteredUsers;
                                    if (displayList.isEmpty) {
                                      return Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 32.h,
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.people_outline,
                                                size: 48.sp,
                                                color: AppColors.black30,
                                              ),
                                              VSpace(8.h),
                                              Text(
                                                storedLanguage['No customers found'] ??
                                                    'No customers found',
                                                style: TextStyle(
                                                  color: AppColors.black50,
                                                  fontSize: 13.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    return ListView.separated(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount:
                                          displayList.length > 5
                                              ? 5
                                              : displayList.length,
                                      separatorBuilder: (_, __) => VSpace(10.h),
                                      itemBuilder: (context, index) {
                                        final Map<String, dynamic> user =
                                            Map<String, dynamic>.from(
                                              displayList[index],
                                            );
                                        final String name =
                                            (user['name'] ?? '').toString();
                                        final String phone =
                                            (user['phone'] ?? '').toString();
                                        final double balance =
                                            double.tryParse(
                                              user['outstanding_balance']
                                                      ?.toString() ??
                                                  '0',
                                            ) ??
                                            0.0;
                                        final Color balColor =
                                            balance > 0
                                                ? AppColors.redColor
                                                : (balance < 0
                                                    ? AppColors.greenColor
                                                    : AppColors.black50);
                                        final String balLabel =
                                            balance > 0
                                                ? 'Due: ₹${balance.toStringAsFixed(2)}'
                                                : (balance < 0
                                                    ? 'Advance: ₹${balance.abs().toStringAsFixed(2)}'
                                                    : 'Settled');

                                        return Dismissible(
                                          key: Key('home_${user['id']}'),
                                          background: Container(
                                            color: Colors.green,
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.only(
                                              left: 20.w,
                                            ),
                                            child: Icon(
                                              Icons.add_circle_outline,
                                              color: Colors.white,
                                              size: 22.sp,
                                            ),
                                          ),
                                          secondaryBackground: Container(
                                            color: Colors.green.shade600,
                                            alignment: Alignment.centerRight,
                                            padding: EdgeInsets.only(
                                              right: 20.w,
                                            ),
                                            child: Icon(
                                              Icons.chat_bubble_outline,
                                              color: Colors.white,
                                              size: 22.sp,
                                            ),
                                          ),
                                          confirmDismiss: (direction) async {
                                            if (direction ==
                                                DismissDirection.endToStart) {
                                              // Swipe Left: WhatsApp Reminder
                                              if (balance > 0) {
                                                Helpers.checkAndForcePhoneVerification(
                                                  context,
                                                  onVerified: () async {
                                                    final String message =
                                                        "Dear $name, this is a friendly reminder that you have an outstanding payment of ₹${balance.toStringAsFixed(2)} due with our shop. Please pay as soon as possible. Thank you!";
                                                    final String encodedMsg =
                                                        Uri.encodeComponent(
                                                          message,
                                                        );
                                                    await launchUrl(
                                                      Uri.parse(
                                                        "https://wa.me/?text=$encodedMsg",
                                                      ),
                                                      mode:
                                                          LaunchMode
                                                              .externalApplication,
                                                    );
                                                  },
                                                );
                                              } else {
                                                Get.snackbar(
                                                  'Settled',
                                                  'No outstanding balance to collect.',
                                                );
                                              }
                                              return false;
                                            } else {
                                              // Swipe Right: Quick entry
                                              udharCtrl.selectUser(user);
                                              Get.toNamed('/addUdharScreen');
                                              return false;
                                            }
                                          },
                                          child: InkWell(
                                            onTap: () {
                                              Get.to(
                                                () => CustomerLedgerScreen(
                                                  customerId:
                                                      user['id'].toString(),
                                                  customerName: name,
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.all(12.r),
                                              decoration: BoxDecoration(
                                                color:
                                                    Get.isDarkMode
                                                        ? AppColors
                                                            .darkCardColor
                                                        : AppColors.whiteColor,
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                border: Border.all(
                                                  color: AppColors.borderColor,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 18.r,
                                                    backgroundColor: AppColors
                                                        .mainColor
                                                        .withValues(alpha: 0.1),
                                                    child: Text(
                                                      name.isNotEmpty
                                                          ? name[0]
                                                              .toUpperCase()
                                                          : 'U',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.mainColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14.sp,
                                                      ),
                                                    ),
                                                  ),
                                                  HSpace(12.w),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          name,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13.sp,
                                                          ),
                                                        ),
                                                        VSpace(2.h),
                                                        Text(
                                                          phone,
                                                          style: TextStyle(
                                                            color:
                                                                AppColors
                                                                    .black50,
                                                            fontSize: 11.sp,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    balLabel,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.sp,
                                                      color: balColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                      ),
                      drawer: buildDrawer(context, storedLanguage),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildContainer(
    TextTheme t, [
    Color? bgColor,
    String? img,
    String? currency,
    String? amout,
  ]) {
    return Container(
      padding: EdgeInsets.only(
        top: 20.h,
        left: 16.h,
        bottom: 16.h,
        right: 16.h,
      ),
      height: 134.h,
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.dollerColor.withValues(alpha: .1),
        borderRadius: Dimensions.kBorderRadius * 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            img ?? "$rootImageDir/doller.png",
            height: 36.h,
            width: 36.h,
            fit: BoxFit.cover,
          ),
          VSpace(5.h),
          Text(
            currency ?? "Us Dollar",
            style: t.bodySmall?.copyWith(
              fontSize: 14.sp,
              color: AppThemes.getIconBlackColor(),
            ),
          ),
          Text(
            amout ?? "\$7468.28",
            maxLines: 2,
            style: t.bodyMedium?.copyWith(fontSize: 16.sp),
          ),
        ],
      ),
    );
  }

  Widget buildAccountsLoader() {
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, i) {
          return Container(
            height: 200.h,
            width: 250.w,
            margin: EdgeInsets.only(right: 20.h),
            decoration: BoxDecoration(
              color:
                  Get.isDarkMode
                      ? AppColors.darkCardColor
                      : AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VSpace(10.h),
                Row(
                  children: [
                    Container(
                      width: 32.h,
                      height: 32.h,
                      margin: EdgeInsets.only(left: 8.w),
                      padding: EdgeInsets.all(10.h),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            Get.isDarkMode
                                ? AppColors.darkBgColor
                                : AppColors.fillColorColor,
                      ),
                    ),
                    Spacer(),
                    Container(
                      width: 5.w,
                      height: 25.h,
                      margin: EdgeInsets.only(right: 20.w),
                      padding: EdgeInsets.all(10.h),
                      decoration: BoxDecoration(
                        color:
                            Get.isDarkMode
                                ? AppColors.darkBgColor
                                : AppColors.fillColorColor,
                      ),
                    ),
                  ],
                ),
                VSpace(25.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80.w,
                      height: 15.h,
                      margin: EdgeInsets.only(left: 8.w),
                      padding: EdgeInsets.all(10.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color:
                            Get.isDarkMode
                                ? AppColors.darkBgColor
                                : AppColors.fillColorColor,
                      ),
                    ),
                    VSpace(6.w),
                    Container(
                      width: 150.w,
                      height: 25.h,
                      margin: EdgeInsets.only(left: 8.w),
                      padding: EdgeInsets.all(10.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color:
                            Get.isDarkMode
                                ? AppColors.darkBgColor
                                : AppColors.fillColorColor,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80.w,
                      height: 15.h,
                      margin: EdgeInsets.only(left: 8.w),
                      padding: EdgeInsets.all(10.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color:
                            Get.isDarkMode
                                ? AppColors.darkBgColor
                                : AppColors.fillColorColor,
                      ),
                    ),
                    VSpace(6.w),
                    Container(
                      width: 170.w,
                      height: 25.h,
                      margin: EdgeInsets.only(left: 8.w),
                      padding: EdgeInsets.all(10.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color:
                            Get.isDarkMode
                                ? AppColors.darkBgColor
                                : AppColors.fillColorColor,
                      ),
                    ),
                  ],
                ),
                VSpace(15.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildDrawer(BuildContext context, storedLanguage) {
    Color lightenColor(Color color, [double amount = 0.1]) {
      assert(amount >= 0 && amount <= 1, 'Amount should be between 0 and 1');
      final hsl = HSLColor.fromColor(color);
      final hslLightened = hsl.withLightness(
        (hsl.lightness + amount).clamp(0.0, 1.0),
      );
      return hslLightened.toColor();
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.only(right: 60.w),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Image.asset(
                "$rootImageDir/drawer_bg_right.png",
                color: AppColors.mainColor,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Image.asset(
                "$rootImageDir/drawer_bg_left.png",
                color: lightenColor(AppColors.mainColor, 0.05),
                width: context.mQuery.width * .6,
                fit: BoxFit.cover,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GetBuilder<ProfileController>(
                  builder: (profileController) {
                    return SizedBox(
                      height: 240.h,
                      child: Column(
                        children: [
                          VSpace(90.h),
                          SizedBox(
                            height: 110.h,
                            width: context.mQuery.width * .58,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  right: -60.w,
                                  child: Container(
                                    height: 120.h,
                                    width: 120.h,
                                    padding: EdgeInsets.all(20.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.mainColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Container(
                                      height: 80.h,
                                      width: 80.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.imageBgColor,
                                        image:
                                            profileController.isLoading ||
                                                    profileController
                                                            .userPhoto ==
                                                        ''
                                                ? DecorationImage(
                                                  image: AssetImage(
                                                    "$rootImageDir/avatar.webp",
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                                : DecorationImage(
                                                  image:
                                                      CachedNetworkImageProvider(
                                                        profileController
                                                            .userPhoto,
                                                      ),
                                                  fit: BoxFit.cover,
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 24.w),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        VSpace(30.h),
                                        Text(
                                          profileController.isLoading
                                              ? ""
                                              : profileController.userName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.t.bodyLarge?.copyWith(
                                            fontSize: 20.sp,
                                            color: AppColors.whiteColor,
                                          ),
                                        ),
                                        VSpace(5.h),
                                        Text(
                                          profileController.isLoading
                                              ? ""
                                              : profileController.userEmail,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.t.displayMedium
                                              ?.copyWith(
                                                fontSize: 16.sp,
                                                color: AppColors.whiteColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        /* buildTile(
                          context,
                          onTap: () {
                            Get.toNamed(RoutesName.withdrawScreen);
                          },
                          img: "$rootImageDir/payout.png",
                          name: storedLanguage['Withdraw'] ?? 'Withdraw',
                        ),
                        buildTile(
                          context,
                          onTap: () {
                            Get.toNamed(RoutesName.withdrawHistoryScreen);
                          },
                          img: "$rootImageDir/payout.png",
                          name:
                              storedLanguage['Withdraw History'] ??
                              'Withdraw History',
                        ), */
                        buildTile(
                          context,
                          onTap: () {
                            Get.toNamed(RoutesName.transferMoneyScreen);
                          },
                          img: "$rootImageDir/send_money.png",
                          name: storedLanguage['Send Money'] ?? 'Send Money',
                        ),
                        buildTile(
                          context,
                          onTap: () {
                            Get.toNamed(RoutesName.transactionScreen);
                          },
                          img: "$rootImageDir/transaction.png",
                          name:
                              storedLanguage['Transactions'] ?? 'Transactions',
                        ),

                        buildTile(
                          context,
                          onTap: () {
                            Get.toNamed(RoutesName.qrCodeScreen);
                          },
                          img: "$rootImageDir/qr_payment.png",
                          name: storedLanguage['QR Code'] ?? 'QR Code',
                        ),
                        buildTileWithIcon(
                          context,
                          onTap: () {
                            Get.toNamed(RoutesName.voiceEntryScreen);
                          },
                          icon: Icons.mic,
                          name: storedLanguage['Voice Entry'] ?? 'Voice Entry',
                        ),
                        buildTileWithIcon(
                          context,
                          onTap: () {
                            Get.toNamed(RoutesName.addUdharScreen);
                          },
                          icon: Icons.account_balance_wallet_outlined,
                          name: storedLanguage['Add Udhar'] ?? 'Add Udhar',
                        ),
                        buildTileWithIcon(
                          context,
                          onTap: () {
                            Get.toNamed(RoutesName.udharDashboardScreen);
                          },
                          icon: Icons.dashboard_customize_outlined,
                          name:
                              storedLanguage['Udhar Dashboard'] ??
                              'Udhar Dashboard',
                        ),
                        buildTileWithIcon(
                          context,
                          onTap: () {
                            Get.toNamed(RoutesName.customerListScreen);
                          },
                          icon: Icons.people_outline,
                          name:
                              storedLanguage['Customer Ledger'] ??
                              'Customer Ledger',
                        ),
                        buildTile(
                          context,
                          onTap: () {
                            Get.to(
                              () => MerchantSettingScreen(
                                isFromDrawerSection: true,
                              ),
                            );
                          },
                          img: "$rootImageDir/settings.png",
                          name:
                              storedLanguage['Merchant Settings'] ??
                              'Merchant Settings',
                        ),
                        buildTile(
                          context,
                          onTap: () {
                            Get.toNamed(RoutesName.securityPinSetupScreen);
                          },
                          img: "$rootImageDir/pin.png",
                          name: storedLanguage['Reset Pin'] ?? 'Reset Pin',
                        ),
                        buildTile(
                          context,
                          onTap: () {
                            Get.toNamed(RoutesName.supportTicketListScreen);
                          },
                          img: "$rootImageDir/support.png",
                          name:
                              storedLanguage['Support Ticket'] ??
                              'Support Ticket',
                        ),

                        VSpace(60.h),
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
  }

  ExpansionTile expansionTileWidget(
    BuildContext context, {
    required String img,
    required String categoryName,
    required List<String> subCategoryList,
    required Function(String) onTap,
    void Function(bool)? onExpansionChanged,
    required bool isCollapsed,
  }) {
    return ExpansionTile(
      shape: const RoundedRectangleBorder(),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.all(0),
      iconColor: AppThemes.getIconBlackColor(),
      title: Row(
        children: [
          HSpace(18.w),
          SizedBox(
            width: 18.w,
            height: 18.w,
            child: Image.asset(
              img,
              color: AppColors.whiteColor,
              fit: BoxFit.cover,
            ),
          ),
          HSpace(27.w),
          Text(
            categoryName,
            style: context.t.bodyMedium?.copyWith(
              fontSize: 18.sp,
              color: AppColors.whiteColor,
            ),
          ),
        ],
      ),
      trailing:
          isCollapsed
              ? Padding(
                padding: EdgeInsets.only(right: 15.w),
                child: const Icon(
                  Icons.arrow_drop_up,
                  color: AppColors.whiteColor,
                ),
              )
              : Padding(
                padding: EdgeInsets.only(right: 15.w),
                child: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.whiteColor,
                ),
              ),
      onExpansionChanged: onExpansionChanged,
      children:
          subCategoryList
              .map(
                (e) => SizedBox(
                  height: 40,
                  child: ListTile(
                    onTap: () => onTap(e),
                    contentPadding: EdgeInsets.only(left: 65.w),
                    title: Text(
                      e,
                      style: context.t.bodySmall?.copyWith(
                        fontSize: 16.sp,
                        color: AppColors.whiteColor,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  ListTile buildTile(
    BuildContext context, {
    required String name,
    required String img,
    void Function()? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 18.w,
        height: 18.w,
        child: Image.asset(img, color: AppColors.whiteColor, fit: BoxFit.cover),
      ),
      title: Text(
        name,
        style: context.t.bodyMedium?.copyWith(
          fontSize: 18.sp,
          color: AppColors.whiteColor,
        ),
      ),
    );
  }

  ListTile buildTileWithIcon(
    BuildContext context, {
    required String name,
    required IconData icon,
    void Function()? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 18.w,
        height: 18.w,
        child: Icon(icon, color: AppColors.whiteColor, size: 20.sp),
      ),
      title: Text(
        name,
        style: context.t.bodyMedium?.copyWith(
          fontSize: 18.sp,
          color: AppColors.whiteColor,
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
          color:
              isReverseColor == true
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
                color:
                    Get.isDarkMode
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
                      color:
                          Get.isDarkMode
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
                      color:
                          Get.isDarkMode
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
