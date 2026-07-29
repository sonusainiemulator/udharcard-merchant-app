import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:paysecure/firebase_options.dart';
import 'package:paysecure/utils/services/custom_error.dart';
import 'controllers/app_controller.dart';
import 'controllers/bindings/bindings.dart';
import 'notification_service/notification_service.dart';
import 'routes/routes_helper.dart';
import 'routes/routes_name.dart';
import 'themes/themes.dart';
import 'utils/app_constants.dart';
import 'utils/services/localstorage/init_hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init attempt error: $e");
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (err) {
      debugPrint("Firebase init fallback error: $err");
    }
  }
  await initHive();
  _initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Create a custom 404 error page to replace Flutter's default red error screen.
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      String errorString = errorDetails.exceptionAsString();
      String stackTrace = errorDetails.stack.toString();
      // Check if the error involves GetBuilder
      if (errorString.contains('GetBuilder') ||
          stackTrace.contains('GetBuilder') ||
          errorString.contains('Scaffold')) {
        return CustomError(errorDetails: errorDetails);
      } else {
        // Use the default error widget for other cases
        return kDebugMode
            ? ErrorWidget(errorDetails.exception)
            : Center(
              child: Image.asset(
                '$rootImageDir/404.png',
                height: 120.h,
                width: double.maxFinite,
                fit: BoxFit.cover,
              ),
            );
      }
    };

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          initialBinding: InitBindings(),
          themeMode: Get.find<AppController>().themeManager(),
          initialRoute: RoutesName.INITIAL,
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 220),
          getPages: RouteHelper.routes(),
          builder: (BuildContext context, Widget? widget) {
            return widget ?? Container(child: Text("Widget is null"));
          },
        );
      },
    );
  }
}

_initializeApp() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    throw Exception('Error loading .env file: $e');
  }
  await Future.wait([
    LocalNotificationService().initNotification(),
    Future.delayed(const Duration(milliseconds: 400)),
  ]);
}
