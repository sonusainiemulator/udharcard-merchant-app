import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../config/app_colors.dart';
import '../../../controllers/profile_controller.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';

class CompleteProfileOnboardingSheet extends StatefulWidget {
  const CompleteProfileOnboardingSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const CompleteProfileOnboardingSheet(),
    );
  }

  @override
  State<CompleteProfileOnboardingSheet> createState() =>
      _CompleteProfileOnboardingSheetState();
}

class _CompleteProfileOnboardingSheetState
    extends State<CompleteProfileOnboardingSheet> {
  final TextEditingController _shopNameCtrl = TextEditingController();
  final TextEditingController _upiIdCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();

  String _selectedCategory = 'Kirana & Grocery';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Kirana & Grocery',
    'General Store',
    'Electronics & Mobile',
    'Clothing & Fashion',
    'Hardware & Paints',
    'Medical & Pharmacy',
    'Services & Salon',
    'Restaurant & Cafe',
    'Other Business',
  ];

  @override
  void initState() {
    super.initState();
    final storedShop = (HiveHelp.read('shop_name') ?? '').toString();
    final storedUpi = (HiveHelp.read('merchant_upi_id') ?? '').toString();
    final storedCity = (HiveHelp.read('merchant_city') ?? '').toString();
    final storedCat = (HiveHelp.read('business_type') ?? '').toString();

    if (storedShop.isNotEmpty) _shopNameCtrl.text = storedShop;
    if (storedUpi.isNotEmpty) _upiIdCtrl.text = storedUpi;
    if (storedCity.isNotEmpty) _cityCtrl.text = storedCity;
    if (storedCat.isNotEmpty && _categories.contains(storedCat)) {
      _selectedCategory = storedCat;
    }
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _upiIdCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveOnboardingProfile() async {
    final shopName = _shopNameCtrl.text.trim();
    final upiId = _upiIdCtrl.text.trim();
    final city = _cityCtrl.text.trim();

    if (shopName.isEmpty) {
      Helpers.showSnackBar(
          msg: 'Please enter your shop or business name', title: 'Required');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Write all merchant details to local Hive storage
    HiveHelp.write('shop_name', shopName);
    HiveHelp.write('business_type', _selectedCategory);
    if (upiId.isNotEmpty) {
      HiveHelp.write('merchant_upi_id', upiId);
    }
    if (city.isNotEmpty) {
      HiveHelp.write('merchant_city', city);
    }
    HiveHelp.write('onboarding_completed', true);

    // Sync to ProfileController if registered
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().update();
    }

    setState(() {
      _isSubmitting = false;
    });

    Get.back();
    Helpers.showSnackBar(
      msg: 'Welcome! Your merchant profile is fully set up 🎉',
      title: 'Success',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 16.h,
        bottom: 20.h + bottomInset + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle Indicator
            Center(
              child: Container(
                width: 44.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Header Banner
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: AppColors.mainColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Complete Merchant Profile",
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Set up your store details to collect payments easily",
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Field 1: Shop / Business Name
            _buildFieldLabel("Shop / Business Name *", isDark),
            SizedBox(height: 6.h),
            _buildTextField(
              controller: _shopNameCtrl,
              hint: "e.g. Ramesh Kirana Store",
              icon: Icons.business_center_rounded,
              isDark: isDark,
            ),

            SizedBox(height: 14.h),

            // Field 2: Business Category Dropdown
            _buildFieldLabel("Business Category", isDark),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor:
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
              ),
            ),

            SizedBox(height: 14.h),

            // Field 3: Merchant UPI ID
            _buildFieldLabel("Merchant UPI ID (Optional)", isDark),
            SizedBox(height: 2.h),
            Text(
              "Used for 1-tap WhatsApp payment reminders & UPI QR collections",
              style: TextStyle(fontSize: 10.sp, color: const Color(0xFF64748B)),
            ),
            SizedBox(height: 6.h),
            _buildTextField(
              controller: _upiIdCtrl,
              hint: "e.g. 9876543210@paytm or store@upi",
              icon: Icons.qr_code_rounded,
              isDark: isDark,
            ),

            SizedBox(height: 14.h),

            // Field 4: Store City / Location
            _buildFieldLabel("City / Location (Optional)", isDark),
            SizedBox(height: 6.h),
            _buildTextField(
              controller: _cityCtrl,
              hint: "e.g. New Delhi, Delhi",
              icon: Icons.location_on_rounded,
              isDark: isDark,
            ),

            SizedBox(height: 22.h),

            // Action Buttons Row
            Row(
              children: [
                // Skip Button
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      HiveHelp.write('onboarding_completed', true);
                      Get.back();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      "Skip for Now",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Primary Save Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _saveOnboardingProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Save & Continue",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
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

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontSize: 13.sp,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 12.sp,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          prefixIcon: Icon(icon, color: AppColors.mainColor, size: 18.sp),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
        ),
      ),
    );
  }
}
