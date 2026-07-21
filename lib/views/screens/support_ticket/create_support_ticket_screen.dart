import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../controllers/support_ticket_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/spacing.dart';

class CreateSupportTicketScreen extends StatelessWidget {
  const CreateSupportTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SupportTicketController.to.files.clear();
    SupportTicketController.to.result = null;
    SupportTicketController.to.selectedFilePaths.clear();
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<SupportTicketController>(
      builder: (supportTicketCtrl) {
        return Scaffold(
          appBar: CustomAppBar(
            title: storedLanguage['Create Ticket'] ?? "Create Ticket",
            actions: [],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: Dimensions.kDefaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storedLanguage['Subject'] ?? "Subject",
                    style: context.t.displayMedium,
                  ),
                  VSpace(12.h),
                  CustomTextField(
                    isBorderColor: true,
                    controller: supportTicketCtrl.subjectEditingCtrl,
                    contentPadding: EdgeInsets.only(left: 20.w),
                    hintext: storedLanguage['Enter Subject'] ?? "Enter Subject",
                    isPrefixIcon: false,
                  ),
                  VSpace(25.h),
                  Text(
                    storedLanguage['Message'] ?? "Message",
                    style: context.t.displayMedium,
                  ),
                  VSpace(12.h),
                  CustomTextField(
                    textfieldHieght: null,
                    contentPadding: EdgeInsets.only(
                      left: 20.w,
                      bottom: 0.h,
                      top: 10.h,
                    ),
                    alignment: Alignment.topLeft,
                    minLines: 3,
                    maxLines: 5,
                    isBorderColor: true,
                    isPrefixIcon: false,
                    controller: supportTicketCtrl.messageEditingCtrl,
                    hintext: storedLanguage['Enter Message'] ?? "Enter Message",
                  ),
                  VSpace(32.h),
                  DottedBorder(
                    options: RectDottedBorderOptions(
                      color: AppThemes.getSliderInactiveColor(),
                      dashPattern: const <double>[6, 4],
                    ),
                    child: Container(
                      width: double.maxFinite,
                      height:
                          supportTicketCtrl.selectedFilePaths.isEmpty
                              ? 180.h
                              : 200.h,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "$rootImageDir/drop.png",
                            color: AppColors.mainColor,
                            height: 57.h,
                          ),
                          VSpace(12.h),
                          InkWell(
                            onTap: () {
                              supportTicketCtrl.pickFiles();
                            },
                            borderRadius: Dimensions.kBorderRadius,
                            child: Container(
                              width: 165.w,
                              height: 38.h,
                              decoration: BoxDecoration(
                                color: AppColors.mainColor,
                                borderRadius: BorderRadius.circular(9.r),
                              ),
                              child: Center(
                                child: Text(
                                  storedLanguage['Browse Files'] ??
                                      "Browse Files",
                                  style: context.t.bodyLarge?.copyWith(
                                    color: AppColors.blackColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          VSpace(
                            supportTicketCtrl.selectedFilePaths.isNotEmpty
                                ? 15.h
                                : 0,
                          ),
                          supportTicketCtrl.selectedFilePaths.isEmpty
                              ? const SizedBox()
                              : Container(
                                width: 170.w,
                                height: 40.h,
                                padding: EdgeInsets.symmetric(
                                  vertical: 5.h,
                                  horizontal: 8.w,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.greenColor,
                                  borderRadius: BorderRadius.circular(32.r),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      supportTicketCtrl
                                                  .selectedFilePaths
                                                  .length <
                                              2
                                          ? "${supportTicketCtrl.selectedFilePaths.length} File selected"
                                          : "${supportTicketCtrl.selectedFilePaths.length} Files selected",
                                      style: context.t.bodySmall?.copyWith(
                                        color: AppColors.whiteColor,
                                      ),
                                    ),
                                    HSpace(6.w),
                                    InkResponse(
                                      onTap: () {
                                        supportTicketCtrl.selectedFilePaths
                                            .clear();
                                        supportTicketCtrl.files.clear();
                                        supportTicketCtrl.result = null;
                                        supportTicketCtrl.update();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(3.h),
                                        decoration: BoxDecoration(
                                          color: AppColors.redColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.close, size: 12.h),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  VSpace(40.h),
                  AppButton(
                    text: storedLanguage['Submit'] ?? "Submit",
                    isLoading:
                        supportTicketCtrl.isCreatingTicket ? true : false,
                    onTap:
                        supportTicketCtrl.isCreatingTicket
                            ? null
                            : () async {
                              if (supportTicketCtrl
                                  .subjectEditingCtrl
                                  .text
                                  .isEmpty) {
                                Helpers.showSnackBar(
                                  msg: "Subject field is required",
                                );
                              } else if (supportTicketCtrl
                                  .messageEditingCtrl
                                  .text
                                  .isEmpty) {
                                Helpers.showSnackBar(
                                  msg: "Message field is required",
                                );
                              } else {
                                await supportTicketCtrl.createTicket(context);
                              }
                            },
                  ),
                  VSpace(40.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
