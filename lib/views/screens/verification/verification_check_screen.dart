import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../config/dimensions.dart';
import '../../../controllers/verification_controller.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/spacing.dart';
import '../../widgets/verification_bottomsheet.dart';

class VerficiationCheckScreen extends StatelessWidget {
  final String verficationType;
  VerficiationCheckScreen({super.key, required this.verficationType});

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    // storedLanguage['AddFund'] ??
    return GetBuilder<VerificationController>(builder: (verifyController) {
      return Scaffold(
        appBar: CustomAppBar(
          title: verficationType + " Verification",
        ),
        body: Padding(
          padding: Dimensions.kDefaultPadding,
          child: Column(
            children: [
              VSpace(30.h),
              if (verficationType == "Email" || verficationType == "Sms")
                Center(
                  child: Image.asset(
                    "$rootImageDir/mobile_verfication.png",
                    height: 150.h,
                    width: 150.h,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              if (verficationType == "2FA")
                Center(
                  child: Image.asset(
                    "$rootImageDir/2fa_verification.png",
                    height: 150.h,
                    width: 150.h,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              VSpace(40.h),
              Center(
                child: Text("$verficationType verification is required",
                    style: context.t.displayMedium),
              ),
              if (verficationType == "2FA")
                Padding(
                  padding: EdgeInsets.only(top: 40.h),
                  child: CustomTextField(
                    hintext: "Enter twoFa code",
                    controller: verifyController.twoFaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              if (verficationType == "2FA") VSpace(30.h),
              if (verficationType == "2FA")
                AppButton(
                  isLoading: verifyController.isVerifying ? true : false,
                  onTap: () async {
                    verifyController.twoFaVerify(
                        code: verifyController.twoFaController.text.toString());
                  },
                  text: storedLanguage['Send Code'] ?? "Send Code",
                ),
              if (verficationType != "2FA")
                Padding(
                  padding: EdgeInsets.only(top: 40.h),
                  child: AppButton(
                    text: storedLanguage['Verify Now'] ?? "Verify Now",
                    onTap: () async {
                      await verificationBottomSheet(
                          isMailVerification:
                              verficationType == "Email" ? true : false);
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
