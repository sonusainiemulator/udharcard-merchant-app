import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../config/app_colors.dart';
import '../../../controllers/udhar_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/helpers.dart';
import '../../widgets/spacing.dart';
import '../../widgets/text_theme_extension.dart';

Future<Map<String, dynamic>?> openAddCustomerScreen({
  required Map storedLanguage,
  String? initialName,
  String? initialPhone,
}) async {
  if (Get.isRegistered<UdharController>()) {
    final ctrl = Get.find<UdharController>();
    await ctrl.checkConnection();
    if (ctrl.isOffline) {
      Helpers.showSnackBar(msg: 'No internet. Adding customers requires realtime sync.');
      return null;
    }
    ctrl.showCustomerLimitNudgeIfNeeded();
  }

  return Get.toNamed<Map<String, dynamic>?>(
    RoutesName.addCustomerScreen,
    arguments: {
      'storedLanguage': storedLanguage,
      'initialName': initialName,
      'initialPhone': initialPhone,
    },
  ) ?? Future.value(null);
}

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  static const Color _accentColor = Color(0xFFD3262A);
  static const Color _fieldBorder = Color(0xFFE8E8E8);

  late final UdharController _controller;
  late final Map _storedLanguage;

  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  bool _showMoreInfo = true;
  String _selectedType = 'Customer';

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
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkBgColor : const Color(0xFFFDFDFD);
    final cardColor = isDark ? AppColors.darkCardColor : Colors.white;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          surfaceTintColor: backgroundColor,
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
              size: 20.sp,
            ),
          ),
          centerTitle: true,
          title: Text(
            'Add Parties',
            style: context.t.bodyLarge?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.blackColor,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhoneField(context, cardColor),
                VSpace(16.h),
                _buildLabeledField(
                  context: context,
                  label: 'Customer Name',
                  child: _buildTextField(
                    context: context,
                    controller: _controller.nameCtrl,
                    hint: _storedLanguage['Name'] ?? 'Enter customer name',
                    fillColor: cardColor,
                  ),
                ),
                VSpace(18.h),
                _buildPartyTypeSection(context),
                VSpace(18.h),
                Center(child: _buildMoreInfoToggle(context)),
                VSpace(18.h),
                Center(child: _buildAvatarSection()),
                if (_showMoreInfo) ...[
                  VSpace(24.h),
                  _buildLabeledField(
                    context: context,
                    label: 'Email Address',
                    child: _buildTextField(
                      context: context,
                      controller: _controller.emailCtrl,
                      hint: _storedLanguage['Email'] ?? 'Enter email address',
                      keyboardType: TextInputType.emailAddress,
                      fillColor: cardColor,
                    ),
                  ),
                  VSpace(16.h),
                  _buildLabeledField(
                    context: context,
                    label: 'Address',
                    child: _buildTextField(
                      context: context,
                      controller: _addressCtrl,
                      hint: 'Plocentia, California(CA), 92870',
                      fillColor: cardColor,
                    ),
                  ),
                  VSpace(16.h),
                  _buildLabeledField(
                    context: context,
                    label: 'Note',
                    child: _buildTextField(
                      context: context,
                      controller: _noteCtrl,
                      hint: 'Text...',
                      fillColor: cardColor,
                      maxLines: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(
            20.w,
            10.h,
            20.w,
            MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                14.h,
          ),
          child: GetBuilder<UdharController>(
            builder: (ctrl) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ctrl.isOffline)
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Text(
                      'Internet required to save customer.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black50,
                      ),
                    ),
                  ),
                SizedBox(
                  height: 52.h,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      disabledBackgroundColor: _accentColor.withValues(alpha: 0.55),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.r),
                      ),
                    ),
                    onPressed: (ctrl.isAddingCustomer || ctrl.isOffline)
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            ctrl.addCustomer(
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
                        : Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context, Color fillColor) {
    return _buildLabeledField(
      context: context,
      label: 'Phone Number',
      child: Container(
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: Get.isDarkMode
                ? AppThemes.getSliderInactiveColor()
                : _fieldBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.all(10.w),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Get.isDarkMode
                    ? AppColors.darkBgColor
                    : AppColors.black10.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14.sp, color: AppColors.black60),
                  HSpace(4.w),
                  Container(
                    width: 15.w,
                    height: 11.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F9D58),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                    child: Center(
                      child: Container(
                        width: 4.w,
                        height: 4.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  HSpace(7.w),
                  Text(
                    '+91',
                    style: context.t.bodyMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller.phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                style: context.t.bodyMedium?.copyWith(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  hintStyle: context.t.bodySmall?.copyWith(
                    color: AppColors.textFieldHintColor,
                    fontSize: 13.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(right: 14.w),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyTypeSection(BuildContext context) {
    final options = ['Customer', 'Dealer', 'Wholesaler', 'Supplier'];
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: options
          .map(
            (option) => SizedBox(
              width: (MediaQuery.of(context).size.width - 64.w) / 2,
              child: InkWell(
                onTap: () => setState(() => _selectedType = option),
                borderRadius: BorderRadius.circular(24.r),
                child: Row(
                  children: [
                    Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedType == option
                              ? _accentColor
                              : AppColors.black30,
                          width: 1.4,
                        ),
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedType == option
                                ? _accentColor
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    HSpace(10.w),
                    Expanded(
                      child: Text(
                        option,
                        style: context.t.bodyMedium?.copyWith(
                          fontSize: 14.sp,
                          color: Get.isDarkMode ? Colors.white : AppColors.black70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMoreInfoToggle(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _showMoreInfo = !_showMoreInfo),
      borderRadius: BorderRadius.circular(20.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'More info',
              style: context.t.bodyMedium?.copyWith(
                color: _accentColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            HSpace(3.w),
            Icon(
              _showMoreInfo
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: _accentColor,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 92.w,
          height: 92.w,
          decoration: const BoxDecoration(
            color: Color(0xFFFDECEF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: _accentColor,
            size: 48.sp,
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: _accentColor,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {},
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({
    required BuildContext context,
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.t.bodySmall?.copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: Get.isDarkMode ? AppColors.black20 : AppColors.black50,
          ),
        ),
        VSpace(6.h),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required Color fillColor,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Get.isDarkMode
              ? AppThemes.getSliderInactiveColor()
              : _fieldBorder,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: maxLines,
        style: context.t.bodyMedium?.copyWith(fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: context.t.bodySmall?.copyWith(
            color: AppColors.textFieldHintColor,
            fontSize: 13.sp,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: maxLines == 1 ? 16.h : 14.h,
          ),
        ),
      ),
    );
  }
}