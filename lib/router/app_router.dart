import 'package:go_router/go_router.dart';

import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/verify_phone_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/set_profile_screen.dart';
import '../features/auth/screens/category_screen.dart';
import '../features/auth/screens/community_standards_screen.dart';
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
import '../models/event_detail_args.dart';
import '../features/admin/screens/admin_reports_screen.dart';
import '../features/admin/screens/admin_report_detail_screen.dart';
import '../features/community/screens/bill_summary_screen.dart';
import '../features/community/screens/bill_payment_screen.dart';
import '../features/community/screens/payment_success_screen.dart';
import '../features/community/screens/create_bill_screen.dart';
import '../models/smart_bill_model.dart';
import '../models/bill_payment_args.dart';
import '../models/smart_pay_bill_args.dart';
import '../features/auth/screens/banned_screen.dart';
import '../models/chat_args.dart';
import '../models/community_model.dart';
import '../models/profile_args.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import '../features/admin/models/report_model.dart';
import 'package:flutter/material.dart';

GoRouter createAppRouter(AppAuthProvider authProvider) {
  String? redirect(BuildContext context, GoRouterState state) {
    // During Google registration the web popup briefly signs in to capture the
    // credential before signing out again. Allow onboarding routes while this
    // flag is set to prevent the guard from bouncing the user to /home.
    if (authProvider.pendingGoogleRegistration) return null;

    final signedIn = authProvider.user != null;

    final authRoutes = {
      '/',
      '/login',
      '/signup',
      '/verify-phone',
      '/otp',
      '/set-profile',
      '/category',
      '/community-standards',
    };

    final location = state.matchedLocation;

    final isAuthRoute = authRoutes.contains(location);

    // Unauthenticated user on a protected route → send to landing page, not login.
    if (!signedIn && !isAuthRoute) {
      return '/';
    }

    if (signedIn && isAuthRoute) {
      return '/home';
    }

    if (signedIn && authProvider.isBanned && location != '/banned') {
      return '/banned';
    }

    if (signedIn && !authProvider.isBanned && location == '/banned') {
      return '/home';
    }

    if (signedIn && location.startsWith('/admin')) {
      if (authProvider.role != 'admin') return '/home';
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
          return CategoryScreen(displayName: extra?['displayName'] as String?);
        },
      ),
      GoRoute(
        path: '/community-standards',
        builder: (context, state) => const CommunityStandardsScreen(),
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
            targetMessageId: args?.targetMessageId,
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
          final args = state.extra as EventDetailArgs?;
          if (args == null) return const SizedBox.shrink();
          return EventDetailScreen(
              event: args.event, communityId: args.communityId);
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
            communityId: args.communityId,
          );
        },
      ),

      // ── Bill / payment flow ───────────────────────────────────────────────────
      GoRoute(
        path: '/create-bill',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return CreateBillScreen(
            communityId: args['communityId'] as String? ?? '',
            eventId: args['eventId'] as String? ?? '',
            eventName: args['eventName'] as String? ?? '',
            existingBill: args['bill'] as SmartBillModel?,
            existingItems: args['items'] as List<SmartBillItemModel>?,
            isEdit: args['isEdit'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/bill-summary',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return BillSummaryScreen(
            communityId:       args['communityId']       as String? ?? '',
            eventId:           args['eventId']           as String? ?? '',
            billId:            args['billId']            as String? ?? '',
            isCurrentUserHost: args['isCurrentUserHost'] as bool?   ?? false,
          );
        },
      ),
      GoRoute(
        path: '/bill-payment',
        pageBuilder: (context, state) {
          final args = state.extra as SmartPayBillArgs?;
          if (args == null) return const NoTransitionPage(child: SizedBox.shrink());
          return CustomTransitionPage(
            child: BillPaymentScreen(args: args),
            transitionsBuilder: (_, animation, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
      ),
      GoRoute(
        path: '/payment-success',
        pageBuilder: (context, state) {
          final args = state.extra as BillPaymentArgs?;
          if (args == null) return const NoTransitionPage(child: SizedBox.shrink());
          return CustomTransitionPage(
            child: PaymentSuccessScreen(args: args),
            transitionsBuilder: (_, animation, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
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
          final report = state.extra as AdminReportModel;
          return AdminReportDetailScreen(report: report);
        },
      ),

      GoRoute(
        path: '/banned',
        builder: (context, state) => const BannedScreen(),
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
