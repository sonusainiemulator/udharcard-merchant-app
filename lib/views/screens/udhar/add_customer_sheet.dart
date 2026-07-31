import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/udhar_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_textfield.dart';
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

  return showModalBottomSheet<Map<String, dynamic>>(
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
                      color: AppColors.black30,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                VSpace(20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      storedLanguage['Add Customer'] ?? 'New Customer',
                      style: context.t.bodyLarge?.copyWith(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        color: AppColors.black50,
                        size: 24.sp,
                      ),
                    ),
                  ],
                ),
                VSpace(20.h),
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
                  hintext: storedLanguage['Email'] ?? 'Email Address (Optional)',
                  controller: controller.emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                VSpace(12.h),
                CustomTextField(
                  hintext: storedLanguage['Credit Limit'] ?? 'Credit Limit (₹)',
                  controller: controller.limitCtrl,
                  keyboardType: TextInputType.number,
                ),
                VSpace(24.h),
                GetBuilder<UdharController>(
                  builder: (ctrl) => AppButton(
                    text: storedLanguage['Add Customer'] ?? 'Create Customer',
                    isLoading: ctrl.isAddingCustomer,
                    onTap: () => ctrl.addCustomer(),
                  ),
                ),
                VSpace(10.h),
              ],
            ),
          ),
        ),
      );
    },
  );
}
