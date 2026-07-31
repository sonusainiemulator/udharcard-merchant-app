import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../themes/themes.dart';
import '../../widgets/spacing.dart';
import '../../widgets/text_theme_extension.dart';

/// Reusable sheet to create a new customer without showing "Opening Balance".
Future<Map<String, dynamic>?> showAddCustomerSheet({
  required BuildContext context,
  required UdharController controller,
  required Map storedLanguage,
}) {
  // Clear the opening balance text controller so that it defaults to 0
  controller.openingBalanceCtrl.clear();
  controller.nameCtrl.clear();
  controller.phoneCtrl.clear();
  controller.emailCtrl.clear();
  controller.limitCtrl.clear();

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) {
      return _AddCustomerSheetContent(
        controller: controller,
        storedLanguage: storedLanguage,
      );
    },
  );
}

class _AddCustomerSheetContent extends StatelessWidget {
  final UdharController controller;
  final Map storedLanguage;
  const _AddCustomerSheetContent({
    required this.controller,
    required this.storedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        // Push the sheet up when keyboard appears
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag Handle ─────────────────────────────────────
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 14.h, bottom: 6.h),
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.black30,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ),

              // ── Header ──────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storedLanguage['Add Customer'] ?? 'Add Customer',
                          style: context.t.bodyLarge?.copyWith(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Fill details to save customer',
                          style: context.t.bodySmall?.copyWith(
                            color: AppColors.black50,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8.h),
                        decoration: BoxDecoration(
                          color: AppColors.black10.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: AppColors.black50,
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: AppColors.borderColor.withValues(alpha: 0.3)),

              // ── Form Fields ─────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Customer Name *', context),
                    VSpace(6.h),
                    _buildField(
                      controller: controller.nameCtrl,
                      hint: storedLanguage['Name'] ?? 'Enter full name',
                      icon: Icons.person_outline_rounded,
                      context: context,
                    ),
                    VSpace(14.h),
                    _buildLabel('Phone Number *', context),
                    VSpace(6.h),
                    _buildField(
                      controller: controller.phoneCtrl,
                      hint: storedLanguage['Phone'] ?? 'Enter 10-digit number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      context: context,
                    ),
                    VSpace(14.h),
                    _buildLabel('Email (Optional)', context),
                    VSpace(6.h),
                    _buildField(
                      controller: controller.emailCtrl,
                      hint: storedLanguage['Email'] ?? 'Enter email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      context: context,
                    ),
                    VSpace(14.h),
                    _buildLabel('Credit Limit (₹)', context),
                    VSpace(6.h),
                    _buildField(
                      controller: controller.limitCtrl,
                      hint: storedLanguage['Credit Limit'] ?? 'Default: ₹5000',
                      icon: Icons.account_balance_wallet_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      context: context,
                    ),
                  ],
                ),
              ),

              VSpace(20.h),

              // ── Save Button — Always visible above keyboard ──────
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                child: GetBuilder<UdharController>(
                  builder: (ctrl) => SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        disabledBackgroundColor:
                            AppColors.mainColor.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: ctrl.isAddingCustomer
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              ctrl.addCustomer();
                            },
                      icon: ctrl.isAddingCustomer
                          ? SizedBox(
                              height: 18.h,
                              width: 18.h,
                              child: const CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.person_add_rounded,
                              color: AppColors.blackColor,
                              size: 20.sp,
                            ),
                      label: Text(
                        ctrl.isAddingCustomer
                            ? 'Saving...'
                            : storedLanguage['Add Customer'] ?? 'Save Customer',
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, BuildContext context) {
    return Text(
      text,
      style: context.t.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12.sp,
        color: AppColors.black50,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required BuildContext context,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? AppColors.darkBgColor
            : AppColors.black10.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppThemes.getSliderInactiveColor(),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: context.t.bodyMedium?.copyWith(fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: context.t.bodySmall?.copyWith(
            color: AppColors.textFieldHintColor,
            fontSize: 13.sp,
          ),
          prefixIcon: Icon(icon, color: AppColors.mainColor, size: 20.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
        ),
      ),
    );
  }
}
