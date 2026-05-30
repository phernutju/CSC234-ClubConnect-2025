import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:csc234_clubconnect/providers/auth_provider.dart';
import 'package:csc234_clubconnect/providers/category_provider.dart';
import 'package:csc234_clubconnect/providers/community_provider.dart';
import 'package:csc234_clubconnect/providers/event_provider.dart';
import 'package:csc234_clubconnect/providers/profile_provider.dart';
import 'package:csc234_clubconnect/providers/rating_provider.dart';
import 'package:csc234_clubconnect/providers/report_provider.dart';
import 'fake_providers.dart';

/// Wraps [child] in all required providers + a minimal GoRouter.
/// Override individual providers via the named parameters.
Widget makeTestApp({
  required Widget child,
  FakeAuthProvider? auth,
  FakeCommunityProvider? community,
  FakeEventProvider? event,
  FakeProfileProvider? profile,
  FakeReportProvider? report,
  FakeCategoryProvider? category,
  FakeRatingProvider? rating,
}) {
  final a = auth ?? FakeAuthProvider();
  final c = community ?? FakeCommunityProvider();
  final e = event ?? FakeEventProvider();
  final p = profile ?? FakeProfileProvider();
  final r = report ?? FakeReportProvider();
  final cat = category ?? FakeCategoryProvider();
  final rat = rating ?? FakeRatingProvider();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => child),
      GoRoute(path: '/login', builder: (_, __) => _stub('login')),
      GoRoute(path: '/signup', builder: (_, __) => _stub('signup')),
      GoRoute(path: '/verify-phone', builder: (_, __) => _stub('verify-phone')),
      GoRoute(path: '/otp', builder: (_, __) => _stub('otp')),
      GoRoute(path: '/set-profile', builder: (_, __) => _stub('set-profile')),
      GoRoute(path: '/category', builder: (_, __) => _stub('category')),
      GoRoute(
          path: '/community-standards',
          builder: (_, __) => _stub('community-standards')),
      GoRoute(path: '/home', builder: (_, __) => _stub('home')),
      GoRoute(
          path: '/notification', builder: (_, __) => _stub('notification')),
      GoRoute(path: '/profile', builder: (_, __) => _stub('profile')),
      GoRoute(path: '/chat', builder: (_, __) => _stub('chat')),
      GoRoute(
          path: '/create-community',
          builder: (_, __) => _stub('create-community')),
      GoRoute(
          path: '/edit-community',
          builder: (_, __) => _stub('edit-community')),
      GoRoute(path: '/events', builder: (_, __) => _stub('events')),
      GoRoute(
          path: '/create-event', builder: (_, __) => _stub('create-event')),
      GoRoute(path: '/edit-event', builder: (_, __) => _stub('edit-event')),
      GoRoute(
          path: '/event-detail', builder: (_, __) => _stub('event-detail')),
      GoRoute(path: '/event-chat', builder: (_, __) => _stub('event-chat')),
      GoRoute(
          path: '/create-bill', builder: (_, __) => _stub('create-bill')),
      GoRoute(
          path: '/bill-summary', builder: (_, __) => _stub('bill-summary')),
      GoRoute(
          path: '/bill-payment', builder: (_, __) => _stub('bill-payment')),
      GoRoute(
          path: '/payment-success',
          builder: (_, __) => _stub('payment-success')),
      GoRoute(path: '/banned', builder: (_, __) => _stub('banned')),
      GoRoute(
          path: '/admin-reports',
          builder: (_, __) => _stub('admin-reports')),
      GoRoute(
          path: '/admin-report-detail',
          builder: (_, __) => _stub('admin-report-detail')),
      GoRoute(
          path: '/global-events',
          builder: (_, __) => _stub('global-events')),
      GoRoute(
          path: '/other-profile',
          builder: (_, __) => _stub('other-profile')),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppAuthProvider>.value(value: a),
      ChangeNotifierProvider<CommunityProvider>.value(value: c),
      ChangeNotifierProvider<EventProvider>.value(value: e),
      ChangeNotifierProvider<ProfileProvider>.value(value: p),
      ChangeNotifierProvider<ReportProvider>.value(value: r),
      ChangeNotifierProvider<CategoryProvider>.value(value: cat),
      ChangeNotifierProvider<RatingProvider>.value(value: rat),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Widget _stub(String name) =>
    Scaffold(body: Center(child: Text('stub:$name')));
