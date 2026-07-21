import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../config/app_colors.dart';
import '../../../../config/dimensions.dart';
import '../../../controllers/transfer_money_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/spacing.dart';

class TransferMoneyScreen extends StatefulWidget {
  const TransferMoneyScreen({super.key});

  @override
  State<TransferMoneyScreen> createState() => _TransferMoneyScreenState();
}

class _TransferMoneyScreenState extends State<TransferMoneyScreen> {
  @override
  void initState() {
    Get.put(TransferMoneyController());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    TextTheme t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: CustomAppBar(title: storedLanguage['Transfer Money'] ?? "Transfer Money"),
      body: GetBuilder<TransferMoneyController>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: Dimensions.kDefaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VSpace(20.h),
                Text(
                  storedLanguage['Recipient Details'] ?? "Recipient Details",
                  style: t.bodyLarge?.copyWith(fontSize: 18.sp),
                ),
                VSpace(15.h),
                CustomTextField(
                  hintext: storedLanguage['Email or Phone'] ?? "Email or Phone",
                  controller: controller.emailOrPhoneCtrl,
                  isPrefixIcon: true,
                  prefixIcon: 'person',
                ),
                VSpace(30.h),
                Text(
                  storedLanguage['Amount'] ?? "Amount",
                  style: t.bodyLarge?.copyWith(fontSize: 18.sp),
                ),
                VSpace(15.h),
                CustomTextField(
                  hintext: "0.00",
                  controller: controller.amountCtrl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  isPrefixIcon: true,
                  prefixIcon: 'wallet',
                ),
                VSpace(50.h),
                AppButton(
                  text: storedLanguage['Send Money'] ?? "Send Money",
                  isLoading: controller.isLoading,
                  bgColor: AppColors.mainColor,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    controller.submitTransfer();
                  },
                ),
                VSpace(40.h),
                Divider(),
                VSpace(20.h),
                Text(
                  storedLanguage['All Contacts'] ?? "All Contacts",
                  style: t.bodyLarge?.copyWith(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                VSpace(15.h),
                CustomTextField(
                  hintext: storedLanguage['Search Contact'] ?? "Search Contact",
                  controller: controller.searchCtrl,
                  isPrefixIcon: true,
                  prefixIcon: 'search',
                  onChanged: controller.searchContacts,
                ),
                VSpace(15.h),
                _buildContactsList(controller, t),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactsList(TransferMoneyController controller, TextTheme t) {
    if (controller.isContactsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (controller.filteredContactsList.isEmpty) {
      return Center(
        child: Text(
          "No contacts found",
          style: t.bodyMedium?.copyWith(color: AppThemes.getParagraphColor()),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.filteredContactsList.length,
      itemBuilder: (context, index) {
        var contact = controller.filteredContactsList[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.mainColor.withValues(alpha: 0.1),
            child: Text(
              (contact['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
              style: TextStyle(color: AppColors.mainColor, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(contact['name'] ?? '', style: t.bodyLarge),
          subtitle: Text(contact['email'] ?? contact['phone'] ?? '', style: t.bodySmall),
          onTap: () {
            controller.selectContact(contact);
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }
}
