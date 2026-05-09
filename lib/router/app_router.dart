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
import '../features/community/screens/edit_community_screen.dart';
import '../features/community/screens/events_screen.dart';
import '../features/community/screens/create_event_screen.dart';
import '../features/community/screens/event_detail_screen.dart';
import '../features/community/screens/event_chat_screen.dart';
import '../features/community/screens/edit_event_screen.dart';
import '../models/event_model.dart';
import '../models/event_chat_args.dart';
import '../features/admin/screens/admin_reports_screen.dart';
import '../features/admin/screens/admin_report_detail_screen.dart';
import '../models/chat_args.dart';
import '../models/community_model.dart';
import '../models/profile_args.dart';
import '../models/report_model.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import 'package:flutter/material.dart';

GoRouter createAppRouter(AppAuthProvider authProvider) {
    String? redirect(BuildContext context, GoRouterState state) {
    final signedIn = authProvider.user != null;

    final authRoutes = {
      '/',
      '/login',
      '/signup',
      '/verify-phone',
      '/otp',
      '/set-profile',
      '/category',
    };

    final location = state.matchedLocation;

    final isAuthRoute = authRoutes.contains(location);

    if (!signedIn && !isAuthRoute) {
      return '/login';
    }

    if (signedIn && isAuthRoute) {
      return '/home';
    }

    return null;
  }

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: redirect,
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
            builder: (context, state) => const MyProfileScreen(),
          ),
        ],
      ),

      // ── Full-screen overlay routes (no bottom nav) ─────────────────────────
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final args = state.extra as ChatArgs?;
          return ChatScreen(
            communityId: args?.communityId ?? '',
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
        path: '/edit-community',
        builder: (context, state) {
          final community = state.extra as CommunityModel?;
          if (community == null) return const SizedBox.shrink();
          return EditCommunityScreen(community: community);
        },
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) {
          final args = state.extra as ChatArgs?;
          return EventsScreen(
            communityId: args?.communityId ?? '',
            communityName: args?.communityName ?? AppStrings.chatCommunityName,
            memberCount: args?.memberCount ?? '',
          );
        },
      ),
      GoRoute(
        path: '/create-event',
        builder: (context, state) {
          final communityId = state.extra as String? ?? '';
          return CreateEventScreen(communityId: communityId);
        },
      ),
      GoRoute(
        path: '/edit-event',
        builder: (context, state) {
          final event = state.extra as EventModel?;
          if (event == null) return const SizedBox.shrink();
          return EditEventScreen(event: event);
        },
      ),
      GoRoute(
        path: '/event-detail',
        builder: (context, state) {
          final event = state.extra as EventModel?;
          if (event == null) return const SizedBox.shrink();
          return EventDetailScreen(event: event);
        },
      ),
      GoRoute(
        path: '/event-chat',
        builder: (context, state) {
          final args = state.extra as EventChatArgs?;
          if (args == null) return const SizedBox.shrink();
          return EventChatScreen(
            event: args.event,
            memberCount: args.memberCount,
          );
        },
      ),

      // ── Admin routes ──────────────────────────────────────────────────────────
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

      GoRoute(
        path: '/other-profile',
        builder: (context, state) {
          final args = state.extra as ProfileArgs?;
          return OtherProfileScreen(
            userId: args?.userId ?? '',
            username: args?.username ?? AppStrings.rateTestUsername,
            communityName: args?.communityName ?? AppStrings.rateTestCommunity,
            communityId: args?.communityId ?? AppStrings.rateTestCommunityId,
          );
        },
      ),
    ],
  );
}
