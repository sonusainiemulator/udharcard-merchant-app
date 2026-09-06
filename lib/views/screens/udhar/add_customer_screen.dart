import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../config/app_colors.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../themes/themes.dart';
import '../../widgets/spacing.dart';
import '../../widgets/text_theme_extension.dart';

Future<Map<String, dynamic>?> openAddCustomerScreen({
  required Map storedLanguage,
  String? initialName,
  String? initialPhone,
}) async {
  if (!Get.isRegistered<UdharController>()) {
    Get.put(UdharController());
  }
  final ctrl = Get.find<UdharController>();
  ctrl.showCustomerLimitNudgeIfNeeded();

  final args = {
    'storedLanguage': storedLanguage,
    'initialName': initialName,
    'initialPhone': initialPhone,
  };

  try {
    final result = await Get.toNamed<Map<String, dynamic>?>(
      RoutesName.addCustomerScreen,
      arguments: args,
    );
    if (result != null) return result;
  } catch (_) {
    final result = await Get.to<Map<String, dynamic>?>(
      () => const AddCustomerScreen(),
      arguments: args,
    );
    if (result != null) return result;
  }
  return null;
}

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  static const Color _accentColor = Color(0xFFD3262A);
  static const Color _fieldBorder = Color(0xFFE4E7EC);

  late final UdharController _controller;
  late final Map _storedLanguage;

  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  bool _showMoreInfo = false;
  String _selectedType = 'Customer';

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.find<UdharController>();

    final args = Map<String, dynamic>.from(Get.arguments ?? const {});
    _storedLanguage = args['storedLanguage'] is Map
        ? Map.from(args['storedLanguage'])
        : {};

    _controller.openingBalanceCtrl.clear();
    _controller.limitCtrl.clear();
    _controller.emailCtrl.clear();
    _controller.nameCtrl.text = (args['initialName'] ?? '').toString();
    _controller.phoneCtrl.text = (args['initialPhone'] ?? '').toString();
    _controller.nameCtrl.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _controller.nameCtrl.removeListener(_onNameChanged);
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBgColor : const Color(0xFFF9FAFB);
    final cardColor = isDark ? AppColors.darkCardColor : Colors.white;
    final borderColor = isDark
        ? AppThemes.getSliderInactiveColor()
        : _fieldBorder;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          surfaceTintColor: cardColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Get.back();
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.blackColor,
              size: 19.sp,
            ),
          ),
          centerTitle: true,
          title: Text(
            _storedLanguage['Add Parties'] ?? 'Add Parties',
            style: context.t.bodyLarge?.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.blackColor,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: borderColor.withValues(alpha: 0.6),
              height: 1,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Profile Header with Realtime Avatar & One-Tap Contact Import
                _buildTopProfileCard(
                  context: context,
                  isDark: isDark,
                  cardColor: cardColor,
                  borderColor: borderColor,
                ),
                VSpace(16.h),

                // Primary Form Card
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.15 : 0.03,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phone Number with Indian Flag & +91
                      _buildPhoneField(
                        context: context,
                        isDark: isDark,
                        fillColor: isDark
                            ? AppColors.darkBgColor
                            : const Color(0xFFFAFAFB),
                        borderColor: borderColor,
                      ),
                      VSpace(16.h),

                      // Customer Name Field
                      _buildCustomerNameField(
                        context: context,
                        isDark: isDark,
                        fillColor: isDark
                            ? AppColors.darkBgColor
                            : const Color(0xFFFAFAFB),
                        borderColor: borderColor,
                      ),
                      VSpace(18.h),

                      // Modern Segmented Party Category Chips
                      _buildPartyTypeSelector(
                        context: context,
                        isDark: isDark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                      ),
                    ],
                  ),
                ),
                VSpace(16.h),

                // Collapsible Additional Details Section
                _buildCollapsibleAdditionalDetails(
                  context: context,
                  isDark: isDark,
                  cardColor: cardColor,
                  borderColor: borderColor,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(
            16.w,
            8.h,
            16.w,
            MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                12.h,
          ),
          child: GetBuilder<UdharController>(
            builder: (ctrl) => SizedBox(
              height: 52.h,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  disabledBackgroundColor:
                      _accentColor.withValues(alpha: 0.55),
                  elevation: 2,
                  shadowColor: _accentColor.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: ctrl.isAddingCustomer
                    ? null
                    : () async {
                        FocusScope.of(context).unfocus();
                        await ctrl.addCustomer(
                          address: _addressCtrl.text,
                          note: _noteCtrl.text,
                          type: _selectedType,
                        );
                      },
                child: ctrl.isAddingCustomer
                    ? SizedBox(
                        height: 22.h,
                        width: 22.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                          HSpace(8.w),
                          Text(
                            _storedLanguage['Add Customer'] ?? 'Add Customer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Authentic Indian Flag widget (Saffron, White with Ashoka Chakra dot, Green)
  Widget _buildIndianFlag() {
    return Container(
      width: 21.w,
      height: 14.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.5.r),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.15),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Saffron
          Expanded(
            child: Container(color: const Color(0xFFFF9933)),
          ),
          // White with Navy Blue Ashoka Chakra
          Expanded(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Container(
                  width: 4.2.w,
                  height: 4.2.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF000080),
                      width: 0.7,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 1.4.w,
                      height: 1.4.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF000080),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // India Green
          Expanded(
            child: Container(color: const Color(0xFF138808)),
          ),
        ],
      ),
    );
  }

  /// Top Profile Card showing avatar initials and fast contact import button
  Widget _buildTopProfileCard({
    required BuildContext context,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
  }) {
    final name = _controller.nameCtrl.text.trim();
    String initials = '';
    if (name.isNotEmpty) {
      final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0]
            .substring(0, parts[0].length >= 2 ? 2 : 1)
            .toUpperCase();
      }
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dynamic Avatar
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentColor.withValues(alpha: 0.12),
                  _accentColor.withValues(alpha: 0.24),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: initials.isNotEmpty
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: _accentColor,
                        letterSpacing: 0.5,
                      ),
                    )
                  : Icon(
                      Icons.person_rounded,
                      color: _accentColor,
                      size: 28.sp,
                    ),
            ),
          ),
          HSpace(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'New Party Profile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.t.bodyMedium?.copyWith(
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.blackColor,
                  ),
                ),
                VSpace(2.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 7.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    _selectedType,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          HSpace(8.w),
          // Quick Import From Contacts Button
          InkWell(
            onTap: () async {
              final contact = await _controller.pickContactFromPhonebook();
              if (contact != null && mounted) setState(() {});
            },
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: _accentColor.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.contacts_rounded,
                    color: _accentColor,
                    size: 16.sp,
                  ),
                  HSpace(5.w),
                  Text(
                    'Contacts',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Phone number input with Indian flag, +91 prefix, and contact picker
  Widget _buildPhoneField({
    required BuildContext context,
    required bool isDark,
    required Color fillColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context: context, label: 'Phone Number *'),
        VSpace(6.h),
        Container(
          height: 52.h,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // Country Code & Flag Pill
              Container(
                margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBgColor
                      : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIndianFlag(),
                    HSpace(6.w),
                    Text(
                      '+91',
                      style: context.t.bodyMedium?.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.blackColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 22.h,
                width: 1,
                color: borderColor,
              ),
              HSpace(10.w),
              Expanded(
                child: TextField(
                  controller: _controller.phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: context.t.bodyMedium?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter 10-digit mobile number',
                    hintStyle: context.t.bodySmall?.copyWith(
                      color: AppColors.textFieldHintColor,
                      fontSize: 13.sp,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              // Contact Book Action Button
              IconButton(
                splashRadius: 20.r,
                onPressed: () async {
                  final contact = await _controller.pickContactFromPhonebook();
                  if (contact != null && mounted) {
                    setState(() {});
                  }
                },
                icon: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.perm_contact_calendar_rounded,
                    color: _accentColor,
                    size: 18.sp,
                  ),
                ),
                tooltip: 'Import from Contacts',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Customer Name input with clean prefix icon and title capitalization
  Widget _buildCustomerNameField({
    required BuildContext context,
    required bool isDark,
    required Color fillColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context: context, label: 'Customer / Party Name *'),
        VSpace(6.h),
        Container(
          height: 52.h,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 12.w, right: 10.w),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 20.sp,
                  color: isDark ? Colors.white60 : AppColors.black50,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller.nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: context.t.bodyMedium?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: _storedLanguage['Name'] ?? 'Enter customer name',
                    hintStyle: context.t.bodySmall?.copyWith(
                      color: AppColors.textFieldHintColor,
                      fontSize: 13.sp,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Modern Segmented Category Chips for Party Type (2x2 Grid)
  Widget _buildPartyTypeSelector({
    required BuildContext context,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
  }) {
    final row1 = [
      {'label': 'Customer', 'icon': Icons.person_rounded},
      {'label': 'Dealer', 'icon': Icons.storefront_rounded},
    ];
    final row2 = [
      {'label': 'Wholesaler', 'icon': Icons.inventory_2_rounded},
      {'label': 'Supplier', 'icon': Icons.local_shipping_rounded},
    ];

    Widget buildChip(Map<String, dynamic> item) {
      final label = item['label'] as String;
      final icon = item['icon'] as IconData;
      final isSelected = _selectedType == label;

      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedType = label);
            },
            borderRadius: BorderRadius.circular(10.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? _accentColor
                    : (isDark ? cardColor : const Color(0xFFF7F8FA)),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isSelected ? _accentColor : borderColor,
                  width: isSelected ? 1.4 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.22),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 17.sp,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : AppColors.black60),
                  ),
                  HSpace(7.w),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : AppColors.black70),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14.sp,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context: context, label: 'Party Category *'),
        VSpace(8.h),
        Row(
          children: [
            buildChip(row1[0]),
            HSpace(10.w),
            buildChip(row1[1]),
          ],
        ),
        VSpace(8.h),
        Row(
          children: [
            buildChip(row2[0]),
            HSpace(10.w),
            buildChip(row2[1]),
          ],
        ),
      ],
    );
  }

  /// Collapsible Card containing Optional Additional Details
  Widget _buildCollapsibleAdditionalDetails({
    required BuildContext context,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Accordion Header
          InkWell(
            onTap: () {
              setState(() => _showMoreInfo = !_showMoreInfo);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: _accentColor,
                      size: 16.sp,
                    ),
                  ),
                  HSpace(10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Additional Details',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.t.bodyMedium?.copyWith(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.blackColor,
                                ),
                              ),
                            ),
                            HSpace(6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBgColor
                                    : const Color(0xFFF0F1F3),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                'Optional',
                                style: TextStyle(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black50,
                                ),
                              ),
                            ),
                          ],
                        ),
                        VSpace(2.h),
                        Text(
                          'Opening balance, credit limit, address & notes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.black50,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showMoreInfo ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white70 : AppColors.black60,
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible Form Body
          if (_showMoreInfo) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Opening Balance & Credit Limit
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(
                              context: context,
                              label: 'Opening Balance (₹)',
                            ),
                            VSpace(6.h),
                            _buildStyledInputField(
                              context: context,
                              controller: _controller.openingBalanceCtrl,
                              hint: '0.00',
                              isDark: isDark,
                              fillColor: isDark
                                  ? AppColors.darkBgColor
                                  : const Color(0xFFF9FAFB),
                              borderColor: borderColor,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              prefixText: '₹ ',
                            ),
                          ],
                        ),
                      ),
                      HSpace(12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(
                              context: context,
                              label: 'Credit Limit (₹)',
                            ),
                            VSpace(6.h),
                            _buildStyledInputField(
                              context: context,
                              controller: _controller.limitCtrl,
                              hint: '5000',
                              isDark: isDark,
                              fillColor: isDark
                                  ? AppColors.darkBgColor
                                  : const Color(0xFFF9FAFB),
                              borderColor: borderColor,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              prefixText: '₹ ',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  VSpace(14.h),
                  // Email Address
                  _buildFieldLabel(
                    context: context,
                    label: 'Email Address (Optional)',
                  ),
                  VSpace(6.h),
                  _buildStyledInputField(
                    context: context,
                    controller: _controller.emailCtrl,
                    hint: _storedLanguage['Email'] ?? 'Enter email address',
                    isDark: isDark,
                    fillColor: isDark
                        ? AppColors.darkBgColor
                        : const Color(0xFFF9FAFB),
                    borderColor: borderColor,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.alternate_email_rounded,
                  ),
                  VSpace(14.h),
                  // Address
                  _buildFieldLabel(
                    context: context,
                    label: 'Shop / House Address (Optional)',
                  ),
                  VSpace(6.h),
                  _buildStyledInputField(
                    context: context,
                    controller: _addressCtrl,
                    hint: 'City, State, Pincode',
                    isDark: isDark,
                    fillColor: isDark
                        ? AppColors.darkBgColor
                        : const Color(0xFFF9FAFB),
                    borderColor: borderColor,
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  VSpace(14.h),
                  // Note
                  _buildFieldLabel(
                    context: context,
                    label: 'Notes & Remarks (Optional)',
                  ),
                  VSpace(6.h),
                  _buildStyledInputField(
                    context: context,
                    controller: _noteCtrl,
                    hint: 'Any special notes, terms or remarks...',
                    isDark: isDark,
                    fillColor: isDark
                        ? AppColors.darkBgColor
                        : const Color(0xFFF9FAFB),
                    borderColor: borderColor,
                    prefixIcon: Icons.edit_note_rounded,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Clean field label
  Widget _buildFieldLabel({
    required BuildContext context,
    required String label,
  }) {
    final isRequired = label.contains('*');
    final cleanLabel = label.replaceAll('*', '').trim();

    return Text.rich(
      TextSpan(
        text: cleanLabel,
        children: [
          if (isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
        ],
      ),
      style: context.t.bodySmall?.copyWith(
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w600,
        color: Get.isDarkMode ? AppColors.black20 : AppColors.black70,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Generic Styled Input Field
  Widget _buildStyledInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required Color fillColor,
    required Color borderColor,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    String? prefixText,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (prefixIcon != null)
            Padding(
              padding: EdgeInsets.only(
                left: 12.w,
                right: 8.w,
                top: maxLines > 1 ? 12.h : 0,
              ),
              child: Icon(
                prefixIcon,
                size: 18.sp,
                color: isDark ? Colors.white60 : AppColors.black50,
              ),
            ),
          if (prefixText != null)
            Padding(
              padding: EdgeInsets.only(left: 12.w, right: 4.w),
              child: Text(
                prefixText,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _accentColor,
                ),
              ),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              minLines: maxLines,
              style: context.t.bodyMedium?.copyWith(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: context.t.bodySmall?.copyWith(
                  color: AppColors.textFieldHintColor,
                  fontSize: 13.sp,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal:
                      (prefixIcon == null && prefixText == null) ? 12.w : 4.w,
                  vertical: 13.h,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}