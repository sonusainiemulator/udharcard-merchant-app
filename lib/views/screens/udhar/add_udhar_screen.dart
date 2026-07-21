import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};

    return GetBuilder<UdharController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor:
              Get.isDarkMode ? AppColors.darkBgColor : AppColors.scaffoldColor,
          appBar: CustomAppBar(
            title: storedLanguage['Add Udhar'] ?? 'Add Udhar',
          ),
          body: SingleChildScrollView(
            padding: Dimensions.kDefaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VSpace(8.h),

                // ── Transaction type toggle ────────────────────────
                _SectionLabel(
                  text:
                      storedLanguage['Transaction Type'] ?? 'Transaction Type',
                ),
                VSpace(10.h),
                _TypeToggle(
                  selectedType: controller.transactionType,
                  onChanged: controller.setType,
                  storedLanguage: storedLanguage,
                ),

                VSpace(28.h),

                // ── Customer selector ─────────────────────────────
                _SectionLabel(text: storedLanguage['Customer'] ?? 'Customer'),
                VSpace(10.h),
                _CustomerSelector(
                  selectedUser: controller.selectedUser,
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

                VSpace(28.h),

                // ── Amount ────────────────────────────────────────
                _SectionLabel(text: storedLanguage['Amount'] ?? 'Amount'),
                VSpace(10.h),
                _AmountField(
                  controller: controller.amountCtrl,
                  storedLanguage: storedLanguage,
                ),

                VSpace(28.h),

                // ── Remarks (optional) ────────────────────────────
                _SectionLabel(
                  text:
                      storedLanguage['Remarks (Optional)'] ??
                      'Remarks (Optional)',
                ),
                VSpace(10.h),
                _RemarksField(
                  controller: controller.remarksCtrl,
                  storedLanguage: storedLanguage,
                ),

                VSpace(40.h),

                // ── Submit ────────────────────────────────────────
                AppButton(
                  text:
                      storedLanguage['Add Udhar Transaction'] ??
                      'Add Udhar Transaction',
                  isLoading: controller.isSubmitting,
                  bgColor: AppColors.mainColor,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    controller.submitUdhar();
                  },
                ),

                VSpace(32.h),
              ],
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
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.t.bodyLarge?.copyWith(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
      ),
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
      decoration: BoxDecoration(
        color:
            Get.isDarkMode ? AppColors.darkCardColor : AppColors.fillColorColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          _TypeOption(
            label: storedLanguage['Udhar Diya (Given)'] ?? 'Udhar Diya (Given)',
            value: 'given',
            selectedType: selectedType,
            activeColor: AppColors.redColor,
            onTap: () => onChanged('given'),
          ),
          _TypeOption(
            label:
                storedLanguage['Payment Received (Udhar Aaya)'] ??
                'Payment Received (Udhar Aaya)',
            value: 'received',
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
    required this.selectedType,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final String selectedType;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.t.bodySmall?.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.whiteColor : AppColors.black50,
            ),
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
    required this.storedLanguage,
    required this.onTap,
    required this.onClear,
  });

  final Map<String, dynamic>? selectedUser;
  final Map storedLanguage;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final bool hasUser = selectedUser != null;
    final String name =
        hasUser ? (selectedUser!['name'] ?? 'User').toString() : '';
    final String sub =
        hasUser
            ? (selectedUser!['email'] ?? selectedUser!['phone'] ?? '')
                .toString()
            : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color:
              Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasUser ? AppColors.mainColor : AppColors.borderColor,
            width: hasUser ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Avatar / icon
            Container(
              width: 40.h,
              height: 40.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mainColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                hasUser ? Icons.person : Icons.person_add_alt_1,
                color: AppColors.mainColor,
                size: 20.sp,
              ),
            ),
            HSpace(12.w),

            // Text
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
                            ),
                          ),
                          if (sub.isNotEmpty)
                            Text(
                              sub,
                              style: context.t.bodySmall?.copyWith(
                                color: AppColors.black50,
                              ),
                            ),
                        ],
                      )
                      : Text(
                        storedLanguage['Tap to select customer'] ??
                            'Tap to select customer',
                        style: context.t.bodyMedium?.copyWith(
                          color: AppColors.textFieldHintColor,
                        ),
                      ),
            ),

            // Action icon
            if (hasUser)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 20.sp, color: AppColors.black30),
              )
            else
              Icon(Icons.chevron_right, size: 20.sp, color: AppColors.black30),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.storedLanguage});

  final TextEditingController controller;
  final Map storedLanguage;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: true,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      style: context.t.bodyLarge?.copyWith(fontSize: 18.sp),
      decoration: InputDecoration(
        hintText: '0.00',
        hintStyle: context.t.bodyLarge?.copyWith(
          color: AppColors.textFieldHintColor,
          fontSize: 18.sp,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Text(
            '₹',
            style: TextStyle(
              fontSize: 18.sp,
              color: AppColors.mainColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor:
            Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.mainColor),
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
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText:
            storedLanguage['e.g. Grocery items, festival advance…'] ??
            'e.g. Grocery items, festival advance…',
        hintStyle: context.t.bodySmall?.copyWith(
          color: AppColors.textFieldHintColor,
        ),
        filled: true,
        fillColor:
            Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.mainColor),
        ),
      ),
    );
  }
}
