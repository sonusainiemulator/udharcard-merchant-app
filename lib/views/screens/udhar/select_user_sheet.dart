import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/spacing.dart';
import '../../widgets/text_theme_extension.dart';

/// A bottom sheet for picking a customer to attach to the udhar entry.
class SelectUserSheet extends StatelessWidget {
  const SelectUserSheet({super.key});

  /// Open as modal bottom sheet and return the selected contact map (or null).
  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SelectUserSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};

    return GetBuilder<UdharController>(
      builder: (controller) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Get.isDarkMode
                    ? AppColors.darkBgColor
                    : AppColors.whiteColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                children: [
                  // ── Drag handle ─────────────────────────────────
                  VSpace(12.h),
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.black20,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  VSpace(16.h),

                  // ── Header ──────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Text(
                          storedLanguage['Select Customer'] ?? 'Select Customer',
                          style: context.t.bodyLarge?.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            await controller.pickContactFromPhonebook();
                          },
                          icon: Icon(Icons.contacts, size: 22.sp, color: AppColors.mainColor),
                          tooltip: "Import from Phonebook",
                        ),
                        HSpace(4.w),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Icon(Icons.close,
                              size: 22.sp, color: AppColors.black50),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  VSpace(12.h),

                  // ── Search bar ──────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: TextField(
                      controller: controller.searchCtrl,
                      onChanged: controller.searchUsers,
                      decoration: InputDecoration(
                        hintText:
                            storedLanguage['Search by name, email or phone'] ??
                                'Search by name, email or phone',
                        hintStyle: context.t.bodySmall
                            ?.copyWith(color: AppColors.textFieldHintColor),
                        prefixIcon:
                            Icon(Icons.search, color: AppColors.black50),
                        filled: true,
                        fillColor: Get.isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.fillColorColor,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  VSpace(12.h),

                  // ── List ────────────────────────────────────────
                  Expanded(
                    child: controller.isUsersLoading
                        ? const Center(child: CircularProgressIndicator())
                        : controller.filteredUsers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_search,
                                        size: 48.sp, color: AppColors.black30),
                                    VSpace(8.h),
                                    Text(
                                      storedLanguage['No customers found'] ??
                                          'No customers found',
                                      style: context.t.bodyMedium
                                          ?.copyWith(color: AppColors.black50),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                itemCount: controller.filteredUsers.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: Get.isDarkMode
                                      ? AppColors.black70
                                      : AppColors.borderColor,
                                ),
                                itemBuilder: (context, index) {
                                  final user =
                                      controller.filteredUsers[index];
                                  final String name =
                                      (user['name'] ?? 'User').toString();
                                  final String sub =
                                      (user['email'] ?? user['phone'] ?? '')
                                          .toString();
                                  final String initial =
                                      name.isNotEmpty ? name[0].toUpperCase() : 'U';

                                  // Assign a consistent avatar color from the brand palette
                                  final Color avatarColor = AppColors.colors[
                                      index % AppColors.colors.length];

                                  return ListTile(
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 4.h),
                                    leading: CircleAvatar(
                                      radius: 22.r,
                                      backgroundColor:
                                          avatarColor.withValues(alpha: 0.15),
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          color: avatarColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                    ),
                                    title: Text(name,
                                        style: context.t.bodyLarge),
                                    subtitle: sub.isNotEmpty
                                        ? Text(sub,
                                            style: context.t.bodySmall
                                                ?.copyWith(
                                                    color: AppColors.black50))
                                        : null,
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: AppColors.black30,
                                      size: 20.sp,
                                    ),
                                    onTap: () {
                                      // Clear search state for next open
                                      controller.searchCtrl.clear();
                                      controller.searchUsers('');
                                      Get.back(result: Map<String, dynamic>.from(user));
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
