import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paysecure/controllers/profile_controller.dart';
import 'package:paysecure/views/widgets/app_button.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../themes/themes.dart';
import '../../../utils/app_constants.dart';
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
  int selectedTabIndex = 0; // 0 = System QR, 1 = Uploaded Merchant QR

  void _showImagePickerBottomSheet(BuildContext context, ProfileController controller) {
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
                  "Upload Merchant QR Code",
                  style: context.t.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                VSpace(20.h),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.mainColor),
                  title: Text("Choose from Gallery", style: context.t.displayMedium),
                  onTap: () {
                    Navigator.pop(context);
                    controller.pickCustomQrCode(ImageSource.gallery);
                  },
                ),
                Divider(color: AppColors.sliderInActiveColor.withValues(alpha: 0.3)),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.mainColor),
                  title: Text("Take Photo from Camera", style: context.t.displayMedium),
                  onTap: () {
                    Navigator.pop(context);
                    controller.pickCustomQrCode(ImageSource.camera);
                  },
                ),
                if (controller.customQrCodePath != null) ...[
                  Divider(color: AppColors.sliderInActiveColor.withValues(alpha: 0.3)),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: Text("Remove Custom QR Code", style: context.t.displayMedium?.copyWith(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(context);
                      controller.removeCustomQrCode();
                    },
                  ),
                ]
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
          appBar: CustomAppBar(title: storedLanguage['QR Code'] ?? "QR Code"),
          body: RefreshIndicator(
            color: AppColors.mainColor,
            onRefresh: () async {
              profileController.getProfile();
            },
            child: Column(
              children: [
                VSpace(16.h),
                // Toggle Tab Bar
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureTabButton(
                          title: "App QR",
                          isSelected: selectedTabIndex == 0,
                          onTap: () {
                            setState(() {
                              selectedTabIndex = 0;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: GestureTabButton(
                          title: "Merchant QR",
                          isSelected: selectedTabIndex == 1,
                          onTap: () {
                            setState(() {
                              selectedTabIndex = 1;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                VSpace(10.h),
                Expanded(
                  child: Container(
                    padding: Dimensions.kDefaultPadding,
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: selectedTabIndex == 0
                          ? _buildSystemQrView(context, profileController)
                          : _buildCustomMerchantQrView(context, profileController),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemQrView(BuildContext context, ProfileController profileController) {
    return Column(
      children: [
        VSpace(30.h),
        Container(
          height: 260.h,
          width: 220.h,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.mainColor),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      "$rootImageDir/frame.png",
                      color: AppColors.mainColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: QrImageView(
                      data: '${profileController.userEmail}',
                      version: QrVersions.auto,
                      size: 200.h,
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppThemes.getIconBlackColor(),
                      ),
                      eyeStyle: QrEyeStyle(
                        color: AppThemes.getIconBlackColor(),
                        eyeShape: QrEyeShape.square,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Transform.rotate(
                    angle: .85,
                    child: Container(
                      height: 20.h,
                      width: 35.h,
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                      ),
                    ),
                  ),
                  Container(
                    height: 30.h,
                    width: 220.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      "Scan Here",
                      style: context.t.displayMedium?.copyWith(
                        color: AppColors.blackColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        VSpace(30.h),
        Text(
          "To receive payments, customers scan this auto-generated app QR code using their mobile device.",
          style: context.t.displayMedium,
          textAlign: TextAlign.center,
        ),
        VSpace(50.h),
      ],
    );
  }

  Widget _buildCustomMerchantQrView(BuildContext context, ProfileController profileController) {
    bool hasCustomQr = profileController.customQrCodePath != null &&
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
                )
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
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
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
                  onTap: () => _showImagePickerBottomSheet(context, profileController),
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
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: Text(
                    "Remove",
                    style: context.t.displayMedium?.copyWith(color: Colors.redAccent),
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
              border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.3), style: BorderStyle.solid),
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
                  "Upload Your QR Code",
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
                  text: "Upload QR Image",
                  onTap: () => _showImagePickerBottomSheet(context, profileController),
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

class GestureTabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const GestureTabButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: context.t.displayMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.blackColor : AppThemes.getIconBlackColor(),
          ),
        ),
      ),
    );
  }
}

