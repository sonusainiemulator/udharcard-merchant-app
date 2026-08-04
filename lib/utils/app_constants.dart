class AppConstants {
  static const String appName = 'UdharCard Merchant';

  //BASE_URL
  static const String baseUrl = 'https://pay.udharcard.shop' + '$prefix';

  //END_POINTS_URL
  static const String prefix = '/api';
  static const String registerUrl = '/register';
  static const String loginUrl = '/login';
  static const String checkMerchantUrl = '/merchant/check-exist';
  static const String forgotPassUrl = '/recovery-pass/get-email';
  static const String forgotPassGetCodeUrl = '/recovery-pass/get-code';
  static const String updatePassUrl = '/update-pass';
  static const String languageUrl = '/language';
  static const String profileUrl = '/profile';
  static const String profilePassUpdateUrl = '/change-password';
  static const String verificationUrl = '/kyc/list';
  static const String identityVerificationUrl = '/kyc/submit';
  static const String twoFaSecurityUrl = '/2FA-security';
  static const String twoFaSecurityEnableUrl = '/2FA-security/enable';
  static const String twoFaSecurityDisableUrl = '/2FA-security/disable';
  static const String twoFaVerifyUrl = '/twoFA-Verify';
  static const String mailUrl = '/mail-verify';
  static const String smsVerifyUrl = '/sms-verify';
  static const String resendCodeUrl = '/resend-code';
  static const String pusherConfigUrl = "/pusher/config";

  //----NOTIFICATION SETTINGS
  static const String notificationSettingsUrl = "/notification-settings";
  static const String notificationPermissionUrl = "/notification-permission";

  //----SUPPORT TICKET
  static const String supportTicketListUrl = '/support-ticket/list';
  static const String supportTicketCreateUrl = '/support-ticket/create';
  static const String supportTicketReplyUrl = '/support-ticket/reply';
  static const String supportTicketViewUrl = '/support-ticket/view';
  static const String supportTicketCloseUrl = '/close-ticket';

  static const String transactionUrl = '/transaction-history';
  static const String dashboardUrl = '/merchant/dashboard';

  //----merchant setting
  static const String merchatSettingUrl = "/merchant/settings";
  static const String merchatSettingUpdate = "/merchant/settings-update";

  //----pin reset
  static const String pinReset = "/security-pin/reset";

  //----WITHDRAW
  static const String withdrawList = "/payout-list";
  static const String payoutUrl = "/payout";
  static const String payoutRequestUrl = "/payout-submit";
  static const String payoutConfirmSubmitUrl = "/payout/confirm/submit";
  static const String getBankFromBankUrl = "/payout/get-bank/from";
  static const String getBankFromCurrencyUrl = "/payout/get-bank/list";
  static const String flutterwaveSubmitUrl =
      "/payout/confirm/submit/flutterwave";
  static const String paystackSubmitUrl = "/payout/confirm/submit/paystack";
  static const String payoutConfirmPreviewUrl = "/payout/confirm/preview";


  //----QR PAYMENT
  static const String qrPaymentList = "/get/qr-payment";

  //----SECURITY PIN MANAGE
  static const String pinManage = "/security-pin/manage";

  static const String baisicCtrl = "/basic";
  static const String deleteAccount = "/delete-account";

  //----TRANSFER MONEY
  static const String transferMoneySubmitUrl = "/merchant/transfer";
  static const String getContactsUrl = "/merchant/udhar/contacts";

  //----UDHAR
  static const String addUdharUrl = "/merchant/udhar/ledger";
  static const String addCustomerUrl = "/merchant/udhar/customers/store";
  static const String updateCustomerUrl = "/merchant/udhar/customers/update";
  static const String deleteCustomerUrl = "/merchant/udhar/customers/delete";
  static const String customerLedgerUrl = "/merchant/udhar/ledger";
  static const String customerQrUrl = "/merchant/udhar/qr";
  static const String udharSyncUrl = "/merchant/udhar/sync";
  static const String sendReminderUrl = "/merchant/udhar/reminder/generate";
  static const String sendAppReminderUrl = "/merchant/udhar/customer"; // id/remind is appended in repo
  static const String generatePdfBillUrl = "/merchant/udhar/bill/download";
  static const String udharReportsUrl = "/merchant/udhar/reports";
  static const String workListUrl = "/merchant/work-list";
  static const String workListSyncUrl = "/merchant/work-list/sync";

  //----SUBSCRIPTION
  static const String subscriptionPlansUrl = "/subscription/plans";
  static const String subscriptionCurrentUrl = "/merchant/subscription/current";
  static const String subscriptionHistoryUrl = "/merchant/subscription/history";
  static const String subscriptionCheckoutUrl = "/merchant/subscription/checkout";
  static const String subscriptionVerifyUrl = "/merchant/subscription/verify";
}

//----------IMAGE DIRECTORY---------//
String rootImageDir = "assets/images";
String rootIconDir = "assets/icons";
String rootJsonDir = "assets/json";
