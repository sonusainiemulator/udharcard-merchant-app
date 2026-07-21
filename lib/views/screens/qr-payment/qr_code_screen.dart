import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/profile_controller.dart';
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

class QrCodeScreen extends StatelessWidget {
  const QrCodeScreen({super.key});

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
                VSpace(20.h),
                Expanded(
                  child: Container(
                    padding: Dimensions.kDefaultPadding,
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          VSpace(40.h),
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
                                          dataModuleShape:
                                              QrDataModuleShape.square,
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
                                        "Scane Here",
                                        style: context.t.displayMedium
                                            ?.copyWith(
                                              color: AppColors.blackColor,
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
                            "To make a payment, the user simply scans a QR code using their mobile device. Once scanned, the payment details are processed instantly for a seamless transaction.",
                            style: context.t.displayMedium,
                          ),
                          VSpace(50.h),
                        ],
                      ),
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
}
