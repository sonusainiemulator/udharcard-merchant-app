import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../config/app_colors.dart';
import '../../../controllers/profile_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../../utils/services/subscription_gate_service.dart';
import '../../widgets/fintech_auth_widgets.dart';

class MerchantOnboardingWizardScreen extends StatefulWidget {
  const MerchantOnboardingWizardScreen({super.key});

  @override
  State<MerchantOnboardingWizardScreen> createState() =>
      _MerchantOnboardingWizardScreenState();
}

class _MerchantOnboardingWizardScreenState
    extends State<MerchantOnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form Controllers
  final TextEditingController _shopNameCtrl = TextEditingController();
  final TextEditingController _upiIdCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();

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
    'Wholesale & Retail',
    'Other Business',
  ];

  @override
  void initState() {
    super.initState();
    final storedShop = (HiveHelp.read('shop_name') ?? '').toString();
    final storedUpi = (HiveHelp.read('merchant_upi_id') ?? '').toString();
    final storedCity = (HiveHelp.read('merchant_city') ?? '').toString();
    final storedAddress = (HiveHelp.read('merchant_address') ?? '').toString();
    final storedPincode = (HiveHelp.read('merchant_pincode') ?? '').toString();
    final storedCat = (HiveHelp.read('business_type') ?? '').toString();

    if (storedShop.isNotEmpty) _shopNameCtrl.text = storedShop;
    if (storedUpi.isNotEmpty) _upiIdCtrl.text = storedUpi;
    if (storedCity.isNotEmpty) _cityCtrl.text = storedCity;
    if (storedAddress.isNotEmpty) _addressCtrl.text = storedAddress;
    if (storedPincode.isNotEmpty) _pincodeCtrl.text = storedPincode;
    if (storedCat.isNotEmpty && _categories.contains(storedCat)) {
      _selectedCategory = storedCat;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shopNameCtrl.dispose();
    _upiIdCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_shopNameCtrl.text.trim().isEmpty) {
        Helpers.showToast(msg: 'Please enter your shop or business name');
        return;
      }
    }
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeWizard();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeWizard() async {
    final shopName = _shopNameCtrl.text.trim();
    final upiId = _upiIdCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final pincode = _pincodeCtrl.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    // Write onboarding profile to local Hive storage
    HiveHelp.write('shop_name', shopName);
    HiveHelp.write('business_type', _selectedCategory);
    if (upiId.isNotEmpty) HiveHelp.write('merchant_upi_id', upiId);
    if (address.isNotEmpty) HiveHelp.write('merchant_address', address);
    if (city.isNotEmpty) HiveHelp.write('merchant_city', city);
    if (pincode.isNotEmpty) HiveHelp.write('merchant_pincode', pincode);
    HiveHelp.write('onboarding_completed', true);

    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().update();
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!SubscriptionGateService.isPlanEnrollmentRequired()) {
      Get.offAllNamed(RoutesName.bottomNavBar);
    } else if ((HiveHelp.read(Keys.subscriptionPlanSelected) ?? false) == true) {
      Get.offAllNamed(RoutesName.bottomNavBar);
    } else {
      Get.offAllNamed(RoutesName.subscriptionPlansScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar & Step Indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (_currentStep > 0)
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: _previousStep,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (_currentStep > 0) SizedBox(width: 12.w),
                          Text(
                            "Step ${_currentStep + 1} of 3",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mainColor,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _completeWizard,
                        child: Text(
                          "Skip Wizard",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Progress Bar
                  Row(
                    children: List.generate(3, (index) {
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 6.h,
                          margin: EdgeInsets.symmetric(horizontal: 3.w),
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? AppColors.mainColor
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Wizard Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildStep1StoreInfo(isDark),
                  _buildStep2PaymentSetup(isDark),
                  _buildStep3LocationInfo(isDark),
                ],
              ),
            ),

            // Bottom Navigation CTA Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _previousStep,
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
                          "Back",
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
                  if (_currentStep > 0) SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _nextStep,
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
                              _currentStep == 2
                                  ? "Finish & Launch Dashboard 🚀"
                                  : "Continue to Next Step ➔",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🏪 Step 1: Store & Category Selection
  Widget _buildStep1StoreInfo(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.storefront_rounded,
            title: "Store Profile & Category",
            subtitle: "Enter your business name and select your shop category",
            isDark: isDark,
          ),
          SizedBox(height: 24.h),
          FintechTextField(
            label: "Shop / Business Name *",
            hint: "e.g. Ramesh Kirana & General Store",
            controller: _shopNameCtrl,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 20.h),
          Text(
            "Select Business Category *",
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 10.h,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                selectedColor: AppColors.mainColor,
                backgroundColor:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.sp,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.mainColor
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 💳 Step 2: UPI Payment Collection Setup
  Widget _buildStep2PaymentSetup(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.qr_code_scanner_rounded,
            title: "Payment Collection Setup",
            subtitle: "Configure your UPI ID to receive 1-tap WhatsApp payments",
            isDark: isDark,
          ),
          SizedBox(height: 24.h),
          FintechTextField(
            label: "Merchant UPI ID (Optional)",
            hint: "e.g. 9876543210@paytm or store@upi",
            controller: _upiIdCtrl,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 8.h),
          Text(
            "Customers will receive direct UPI payment links with your UPI ID",
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 24.h),

          // Accepted Payment Apps Card
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.mainColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "Supported Collection Modes",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  "All standard UPI apps (Google Pay, PhonePe, Paytm, BHIM) are automatically enabled for collection.",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📍 Step 3: Location & Business Address
  Widget _buildStep3LocationInfo(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.location_on_rounded,
            title: "Store Location & Address",
            subtitle: "Add your shop locality and city for invoices & receipts",
            isDark: isDark,
          ),
          SizedBox(height: 24.h),
          FintechTextField(
            label: "Store Address / Locality (Optional)",
            hint: "e.g. Shop 12, Main Market, Sector 14",
            controller: _addressCtrl,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: FintechTextField(
                  label: "City (Optional)",
                  hint: "e.g. Gurugram",
                  controller: _cityCtrl,
                  textInputAction: TextInputAction.next,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: FintechTextField(
                  label: "Pincode (Optional)",
                  hint: "e.g. 122001",
                  controller: _pincodeCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppColors.mainColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            icon,
            color: AppColors.mainColor,
            size: 26.sp,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
