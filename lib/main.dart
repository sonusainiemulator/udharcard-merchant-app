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

  // Protect against unhandled Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("FlutterError caught: ${details.exceptionAsString()}");
  };

  // Safe Firebase Initialization
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

  // Safe local storage initialization
  try {
    await initHive();
  } catch (e) {
    debugPrint("Hive init error in main: $e");
  }

  // Safe environment variables loading
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("dotenv load warning (using defaults): $e");
  }

  // Register AppController
  try {
    Get.put(AppController(), permanent: true);
  } catch (e) {
    debugPrint("AppController put error: $e");
  }

  // Immediately launch the UI so iOS watchdog never terminates app
  runApp(const MyApp());

  // Non-blocking background service initialization post-frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initBackgroundServices();
  });
}

void _initBackgroundServices() async {
  try {
    await LocalNotificationService().initNotification();
  } catch (e) {
    debugPrint("LocalNotificationService init error: $e");
  }
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
                height: 120.0,
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
            return widget ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}

