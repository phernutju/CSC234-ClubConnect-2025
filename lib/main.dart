import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/community_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/category_provider.dart';
import 'providers/attendee_provider.dart';
import 'providers/event_provider.dart';
import 'providers/smart_bill_provider.dart';
import 'providers/rating_provider.dart';
import 'providers/report_provider.dart';
import 'router/app_router.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Disable Crashlytics collection in debug builds so local crashes
    // don't pollute the production dashboard.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    // Forward Flutter framework errors to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Forward platform/engine errors (outside the Flutter framework) to Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    runApp(const ClubConnectApp());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

/// Root widget — wires up GoRouter and a minimal Material theme.
/// No custom colors here; all theme tokens live in app_constants.dart.
class ClubConnectApp extends StatelessWidget {
  const ClubConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = AppAuthProvider();
    final appRouter = createAppRouter(authProvider);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RatingProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => SmartBillProvider()),
        ChangeNotifierProvider(create: (_) => AttendeeProvider()),
      ],
      child: MaterialApp.router(
        title: 'ClubConnect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          // Suppress the default blue focus/cursor color across the app
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF6B4A),
            brightness: Brightness.light,
          ),
          // Remove the Material splash / ink-well ripple in favor of custom GestureDetectors
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          appBarTheme: const AppBarTheme(
            toolbarHeight: AppSizes.appBarHeight,
          ),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
