import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/bindings/bindings.dart';
import 'package:paysecure/controllers/profile_controller.dart';
import 'package:paysecure/routes/routes_helper.dart';
import 'package:paysecure/routes/routes_name.dart';
import 'package:paysecure/views/screens/profile/edit_profile_screen.dart';
import 'package:paysecure/views/screens/profile/profile_setting_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EditProfileScreen pumps without setState during build', (tester) async {
    Get.testMode = true;
    InitBindings().dependencies();

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => GetMaterialApp(
          home: const EditProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('Navigating from ProfileSettingScreen to EditProfileScreen causes no setState during build error', (tester) async {
    Get.testMode = true;
    InitBindings().dependencies();
    final profileCtrl = Get.find<ProfileController>();
    profileCtrl.profileList.clear();

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => GetMaterialApp(
          initialRoute: RoutesName.profileSettingScreen,
          getPages: RouteHelper.routes(),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(ProfileSettingScreen), findsOneWidget);

    Get.to(() => const EditProfileScreen());
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });
}
