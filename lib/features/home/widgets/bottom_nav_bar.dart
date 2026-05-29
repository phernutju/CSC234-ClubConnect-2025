import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: const Color(0xFFFF6B4A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        iconSize: 28,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 28), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications, size: 28), label: 'Notification'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 28), label: 'You'),
        ],
      ),
    );
  }
}
