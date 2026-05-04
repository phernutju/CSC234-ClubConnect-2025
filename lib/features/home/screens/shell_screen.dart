import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/bottom_nav_bar.dart';

/// Persistent shell that wraps every main-app screen.
/// Renders the [AppBottomNavBar] below the [child] widget provided
/// by GoRouter's ShellRoute.
///
/// When a nav item is tapped, this widget calls context.go() to switch
/// routes while keeping the shell (and bottom nav) alive.
class ShellScreen extends StatelessWidget {
  /// The current page widget rendered by GoRouter inside the shell
  final Widget child;

  const ShellScreen({super.key, required this.child});

  /// Maps the current route path to a bottom-nav index.
  int _indexFromLocation(String location) {
    if (location.startsWith('/notification')) return 1;
    if (location.startsWith('/profile'))      return 2;
    return 0; // default: Home
  }

  /// Routes to the correct path when a nav item is tapped.
  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 1:
        context.go('/notification');
      case 2:
        context.go('/profile');
      default:
        context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine active tab by reading the current route location
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: child,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }
}
