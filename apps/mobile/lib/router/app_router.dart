import 'package:go_router/go_router.dart';

import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/verify_phone_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/set_profile_screen.dart';
import '../features/auth/screens/category_screen.dart';
import '../features/home/screens/shell_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/notification_screen.dart';
import '../features/home/screens/profile_screen.dart';
import '../features/home/screens/chat_screen.dart';
import '../features/home/screens/create_community_screen.dart';

/// Defines every named route in the app and their order in the navigation stack.
///
/// Auth flow:   / → /login or /signup → /verify-phone → /otp → /set-profile → /category → /home
/// Main app:    ShellRoute wraps /home, /notification, /profile (shares bottom nav)
/// Overlays:    /chat and /create-community are pushed over the shell (no bottom nav)
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Auth routes (no bottom nav) ──────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/verify-phone',
      builder: (context, state) => const VerifyPhoneScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OtpScreen(),
    ),
    GoRoute(
      path: '/set-profile',
      builder: (context, state) => const SetProfileScreen(),
    ),
    GoRoute(
      path: '/category',
      builder: (context, state) => const CategoryScreen(),
    ),

    // ── Main-app shell (bottom nav shared across these three routes) ─────────
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/notification',
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // ── Full-screen overlay routes (no bottom nav) ───────────────────────────
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/create-community',
      builder: (context, state) => const CreateCommunityScreen(),
    ),
  ],
);
