import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/config/dimensions.dart';
import 'package:paysecure/themes/themes.dart';
import 'package:paysecure/utils/services/helpers.dart';
import 'package:paysecure/views/widgets/app_button.dart';
import 'package:paysecure/views/widgets/custom_appbar.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../../utils/services/localstorage/hive.dart';
import '../../../../utils/services/localstorage/keys.dart';
import '../../../controllers/pin_reset_controller.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/spacing.dart';

class SecurityPinSetupScreen extends StatelessWidget {
  const SecurityPinSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<PinResetController>(
      builder: (pinController) {
        return Scaffold(
          appBar: CustomAppBar(
            title: storedLanguage['Reset Security Pin'] ?? "Reset Security Pin",
          ),
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: Dimensions.kDefaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VSpace(40.h),
                  Text(
                    pinController.question.isNotEmpty
                        ? pinController.question
                        : "What was the house number and street name you lived in as a child?",
                    style: context.t.displayMedium,
                  ),
                  VSpace(10.h),
                  CustomTextField(
                    isBorderColor: true,
                    isSuffixIcon: false,
                    contentPadding: EdgeInsets.only(left: 20.w),
                    hintext:
                        storedLanguage['Security question\'s answer'] ??
                        'Security question\'s answer',
                    controller: pinController.questionController,
                    onChanged: (v) async {},
                  ),
                  if (pinController.hint.isNotEmpty) VSpace(5.h),
                  if (pinController.hint.isNotEmpty)
                    Text(
                      "Hints: " + pinController.hint,
                      style: context.t.bodySmall?.copyWith(
                        color: AppThemes.getParagraphColor(),
                      ),
                    ),
                  VSpace(20),
                  Text("Old security pin", style: context.t.displayMedium),
                  VSpace(10.h),
                  CustomTextField(
                    isBorderColor: true,
                    isSuffixIcon: false,
                    contentPadding: EdgeInsets.only(left: 20.w),
                    hintext: 'eg: 12345',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    controller: pinController.oldPin,
                    onChanged: (v) async {},
                  ),
                  VSpace(20),
                  Text("Security pin", style: context.t.displayMedium),
                  VSpace(10.h),
                  CustomTextField(
                    isBorderColor: true,
                    isSuffixIcon: false,
                    contentPadding: EdgeInsets.only(left: 20.w),
                    hintext: 'eg: 12345',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    controller: pinController.newPin,
                    onChanged: (v) async {},
                  ),
                  VSpace(20),
                  Text("Confirm pin", style: context.t.displayMedium),
                  VSpace(10.h),
                  CustomTextField(
                    isBorderColor: true,
                    isSuffixIcon: false,
                    contentPadding: EdgeInsets.only(left: 20.w),
                    hintext: 'eg: 12345',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    controller: pinController.confirmPin,
                    onChanged: (v) async {},
                  ),

                  VSpace(40.h),
                  AppButton(
                    isLoading: pinController.isLoading,
                    onTap:
                        pinController.isLoading
                            ? null
                            : () async {
                              try {
                                if (pinController
                                    .questionController
                                    .text
                                    .isEmpty) {
                                  Helpers.showSnackBar(
                                    msg: "Question field is required",
                                  );
                                } else if (pinController.oldPin.text.isEmpty) {
                                  Helpers.showSnackBar(
                                    msg: "Old Pin is required",
                                  );
                                } else if (pinController.newPin.text.isEmpty) {
                                  Helpers.showSnackBar(
                                    msg: "New Pin is required",
                                  );
                                } else if (pinController
                                    .confirmPin
                                    .text
                                    .isEmpty) {
                                  Helpers.showSnackBar(
                                    msg: "Confirm Pin is required",
                                  );
                                } else if (pinController.newPin.text !=
                                    pinController.confirmPin.text) {
                                  Helpers.showSnackBar(
                                    msg:
                                        "New Pin and Confirm Pin doesn't match.",
                                  );
                                } else {
                                  await pinController.pinReset(
                                    fields: {
                                      "answer":
                                          pinController.questionController.text,
                                      "old_security_pin":
                                          pinController.oldPin.text,
                                      "security_pin": pinController.newPin.text,
                                      "security_pin_confirmation":
                                          pinController.confirmPin.text,
                                    },
                                  );
                                }
                              } catch (e) {
                                Helpers.showSnackBar(msg: e.toString());
                              }
                            },
                    text:
                        storedLanguage['Reset Security PIN'] ??
                        "Reset Security PIN",
                  ),
                  VSpace(65.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
