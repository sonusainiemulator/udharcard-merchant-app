import '../views/screens/merchant-settings/merchant_settings_screen.dart';
import '../views/screens/pin_setup/security_pin_setup_screen.dart';
import '../views/screens/qr-payment/qr_code_screen.dart';
import '../views/screens/transfer/transfer_money_screen.dart';
import '../views/screens/udhar/add_udhar_screen.dart';
import '../views/screens/udhar/customer_list_screen.dart';
import '../views/screens/udhar/customer_ledger_screen.dart';
import '../views/screens/udhar/chat_ledger_screen.dart';
import '../views/screens/udhar/udhar_dashboard_screen.dart';
import 'routes_name.dart';
import '../routes/page_index.dart';

class RouteHelper {
  static List<GetPage> routes() => [
    GetPage(name: RoutesName.INITIAL, page: () => SplashScreen()),
    GetPage(name: RoutesName.onbordingScreen, page: () => OnbordingScreen()),
    GetPage(name: RoutesName.bottomNavBar, page: () => BottomNavBar()),
    GetPage(name: RoutesName.loginScreen, page: () => LoginScreen()),
    GetPage(name: RoutesName.registerScreen, page: () => RegisterScreen()),
    GetPage(name: RoutesName.forgotPassScreen, page: () => ForgotPassScreen()),
    GetPage(name: RoutesName.otpScreen, page: () => OtpScreen()),
    GetPage(name: RoutesName.firebasePhoneLoginScreen, page: () => FirebasePhoneLoginScreen()),
    GetPage(name: RoutesName.firebaseOtpVerifyScreen, page: () => FirebaseOtpVerifyScreen()),
    GetPage(
      name: RoutesName.createNewPassScreen,
      page: () => CreateNewPassScreen(),
    ),
    GetPage(name: RoutesName.homeScreen, page: () => HomeScreen()),
    GetPage(
      name: RoutesName.transactionScreen,
      page: () => TransactionScreen(),
    ),
    GetPage(name: RoutesName.withdrawScreen, page: () => WithdrawScreen()),
    GetPage(
      name: RoutesName.withdrawPreviewScreen,
      page: () => WithdrawPreviewScreen(),
    ),
    GetPage(
      name: RoutesName.withdrawHistoryScreen,
      page: () => WithdrawHistoryScreen(),
    ),
    GetPage(
      name: RoutesName.flutterWaveWithdrawScreen,
      page: () => FlutterWaveWithdrawScreen(),
    ),
    GetPage(
      name: RoutesName.profileSettingScreen,
      page: () => ProfileSettingScreen(),
    ),
    GetPage(
      name: RoutesName.notificationPermissionScreen,
      page: () => NotificationPermissionScreen(),
    ),
    GetPage(
      name: RoutesName.editProfileScreen,
      page: () => EditProfileScreen(),
    ),
    GetPage(
      name: RoutesName.changePasswordScreen,
      page: () => ChangePasswordScreen(),
    ),
    GetPage(
      name: RoutesName.supportTicketListScreen,
      page: () => SupportTicketListScreen(),
    ),
    GetPage(
      name: RoutesName.supportTicketViewScreen,
      page: () => SupportTicketViewScreen(),
    ),
    GetPage(
      name: RoutesName.createSupportTicketScreen,
      page: () => CreateSupportTicketScreen(),
    ),
    GetPage(
      name: RoutesName.twoFaVerificationScreen,
      page: () => TwoFaVerificationScreen(),
    ),
    GetPage(
      name: RoutesName.identityVerificationScreen,
      page: () => IdentityVerificationScreen(),
    ),
    GetPage(
      name: RoutesName.verificationListScreen,
      page: () => VerificationListScreen(),
    ),
    GetPage(
      name: RoutesName.notificationScreen,
      page: () => NotificationScreen(),
    ),
    GetPage(
      name: RoutesName.merchantSettingScreen,
      page: () => MerchantSettingScreen(),
    ),
    GetPage(
      name: RoutesName.securityPinSetupScreen,
      page: () => SecurityPinSetupScreen(),
    ),
    GetPage(
      name: RoutesName.qrCodeScreen,
      page: () => QrCodeScreen(),
    ),
    GetPage(
      name: RoutesName.paymentSuccessScreen,
      page:
          () =>
              PaymentSuccessScreen(amount: '', currencySymbol: '', gateway: ''),
    ),
    GetPage(
      name: RoutesName.deleteAccountScreen,
      page: () => DeleteAccountScreen(),
    ),
    GetPage(
      name: RoutesName.voiceEntryScreen,
      page: () => const VoiceEntryScreen(),
    ),
    GetPage(
      name: RoutesName.transferMoneyScreen,
      page: () => const TransferMoneyScreen(),
    ),
    GetPage(
      name: RoutesName.addUdharScreen,
      page: () => const AddUdharScreen(),
    ),
    GetPage(
      name: RoutesName.customerListScreen,
      page: () => const CustomerListScreen(),
    ),
    GetPage(
      name: RoutesName.customerLedgerScreen,
      page: () {
        final args = Get.arguments ?? {};
        return CustomerLedgerScreen(
          customerId: (args['customerId'] ?? '').toString(),
          customerName: (args['customerName'] ?? '').toString(),
        );
      },
    ),
    GetPage(
      name: RoutesName.udharDashboardScreen,
      page: () => const UdharDashboardScreen(),
    ),
    GetPage(
      name: RoutesName.chatLedgerScreen,
      page: () {
        final args = Get.arguments ?? {};
        return ChatLedgerScreen(
          customerId: (args['customerId'] ?? '').toString(),
          customerName: (args['customerName'] ?? '').toString(),
        );
      },
    ),
  ];
}
