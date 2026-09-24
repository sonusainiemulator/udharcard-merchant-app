import 'dart:convert';
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
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';
import '../../../utils/services/helpers.dart';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  late final ProfileController _profileController;
  final TextEditingController _upiInputController = TextEditingController();
  bool _isEditingUpi = false;

  @override
  void initState() {
    super.initState();
    _profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    _profileController.loadCustomQrCode(notify: false);
    _profileController.loadMerchantUpiId(notify: false);
    _upiInputController.text = _profileController.merchantUpiId ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileController.loadCustomQrCode(notify: true);
      _profileController.loadMerchantUpiId(notify: true);
      _upiInputController.text = _profileController.merchantUpiId ?? '';
    });
  }

  @override
  void dispose() {
    _upiInputController.dispose();
    super.dispose();
  }

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
      builder: (sheetContext) {
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
                VSpace(16.h),
                ListTile(
                  leading: Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.mainColor,
                  ),
                  title: Text(
                    "Choose from Gallery",
                    style: context.t.displayMedium,
                  ),
                  subtitle: Text(
                    "Select QR image from your photos",
                    style: context.t.bodySmall,
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Future.delayed(const Duration(milliseconds: 200));
                    controller.pickCustomQrCode(ImageSource.gallery);
                  },
                ),
                Divider(
                  color: AppColors.sliderInActiveColor.withValues(alpha: 0.3),
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.mainColor,
                  ),
                  title: Text(
                    "Take Photo from Camera",
                    style: context.t.displayMedium,
                  ),
                  subtitle: Text(
                    "Capture physical store QR standee",
                    style: context.t.bodySmall,
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Future.delayed(const Duration(milliseconds: 200));
                    controller.pickCustomQrCode(ImageSource.camera);
                  },
                ),
                Divider(
                  color: AppColors.sliderInActiveColor.withValues(alpha: 0.3),
                ),
                ListTile(
                  leading: Icon(
                    Icons.folder_open_rounded,
                    color: AppColors.mainColor,
                  ),
                  title: Text(
                    "Browse Image Files",
                    style: context.t.displayMedium,
                  ),
                  subtitle: Text(
                    "Pick from Downloads, Drive, or WhatsApp",
                    style: context.t.bodySmall,
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Future.delayed(const Duration(milliseconds: 200));
                    controller.pickCustomQrCodeFromFilePicker();
                  },
                ),
                if (controller.customQrCodePath != null ||
                    HiveHelp.read(Keys.customQrCodeBase64) != null) ...[
                  Divider(
                    color: AppColors.sliderInActiveColor.withValues(alpha: 0.3),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      "Remove Merchant QR Image",
                      style: context.t.displayMedium?.copyWith(
                        color: Colors.redAccent,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
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
      init: _profileController,
      builder: (profileController) {
        return Scaffold(
          appBar: CustomAppBar(
            title: storedLanguage['Merchant QR'] ?? "Merchant QR",
          ),
          body: RefreshIndicator(
            color: AppColors.mainColor,
            onRefresh: () async {
              profileController.loadCustomQrCode(notify: true);
              profileController.loadMerchantUpiId(notify: true);
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
    if (profileController.isUploadingQr) {
      return Container(
        margin: EdgeInsets.only(top: 24.h),
        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
        decoration: BoxDecoration(
          color: AppThemes.getDarkCardColor(),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.mainColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
            ),
            VSpace(16.h),
            Text(
              "Saving your Merchant QR Code...",
              style: context.t.displayMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final path = profileController.customQrCodePath;
    final b64 = HiveHelp.read(Keys.customQrCodeBase64);
    final bool hasFileOnDisk =
        path != null && path.isNotEmpty && File(path).existsSync();
    final bool hasBase64 = b64 != null && b64.toString().isNotEmpty;
    final bool hasCustomQrImage = hasFileOnDisk || hasBase64;

    final shopName =
        (HiveHelp.read('shop_name') ?? 'UdharCard Store').toString().trim();
    final upiId = (profileController.merchantUpiId ??
            HiveHelp.read(Keys.merchantUpiId)?.toString() ??
            '')
        .trim();
    final bool hasUpiId = upiId.isNotEmpty;

    return Column(
      children: [
        VSpace(16.h),
        if (hasCustomQrImage) ...[
          // --- Display Custom Uploaded QR Card ---
          Container(
            padding: EdgeInsets.all(14.r),
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
                  child: hasFileOnDisk
                      ? Image.file(
                          File(path!),
                          height: 260.h,
                          width: 240.w,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) {
                            if (hasBase64) {
                              try {
                                return Image.memory(
                                  base64Decode(b64.toString()),
                                  height: 260.h,
                                  width: 240.w,
                                  fit: BoxFit.contain,
                                );
                              } catch (_) {}
                            }
                            return Icon(
                              Icons.qr_code_2_rounded,
                              size: 160.r,
                              color: AppColors.mainColor,
                            );
                          },
                        )
                      : Image.memory(
                          base64Decode(b64.toString()),
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
                    shopName.isNotEmpty ? shopName : "Your Merchant QR Code",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.t.displaySmall?.copyWith(
                      color: AppColors.blackColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasUpiId) ...[
                  VSpace(8.h),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: upiId));
                      Helpers.showSnackBar(
                          msg: "UPI ID copied: $upiId", title: "Copied");
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 14.sp,
                            color: const Color(0xFF64748B),
                          ),
                          HSpace(4.w),
                          Text(
                            "UPI: $upiId",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          VSpace(20.h),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: "Change QR",
                  onTap: () => _showImagePickerBottomSheet(
                    context,
                    profileController,
                  ),
                ),
              ),
              HSpace(10.w),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.mainColor),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.share_rounded,
                    color: AppColors.mainColor,
                    size: 18.sp,
                  ),
                  label: Text(
                    "Share QR",
                    style: context.t.displayMedium?.copyWith(
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () async {
                    try {
                      if (hasFileOnDisk) {
                        await Share.shareXFiles(
                          [XFile(path!)],
                          text:
                              "Namaste! Please scan this QR code to make your payment directly to $shopName.",
                        );
                      } else if (hasUpiId) {
                        await Share.share(
                          "Namaste! Pay directly to $shopName via UPI ID: $upiId",
                        );
                      }
                    } catch (e) {
                      Helpers.showSnackBar(msg: "Could not share QR: $e");
                    }
                  },
                ),
              ),
            ],
          ),
          VSpace(10.h),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(vertical: 10.h),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text("Remove Merchant QR"),
              onPressed: () => profileController.removeCustomQrCode(),
            ),
          ),
        ] else if (hasUpiId && !_isEditingUpi) ...[
          // --- Display Generated Dynamic UPI QR Card ---
          Container(
            padding: EdgeInsets.all(14.r),
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
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: QrImageView(
                    data: "upi://pay?pa=$upiId&pn=${Uri.encodeComponent(shopName)}&cu=INR",
                    version: QrVersions.auto,
                    size: 220.r,
                    backgroundColor: Colors.white,
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
                    shopName.isNotEmpty ? shopName : "Your UPI QR Code",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.t.displaySmall?.copyWith(
                      color: AppColors.blackColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                VSpace(8.h),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: upiId));
                    Helpers.showSnackBar(
                        msg: "UPI ID copied: $upiId", title: "Copied");
                  },
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 14.sp,
                          color: const Color(0xFF64748B),
                        ),
                        HSpace(4.w),
                        Text(
                          "UPI: $upiId",
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          VSpace(20.h),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: "Upload QR Photo",
                  onTap: () => _showImagePickerBottomSheet(
                    context,
                    profileController,
                  ),
                ),
              ),
              HSpace(10.w),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.mainColor),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.mainColor,
                    size: 18.sp,
                  ),
                  label: Text(
                    "Edit UPI ID",
                    style: context.t.displayMedium?.copyWith(
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isEditingUpi = true;
                      _upiInputController.text = upiId;
                    });
                  },
                ),
              ),
            ],
          ),
          VSpace(10.h),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(vertical: 10.h),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text("Remove UPI QR"),
              onPressed: () => profileController.removeMerchantUpiId(),
            ),
          ),
        ] else ...[
          // --- Empty State: Upload Image OR Enter UPI ID ---
          Container(
            padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 18.w),
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
                  size: 72.r,
                  color: AppColors.mainColor,
                ),
                VSpace(14.h),
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
                VSpace(20.h),
                AppButton(
                  text: "Upload Merchant QR Image",
                  onTap: () => _showImagePickerBottomSheet(
                    context,
                    profileController,
                  ),
                ),
                VSpace(24.h),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Text(
                        "OR ENTER UPI ID",
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
                VSpace(16.h),
                Container(
                  decoration: BoxDecoration(
                    color: AppThemes.getDarkCardColor(),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.mainColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _upiInputController,
                    decoration: InputDecoration(
                      hintText: "e.g. yourstore@okhdfcbank or 9876543210@paytm",
                      hintStyle: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.mainColor,
                        size: 20.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ),
                VSpace(12.h),
                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      foregroundColor: AppColors.blackColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final entered = _upiInputController.text.trim();
                      if (entered.isEmpty || !entered.contains('@')) {
                        Helpers.showSnackBar(
                          msg: "Please enter a valid UPI ID (e.g. name@bank)",
                          title: "Invalid UPI ID",
                        );
                        return;
                      }
                      setState(() {
                        _isEditingUpi = false;
                      });
                      profileController.saveMerchantUpiId(entered);
                    },
                    child: Text(
                      "Generate Instant QR from UPI ID",
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

