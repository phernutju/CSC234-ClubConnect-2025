import 'package:flutter/material.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ClubConnectApp());
}

/// Root widget — wires up GoRouter and a minimal Material theme.
/// No custom colors here; all theme tokens live in app_constants.dart.
class ClubConnectApp extends StatelessWidget {
  const ClubConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
      ),
      routerConfig: appRouter,
    );
  }
}
