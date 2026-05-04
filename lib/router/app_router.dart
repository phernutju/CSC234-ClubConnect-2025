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
import '../features/home/screens/my_profile_screen.dart';
import '../features/home/screens/other_profile_screen.dart';
import '../features/home/screens/chat_screen.dart';
import '../features/home/screens/create_community_screen.dart';
import '../models/chat_args.dart';
import '../models/profile_args.dart';
import '../constants/app_constants.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Auth routes ──────────────────────────────────────────────────────────
    GoRoute(path: '/',          builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/login',     builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup',    builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/verify-phone', builder: (_, __) => const VerifyPhoneScreen()),
    GoRoute(path: '/otp',       builder: (_, __) => const OtpScreen()),
    GoRoute(path: '/set-profile', builder: (_, __) => const SetProfileScreen()),
    GoRoute(path: '/category',  builder: (_, __) => const CategoryScreen()),

    // ── Main-app shell ───────────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(path: '/home',         builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/notification', builder: (_, __) => const NotificationScreen()),
        GoRoute(path: '/profile',      builder: (_, __) => const MyProfileScreen()),
      ],
    ),

    // ── Overlay routes (no bottom nav) ───────────────────────────────────────
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final args = state.extra as ChatArgs?;
        return ChatScreen(
          communityId:   args?.communityId   ?? '',
          communityName: args?.communityName ?? AppStrings.chatCommunityName,
          memberCount:   args?.memberCount   ?? '',
        );
      },
    ),
    GoRoute(
      path: '/create-community',
      builder: (_, __) => const CreateCommunityScreen(),
    ),
    GoRoute(
      path: '/other-profile',
      builder: (context, state) {
        final args = state.extra as ProfileArgs?;
        return OtherProfileScreen(
          userId:        args?.userId        ?? '',
          username:      args?.username      ?? AppStrings.rateTestUsername,
          communityName: args?.communityName ?? AppStrings.rateTestCommunity,
          communityId:   '',
        );
      },
    ),
  ],
);
