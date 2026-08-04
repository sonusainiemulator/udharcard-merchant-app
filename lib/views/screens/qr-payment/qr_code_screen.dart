import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paysecure/controllers/profile_controller.dart';
import 'package:paysecure/views/widgets/app_button.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  void _showImagePickerBottomSheet(
    BuildContext context,
    ProfileController controller,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getDarkCardColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Upload Merchant QR",
                  style: context.t.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                VSpace(20.h),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: AppColors.mainColor,
                  ),
                  title: Text(
                    "Choose from Gallery",
                    style: context.t.displayMedium,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    controller.pickCustomQrCode(ImageSource.gallery);
                  },
                ),
                Divider(
                  color: AppColors.sliderInActiveColor.withValues(alpha: 0.3),
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.mainColor),
                  title: Text(
                    "Take Photo from Camera",
                    style: context.t.displayMedium,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    controller.pickCustomQrCode(ImageSource.camera);
                  },
                ),
                if (controller.customQrCodePath != null) ...[
                  Divider(
                    color: AppColors.sliderInActiveColor.withValues(alpha: 0.3),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      "Remove Merchant QR",
                      style: context.t.displayMedium?.copyWith(
                        color: Colors.redAccent,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      controller.removeCustomQrCode();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        return Scaffold(
          appBar: CustomAppBar(
            title: storedLanguage['Merchant QR'] ?? "Merchant QR",
          ),
          body: RefreshIndicator(
            color: AppColors.mainColor,
            onRefresh: () async {
              profileController.getProfile();
            },
            child: Container(
              padding: Dimensions.kDefaultPadding,
              width: double.maxFinite,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    VSpace(12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 14.w,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        "System QR is temporarily disabled. Please use uploaded Merchant QR for online payments.",
                        textAlign: TextAlign.center,
                        style: context.t.bodySmall,
                      ),
                    ),
                    VSpace(14.h),
                    _buildCustomMerchantQrView(context, profileController),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomMerchantQrView(
    BuildContext context,
    ProfileController profileController,
  ) {
    bool hasCustomQr =
        profileController.customQrCodePath != null &&
        File(profileController.customQrCodePath!).existsSync();

    return Column(
      children: [
        VSpace(20.h),
        if (hasCustomQr) ...[
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppThemes.getDarkCardColor(),
              border: Border.all(color: AppColors.mainColor, width: 2.w),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.file(
                    File(profileController.customQrCodePath!),
                    height: 260.h,
                    width: 240.w,
                    fit: BoxFit.contain,
                  ),
                ),
                VSpace(12.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    "Your Merchant QR Code",
                    style: context.t.displaySmall?.copyWith(
                      color: AppColors.blackColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          VSpace(24.h),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: "Change QR",
                  onTap:
                      () => _showImagePickerBottomSheet(
                        context,
                        profileController,
                      ),
                ),
              ),
              HSpace(12.w),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  label: Text(
                    "Remove",
                    style: context.t.displayMedium?.copyWith(
                      color: Colors.redAccent,
                    ),
                  ),
                  onPressed: () => profileController.removeCustomQrCode(),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.mainColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.mainColor.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 80.r,
                  color: AppColors.mainColor,
                ),
                VSpace(16.h),
                Text(
                  "Upload Merchant QR",
                  style: context.t.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                VSpace(8.h),
                Text(
                  "Upload your existing store QR code (Google Pay, PhonePe, Paytm, BharatPe, or Bank QR) so customers can pay you directly.",
                  textAlign: TextAlign.center,
                  style: context.t.displayMedium?.copyWith(
                    color: AppThemes.getParagraphColor(),
                  ),
                ),
                VSpace(24.h),
                AppButton(
                  text: "Upload Merchant QR Image",
                  onTap:
                      () => _showImagePickerBottomSheet(
                        context,
                        profileController,
                      ),
                ),
              ],
            ),
          ),
        ],
        VSpace(40.h),
      ],
    );
  }
}
