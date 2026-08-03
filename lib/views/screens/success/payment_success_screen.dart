import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:paysecure/config/dimensions.dart';
import 'package:paysecure/controllers/bindings/controller_index.dart';
import 'package:paysecure/routes/routes_name.dart';
import 'package:paysecure/themes/themes.dart';
import 'package:paysecure/utils/app_constants.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/views/widgets/app_button.dart';
import 'package:paysecure/views/widgets/spacing.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../../config/app_colors.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final bool? isFromDepositPage;
  final String amount;
  final String currencySymbol;
  final String gateway;
  const PaymentSuccessScreen({
    Key? key,
    this.isFromDepositPage = false,
    required this.amount,
    required this.currencySymbol,
    required this.gateway,
  }) : super(key: key);

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  late ConfettiController _centerController;

  @override
  void initState() {
    super.initState();
    _centerController =
        ConfettiController(duration: const Duration(seconds: 40));
    _centerController.play();
  }

  @override
  void dispose() {
    _centerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Get.offAllNamed(RoutesName.bottomNavBar);
      },
      child: Scaffold(
        backgroundColor:
            Get.isDarkMode ? AppColors.darkBgColor : AppColors.fillColorColor,
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Center(
                child: Image.asset(
                  "$rootImageDir/success_top.png",
                  width: 295.w,
                  height: 127.h,
                  fit: BoxFit.fitHeight,
                  color: AppColors.mainColor.withValues(alpha: .3),
                ),
              ),
              VSpace(10.h),
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    "$rootImageDir/success_bottom.png",
                    width: double.maxFinite,
                    height: 127.h,
                    fit: BoxFit.fitHeight,
                    color: AppColors.mainColor.withValues(alpha: .3),
                  ),
                  Positioned(
                    top: 40.h,
                    child: Image.asset(
                      "$rootImageDir/success_middle.png",
                      width: 96.h,
                      height: 96.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: ConfettiWidget(
                      confettiController: _centerController,
                      blastDirection: pi / 2,
                      maxBlastForce: 5,
                      minBlastForce: 1,
                      emissionFrequency: 0.03,
                      numberOfParticles: 10,
                      gravity: 0,
                    ),
                  ),
                ],
              ),
              VSpace(30.h),
              Text(
                  widget.isFromDepositPage == true
                      ? storedLanguage['Deposit Success'] ?? "Deposit Success"
                    : storedLanguage['Payment Success'] ??
                      "Payment Success",
                  style: context.t.bodyMedium?.copyWith(fontSize: 32.sp)),
              VSpace(40.h),
              Padding(
                padding: Dimensions.kDefaultPadding,
                child: Container(
                  width: double.maxFinite,
                  height: 68.h,
                  decoration: BoxDecoration(
                    color: AppThemes.getDarkCardColor(),
                    borderRadius: Dimensions.kBorderRadius,
                    border: Border.all(
                      color: AppColors.mainColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "${Helpers.numberFormatWithAsFixed2('', widget.amount)} ${widget.currencySymbol}",
                      style: context.t.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold, fontSize: 32.sp),
                    ),
                  ),
                ),
              ),
              VSpace(40.h),
              Padding(
                padding: Dimensions.kDefaultPadding,
                child: Container(
                    width: double.maxFinite,
                    height: 150.h,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                    decoration: BoxDecoration(
                      color: AppThemes.getDarkCardColor(),
                      borderRadius: Dimensions.kBorderRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.isFromDepositPage == true
                                  ? "Deposit Amount"
                                : "Payment Amount",
                              style: context.t.displayMedium?.copyWith(
                                  color: AppThemes.getParagraphColor()),
                            ),
                            Expanded(
                                child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                  "${Helpers.numberFormatWithAsFixed2('', widget.amount)} ${widget.currencySymbol}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.t.bodyMedium),
                            )),
                          ],
                        ),
                        Container(
                          width: double.maxFinite,
                          height: .5,
                          color: AppThemes.getSliderInactiveColor(),
                        ),
                        Row(
                          children: [
                            Text(
                              "Gateway",
                              style: context.t.displayMedium?.copyWith(
                                  color: AppThemes.getParagraphColor()),
                            ),
                            Expanded(
                                child: Align(
                              alignment: Alignment.centerRight,
                              child: Text("${widget.gateway}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.t.bodyMedium),
                            )),
                          ],
                        ),
                        Container(
                          width: double.maxFinite,
                          height: .5,
                          color: AppThemes.getSliderInactiveColor(),
                        ),
                        Row(
                          children: [
                            Text(
                              "Date",
                              style: context.t.displayMedium?.copyWith(
                                  color: AppThemes.getParagraphColor()),
                            ),
                            Expanded(
                                child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                  "${DateFormat('MMM d, yyyy').format(DateTime.now())}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.t.bodyMedium),
                            )),
                          ],
                        ),
                      ],
                    )),
              ),
              VSpace(40.h),
              Padding(
                padding: Dimensions.kDefaultPadding,
                child: AppButton(
                  onTap: () {
                    Get.offAllNamed(RoutesName.bottomNavBar);
                  },
                  text: storedLanguage['Return Home'] ?? "Return Home",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
