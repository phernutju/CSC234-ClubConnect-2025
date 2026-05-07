import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/community_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/category_provider.dart';
import 'providers/rating_provider.dart';
import 'providers/report_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ClubConnectApp());
}

class ClubConnectApp extends StatelessWidget {
  ClubConnectApp({super.key});

  final AppAuthProvider _authProvider = AppAuthProvider();
  late final GoRouter _appRouter = createAppRouter(_authProvider);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp.router(
        title: 'ClubConnect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          // Suppress the default blue focus/cursor color across the app
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE07355),
            brightness: Brightness.light,
          ),
          // Remove the Material splash / ink-well ripple in favor of custom GestureDetectors
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          appBarTheme: const AppBarTheme(
            toolbarHeight: AppSizes.appBarHeight,
          ),
        ),
        routerConfig: _appRouter,
      ),
    );
  }
}
