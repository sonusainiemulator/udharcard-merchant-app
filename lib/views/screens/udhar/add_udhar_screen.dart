import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';
import '../../widgets/text_theme_extension.dart';
import 'select_user_sheet.dart';

class AddUdharScreen extends StatefulWidget {
  const AddUdharScreen({super.key});

  @override
  State<AddUdharScreen> createState() => _AddUdharScreenState();
}

class _AddUdharScreenState extends State<AddUdharScreen> {
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<UdharController>()) {
      Get.put(UdharController());
    }

    final args = Get.arguments;
    if (args is Map) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Get.find<UdharController>().applyVoiceEntryPrefill(
          name: args['name']?.toString(),
          amount:
              args['amount'] is num
                  ? (args['amount'] as num).toDouble()
                  : double.tryParse(args['amount']?.toString() ?? ''),
          type: args['type']?.toString(),
        );
      });
    }
  }

  void _onAddQuickAmount(UdharController controller, int amountToAdd) {
    HapticFeedback.selectionClick();
    final current = double.tryParse(controller.amountCtrl.text.trim()) ?? 0.0;
    final next = current + amountToAdd;
    controller.amountCtrl.text =
        next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(2);
    controller.amountCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.amountCtrl.text.length),
    );
    controller.update();
  }

  @override
  Widget build(BuildContext context) {
    final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};

    return GetBuilder<UdharController>(
      builder: (controller) {
        final bool isReceived = controller.transactionType == 'received';
        final Color themeAccent =
            isReceived ? AppColors.greenColor : AppColors.redColor;
        final bool isKeyboardOpen =
            MediaQuery.of(context).viewInsets.bottom > 0;
        final double bottomInset =
            isKeyboardOpen
                ? 10.h
                : (MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 8.h
                    : 22.h);

        return Scaffold(
          backgroundColor:
              Get.isDarkMode ? AppColors.darkBgColor : AppColors.scaffoldColor,
          appBar: CustomAppBar(
            title:
                isReceived
                    ? (storedLanguage['Payment Received'] ??
                        'Payment Received')
                    : (storedLanguage['Add Udhar'] ?? 'Add Udhar'),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Transaction type toggle ────────────────────────
                _SectionLabel(
                  text:
                      storedLanguage['Transaction Type'] ?? 'Transaction Type',
                ),
                VSpace(8.h),
                _TypeToggle(
                  selectedType: controller.transactionType,
                  onChanged: (newType) {
                    controller.setType(newType);
                  },
                  storedLanguage: storedLanguage,
                ),

                if (isReceived) ...[
                  VSpace(16.h),
                  _SectionLabel(
                    text:
                        storedLanguage['Payment Method'] ?? 'Payment Method',
                  ),
                  VSpace(8.h),
                  _PaymentMethodToggle(
                    selectedMethod: controller.paymentMethod,
                    onChanged: controller.setPaymentMethod,
                    storedLanguage: storedLanguage,
                  ),
                ],

                VSpace(16.h),

                // ── Customer selector ─────────────────────────────
                _SectionLabel(
                  text: storedLanguage['Customer'] ?? 'Customer',
                  isRequired: true,
                ),
                VSpace(8.h),
                _CustomerSelector(
                  selectedUser: controller.selectedUser,
                  isReceived: isReceived,
                  storedLanguage: storedLanguage,
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    final picked = await SelectUserSheet.show(context);
                    if (picked != null) {
                      controller.selectUser(picked);
                    }
                  },
                  onClear: controller.clearSelectedUser,
                ),

                VSpace(16.h),

                // ── Amount ────────────────────────────────────────
                _SectionLabel(
                  text: storedLanguage['Amount'] ?? 'Amount',
                  isRequired: true,
                ),
                VSpace(8.h),
                _AmountField(
                  controller: controller.amountCtrl,
                  isReceived: isReceived,
                  storedLanguage: storedLanguage,
                  onQuickAmount: (val) => _onAddQuickAmount(controller, val),
                ),

                VSpace(16.h),

                // ── Date & Time Selector ──────────────────────────
                _SectionLabel(
                  text: storedLanguage['Date & Time'] ?? 'Transaction Date',
                ),
                VSpace(8.h),
                _DateSelector(
                  selectedDate: controller.selectedDate,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    controller.pickDateAndTime(context);
                  },
                ),

                VSpace(16.h),

                // ── Remarks (optional) ────────────────────────────
                _SectionLabel(
                  text:
                      storedLanguage['Remarks (Optional)'] ??
                      'Remarks (Optional)',
                ),
                VSpace(8.h),
                _RemarksField(
                  controller: controller.remarksCtrl,
                  storedLanguage: storedLanguage,
                ),

                VSpace(16.h),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            bottom: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, bottomInset),
              decoration: BoxDecoration(
                color:
                    Get.isDarkMode
                        ? AppColors.darkCardColor
                        : AppColors.whiteColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    offset: const Offset(0, -3),
                    blurRadius: 10,
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color:
                        Get.isDarkMode
                            ? Colors.white12
                            : AppColors.borderColor.withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                ),
              ),
              child: SizedBox(
                height: 52.h,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeAccent,
                    elevation: 2,
                    shadowColor: themeAccent.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed:
                      controller.isSubmitting
                          ? null
                          : () {
                            FocusScope.of(context).unfocus();
                            controller.submitUdhar();
                          },
                  child:
                      controller.isSubmitting
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20.h,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                              HSpace(12.w),
                              Text(
                                storedLanguage['Saving...'] ?? 'Saving...',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isReceived
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                              HSpace(8.w),
                              Text(
                                isReceived
                                    ? (storedLanguage['Add Receive Transaction'] ??
                                        'Add Receive Transaction')
                                    : (storedLanguage['Add Udhar Transaction'] ??
                                        'Add Udhar Transaction'),
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, this.isRequired = false});
  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: context.t.bodyMedium?.copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Get.isDarkMode ? AppColors.whiteColor : AppColors.black80,
          ),
        ),
        if (isRequired)
          Padding(
            padding: EdgeInsets.only(left: 3.w),
            child: Text(
              '*',
              style: TextStyle(
                color: AppColors.redColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

/// Given / Received toggle pill
class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.selectedType,
    required this.onChanged,
    required this.storedLanguage,
  });

  final String selectedType;
  final void Function(String) onChanged;
  final Map storedLanguage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color:
            Get.isDarkMode ? AppColors.darkCardColor : AppColors.fillColorColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Get.isDarkMode ? Colors.white12 : AppColors.borderColor,
        ),
      ),
      child: Row(
        children: [
          _TypeOption(
            label: storedLanguage['Udhar Diya (Given)'] ?? 'Udhar Diya (Given)',
            value: 'given',
            icon: Icons.arrow_upward_rounded,
            selectedType: selectedType,
            activeColor: AppColors.redColor,
            onTap: () => onChanged('given'),
          ),
          _TypeOption(
            label:
                storedLanguage['Payment Received (Udhar Aaya)'] ??
                'Payment Received (Udhar Aaya)',
            value: 'received',
            icon: Icons.arrow_downward_rounded,
            selectedType: selectedType,
            activeColor: AppColors.greenColor,
            onTap: () => onChanged('received'),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.value,
    required this.icon,
    required this.selectedType,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final String selectedType;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedType == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15.sp,
                color:
                    isSelected
                        ? Colors.white
                        : (Get.isDarkMode
                            ? AppColors.greyColor
                            : AppColors.black60),
              ),
              HSpace(5.w),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.t.bodySmall?.copyWith(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color:
                        isSelected
                            ? Colors.white
                            : (Get.isDarkMode
                                ? AppColors.greyColor
                                : AppColors.black60),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cash / Online toggle for received payments
class _PaymentMethodToggle extends StatelessWidget {
  const _PaymentMethodToggle({
    required this.selectedMethod,
    required this.onChanged,
    required this.storedLanguage,
  });

  final String selectedMethod;
  final void Function(String) onChanged;
  final Map storedLanguage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color:
            Get.isDarkMode ? AppColors.darkCardColor : AppColors.fillColorColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Get.isDarkMode ? Colors.white12 : AppColors.borderColor,
        ),
      ),
      child: Row(
        children: [
          _PaymentMethodOption(
            label: storedLanguage['Cash'] ?? 'Cash',
            value: 'cash',
            icon: Icons.payments_outlined,
            selectedMethod: selectedMethod,
            activeColor: AppColors.greenColor,
            onTap: () => onChanged('cash'),
          ),
          _PaymentMethodOption(
            label: storedLanguage['Online'] ?? 'Online',
            value: 'online',
            icon: Icons.qr_code_2_rounded,
            selectedMethod: selectedMethod,
            activeColor: AppColors.greenColor,
            onTap: () => onChanged('online'),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  const _PaymentMethodOption({
    required this.label,
    required this.value,
    required this.icon,
    required this.selectedMethod,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final String selectedMethod;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedMethod == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.25),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16.sp,
                color:
                    isSelected
                        ? Colors.white
                        : (Get.isDarkMode
                            ? AppColors.greyColor
                            : AppColors.black60),
              ),
              HSpace(6.w),
              Text(
                label,
                style: context.t.bodySmall?.copyWith(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color:
                      isSelected
                          ? Colors.white
                          : (Get.isDarkMode
                              ? AppColors.greyColor
                              : AppColors.black60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable card that shows selected customer or a prompt to pick one.
class _CustomerSelector extends StatelessWidget {
  const _CustomerSelector({
    required this.selectedUser,
    required this.isReceived,
    required this.storedLanguage,
    required this.onTap,
    required this.onClear,
  });

  final Map<String, dynamic>? selectedUser;
  final bool isReceived;
  final Map storedLanguage;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final bool hasUser = selectedUser != null;
    final String name =
        hasUser
            ? (selectedUser!['name'] ??
                    selectedUser!['customer_name'] ??
                    'User')
                .toString()
            : '';
    final String sub =
        hasUser
            ? (selectedUser!['phone'] ??
                    selectedUser!['customer_phone'] ??
                    selectedUser!['mobile'] ??
                    selectedUser!['email'] ??
                    '')
                .toString()
            : '';
    final String initial =
        name.isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    final Color accentColor =
        isReceived ? AppColors.greenColor : AppColors.mainColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color:
              Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                hasUser
                    ? accentColor.withValues(alpha: 0.6)
                    : (Get.isDarkMode ? Colors.white12 : AppColors.borderColor),
            width: hasUser ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 42.h,
              height: 42.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    hasUser
                        ? accentColor.withValues(alpha: 0.12)
                        : (Get.isDarkMode
                            ? Colors.white10
                            : AppColors.fillColorColor),
              ),
              alignment: Alignment.center,
              child:
                  hasUser
                      ? Text(
                        initial,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      )
                      : Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppColors.textFieldHintColor,
                        size: 20.sp,
                      ),
            ),
            HSpace(12.w),

            // Name & subtitle
            Expanded(
              child:
                  hasUser
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: context.t.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (sub.isNotEmpty) ...[
                            VSpace(2.h),
                            Text(
                              sub,
                              style: context.t.bodySmall?.copyWith(
                                color: AppColors.black50,
                                fontSize: 12.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storedLanguage['Select Customer'] ??
                                'Select Customer',
                            style: context.t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textFieldHintColor,
                              fontSize: 14.sp,
                            ),
                          ),
                          VSpace(2.h),
                          Text(
                            storedLanguage['Tap to choose from contacts'] ??
                                'Tap to choose from contacts',
                            style: context.t.bodySmall?.copyWith(
                              color: AppColors.black30,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
            ),

            // Action button
            if (hasUser)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color:
                        Get.isDarkMode
                            ? Colors.white10
                            : AppColors.black10.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16.sp,
                    color: AppColors.black60,
                  ),
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      storedLanguage['Select'] ?? 'Select',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    HSpace(4.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11.sp,
                      color: accentColor,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.isReceived,
    required this.storedLanguage,
    required this.onQuickAmount,
  });

  final TextEditingController controller;
  final bool isReceived;
  final Map storedLanguage;
  final void Function(int) onQuickAmount;

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        isReceived ? AppColors.greenColor : AppColors.mainColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          autofocus: false,
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Get.isDarkMode ? AppColors.whiteColor : AppColors.blackColor,
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(
              color: AppColors.textFieldHintColor,
              fontSize: 22.sp,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Text(
                '₹',
                style: TextStyle(
                  fontSize: 22.sp,
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor:
                Get.isDarkMode
                    ? AppColors.darkCardColor
                    : AppColors.whiteColor,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color:
                    Get.isDarkMode ? Colors.white12 : AppColors.borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color:
                    Get.isDarkMode ? Colors.white12 : AppColors.borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: accentColor, width: 1.6),
            ),
          ),
        ),

        VSpace(8.h),

        // Quick amount suggestion chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _QuickChip(label: '+ ₹100', value: 100, onTap: onQuickAmount),
              _QuickChip(label: '+ ₹500', value: 500, onTap: onQuickAmount),
              _QuickChip(label: '+ ₹1,000', value: 1000, onTap: onQuickAmount),
              _QuickChip(label: '+ ₹2,000', value: 2000, onTap: onQuickAmount),
              _QuickChip(label: '+ ₹5,000', value: 5000, onTap: onQuickAmount),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final int value;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => onTap(value),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
            decoration: BoxDecoration(
              color:
                  Get.isDarkMode
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.fillColorColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color:
                    Get.isDarkMode
                        ? Colors.white12
                        : AppColors.borderColor,
                width: 0.8,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color:
                    Get.isDarkMode
                        ? Colors.white70
                        : AppColors.black70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tappable card that shows selected date or defaults to Now
class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.selectedDate, required this.onTap});

  final DateTime? selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasDate = selectedDate != null;
    final String formattedDate =
        hasDate
            ? DateFormat('dd MMM yyyy, hh:mm a').format(selectedDate!)
            : 'Today, Now';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color:
              Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                Get.isDarkMode ? Colors.white12 : AppColors.borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38.h,
              height: 38.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mainColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: AppColors.mainColor,
                size: 19.sp,
              ),
            ),
            HSpace(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: context.t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!hasDate)
                    Text(
                      'Defaulted to current time',
                      style: context.t.bodySmall?.copyWith(
                        color: AppColors.black30,
                        fontSize: 11.sp,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.edit_calendar_outlined,
              color: AppColors.black50,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _RemarksField extends StatelessWidget {
  const _RemarksField({required this.controller, required this.storedLanguage});

  final TextEditingController controller;
  final Map storedLanguage;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
      style: context.t.bodyMedium?.copyWith(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText:
            storedLanguage['e.g. Grocery items, advance payment, bill #123...'] ??
            'e.g. Grocery items, advance payment, bill #123...',
        hintStyle: context.t.bodySmall?.copyWith(
          color: AppColors.textFieldHintColor,
          fontSize: 13.sp,
        ),
        filled: true,
        fillColor:
            Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Get.isDarkMode ? Colors.white12 : AppColors.borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Get.isDarkMode ? Colors.white12 : AppColors.borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.mainColor, width: 1.4),
        ),
      ),
    );
  }
}
