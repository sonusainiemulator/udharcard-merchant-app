
import 'package:paysecure/controllers/pin_reset_controller.dart';

import '../merchant_setting_controller.dart';
import 'controller_index.dart';

class InitBindings implements Bindings {
  @override
  void dependencies() {
    Get.put(AppController());
    Get.put(ProfileController());
    Get.put(PushNotificationController());

    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    Get.lazyPut<BottomNavController>(() => BottomNavController(), fenix: true);
    Get.lazyPut<SupportTicketController>(
      () => SupportTicketController(),
      fenix: true,
    );
    Get.lazyPut<TransactionController>(
      () => TransactionController(),
      fenix: true,
    );
    Get.lazyPut<NotificationSettingsController>(
      () => NotificationSettingsController(),
      fenix: true,
    );
    Get.lazyPut<VerificationController>(
      () => VerificationController(),
      fenix: true,
    );
    Get.lazyPut<MerchantSettingController>(
      () => MerchantSettingController(),
      fenix: true,
    );
    Get.lazyPut<PinResetController>(
      () => PinResetController(),
      fenix: true,
    );
    Get.lazyPut<UdharController>(
      () => UdharController(),
      fenix: true,
    );
    Get.lazyPut<WorkListController>(
      () => WorkListController(),
      fenix: true,
    );
    Get.lazyPut<SubscriptionController>(
      () => SubscriptionController(),
      fenix: true,
    );
  }
}
