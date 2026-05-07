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
import '../features/profile/screens/my_profile_screen.dart';
import '../features/profile/screens/other_profile_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/community/screens/create_community_screen.dart';
import '../models/chat_args.dart';
import '../models/community_model.dart';
import '../models/profile_args.dart';
import '../constants/app_constants.dart';
import '../features/admin/screens/admin_reports_screen.dart';
import '../features/admin/screens/admin_report_detail_screen.dart';
import '../features/admin/models/report_model.dart';

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
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SetProfileScreen(
          googleDisplayName: extra?['googleDisplayName'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/category',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CategoryScreen(
          displayName: extra?['displayName'] as String?,
        );
      },
    ),

    // ── Main-app shell (bottom nav shared across these three routes) ─────────
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return HomeScreen(
              displayName: extra?['displayName'] as String?,
              interests: (extra?['interests'] as List?)?.cast<String>() ?? const [],
            );
          },
        ),
        GoRoute(
          path: '/notification',
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const MyProfileScreen(),
        ),
      ],
    ),

    // ── Full-screen overlay routes (no bottom nav) ───────────────────────────
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final args = state.extra as ChatArgs?;
        return ChatScreen(
          communityName: args?.communityName ?? AppStrings.chatCommunityName,
          memberCount: args?.memberCount ?? '',
        );
      },
    ),
    GoRoute(
      path: '/create-community',
      builder: (context, state) => const CreateCommunityScreen(),
    ),

    GoRoute(
      path: '/other-profile',
      builder: (context, state) {
        final args = state.extra as ProfileArgs;
        return OtherProfileScreen(
          username: args.username,
          communityName: args.communityName,
        );
      },
    ),
    GoRoute(
      path: '/edit-community',
      builder: (context, state) {
        final community = state.extra as CommunityModel;
        return CreateCommunityScreen(
          isEditMode: true,
          existingCommunity: community,
        );
      },
    ),

    // ── Admin routes ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminReportsScreen(),
    ),
    GoRoute(
      path: '/admin-reports',
      builder: (context, state) => const AdminReportsScreen(),
    ),
    GoRoute(
      path: '/admin-report-detail',
      builder: (context, state) {
        final report = state.extra as ReportModel;
        return AdminReportDetailScreen(report: report);
      },
    ),
  ],
);
