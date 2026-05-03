import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Every color, size, and string used across the app lives here.
/// Widgets must NOT hardcode any values — always reference these constants.

// ─── Colors ───────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  /// Coral/terracotta: primary action color (buttons, nav bar, active tabs)
  static const Color primary = Color(0xFFE07355);

  /// Warm cream: background for auth screens
  static const Color background = Color(0xFFFAF5F0);

  /// Pure white: card surfaces, main-app screen backgrounds
  static const Color cardWhite = Color(0xFFFFFFFF);

  /// Near-black: headings and body copy
  static const Color textDark = Color(0xFF1A1A1A);

  /// Medium gray: secondary / supporting text
  static const Color textGray = Color(0xFF888888);

  /// Light gray: input border outlines
  static const Color inputBorder = Color(0xFFDDDDDD);

  /// Very light gray: input fill background
  static const Color inputFill = Color(0xFFF5F5F5);

  /// Step-progress bar: filled segment
  static const Color stepActive = Color(0xFF1A1A1A);

  /// Step-progress bar: unfilled segment
  static const Color stepInactive = Color(0xFFD8D8D8);

  /// Interest chip — selected background
  static const Color chipSelected = Color(0xFF1A1A1A);

  /// Interest chip — selected text color
  static const Color chipSelectedText = Color(0xFFFFFFFF);

  /// Interest chip — unselected border
  static const Color chipBorder = Color(0xFFCCCCCC);

  /// Discover category card: Badminton (green)
  static const Color categoryGreen = Color(0xFF8DD1A4);

  /// Discover category card: Coding (blue)
  static const Color categoryBlue = Color(0xFFADD8E6);

  /// Discover category card: Games (purple)
  static const Color categoryPurple = Color(0xFFBBADD8);

  /// Notification item left-border accent
  static const Color notifBorder = Color(0xFFE07355);

  /// Salmon placeholder for avatars / profile circles
  static const Color avatarSalmon = Color(0xFFE8A898);

  /// Subtle divider line
  static const Color divider = Color(0xFFEEEEEE);

  /// Liquid glass card background — white at 20% opacity
  static const Color glassBackground = Color(0x33FFFFFF);

  /// Liquid glass card border — white at 30% opacity
  static const Color glassBorder = Color(0x4DFFFFFF);
}

// ─── Sizes & Spacing ──────────────────────────────────────────────────────────
class AppSizes {
  AppSizes._();

  // Padding scale
  static const double paddingXS  = 4.0;
  static const double paddingS   = 8.0;
  static const double paddingM   = 16.0;
  static const double paddingL   = 24.0;
  static const double paddingXL  = 32.0;
  static const double paddingXXL = 48.0;

  // Border-radius scale
  static const double radiusS    = 8.0;
  static const double radiusM    = 14.0;
  static const double radiusL    = 22.0;
  static const double radiusXL   = 32.0;
  static const double radiusPill = 100.0;

  // Fixed component heights / sizes
  static const double buttonHeight      = 54.0;
  static const double inputHeight       = 52.0;
  static const double bottomNavHeight   = 68.0;
  static const double stepBarHeight     = 5.0;
  static const double cardThumbnailSize = 72.0;
  static const double avatarSmall       = 42.0;
  static const double avatarLarge       = 120.0;
  static const double categoryCardSize  = 90.0;
  static const double otpBoxSize        = 58.0;
  static const double iconSize          = 22.0;
  static const double coverImageHeight  = 200.0;

  // Font sizes
  static const double fontXS      = 11.0;
  static const double fontS       = 13.0;
  static const double fontM       = 15.0;
  static const double fontL       = 17.0;
  static const double fontXL      = 22.0;
  static const double fontXXL     = 28.0;
  static const double fontDisplay = 32.0;

  /// Blur sigma for BackdropFilter on liquid glass cards
  static const double glassBlurSigma = 15.0;
}

// ─── String Constants ─────────────────────────────────────────────────────────
class AppStrings {
  AppStrings._();

  static const String appName = 'ClubConnect';

  // Welcome screen
  static const String welcomeHeading   = 'Drop-in !';
  static const String welcomeTagline   = 'Best space to connect\nwith people';
  static const String welcomeLogin     = 'Login';
  static const String welcomeNoAccount = 'No Account? ';
  static const String welcomeSignUp    = 'Sign Up';

  // Login screen
  static const String loginTitle    = 'Login';
  static const String loginEmail    = 'Email *';
  static const String loginPassword = 'Password *';
  static const String loginNext     = 'Next';

  // Sign-up screen
  static const String signupHeading       = 'Create your ';
  static const String signupHeadingAccent = 'account';
  static const String signupEmail         = 'Email *';
  static const String signupPassword      = 'Password *';
  static const String signupConfirm       = 'Confirm Password *';
  static const String signupNext          = 'Next';

  // Verify phone screen
  static const String verifyHeading       = 'Verify your';
  static const String verifyHeadingAccent = 'Phone Number';
  static const String verifyPhoneLabel    = 'Phone No.*';
  static const String verifyHint =
      'For your account security, ClubConnect will send an SMS text '
      'message with a unique verification code to the phone number provided.';
  static const String verifyNext = 'Next';

  // OTP screen
  static const String otpHeading       = 'Enter ';
  static const String otpHeadingAccent = 'OTP';
  static const String otpSubtitle =
      "We've sent a text message to your phone!\n"
      'Please enter the 4-digit here to continue.';
  static const String otpNoCode = "Didn't receive code? ";
  static const String otpResend = 'Resend now';
  static const String otpNext   = 'Next';

  // Set-profile screen
  static const String setProfileHeading       = 'Complete ';
  static const String setProfileHeadingAccent = 'Profile !';
  static const String setProfileDisplayName   = 'Display Name*';
  static const String setProfileAboutMe       = 'About me (optional)';
  static const String setProfileNext          = 'Next';

  // Category / interests screen
  static const String categoryHeading    = 'What sparks you?';
  static const String categorySubtitle   = "Pick up to 3. We'll surface live rooms in these.";
  static const String categoryGetStarted = 'Get Started!';

  // Home screen
  static const String homeWelcome    = 'Welcome, ';
  static const String homeUsername   = '[Username]';
  static const String homeSearchHint = 'Search';
  static const String tabDiscover    = 'Discover';
  static const String tabMyClub      = 'My club';
  static const String tabTrending    = 'Trending';

  // Bottom navigation bar
  static const String navHome         = 'Home';
  static const String navNotification = 'Notification';
  static const String navYou          = 'You';

  // Notification / Inbox screen
  static const String inboxTitle   = 'Inbox';
  static const String inboxRecent  = 'Recent';
  static const String inboxOld     = '2 days ago';
  static const String notifMention = ' mentioned you in ';
  static const String notifBody    = '@name Lorem ipsum dolor sit amet';

  // Chat screen
  static const String chatToday     = 'Today';
  static const String chatInputHint = 'Emit...';

  // Create Community screen
  static const String createTitle         = 'Host';
  static const String createNameLabel     = 'Community Name';
  static const String createNameHint      = 'Enter Community Name';
  static const String createAboutLabel    = 'About Community';
  static const String createAboutHint     = 'Enter Community description';
  static const String createCategoryLabel = 'Category';
  static const String createRulesLabel    = 'Community Rules';
  static const String createRulesHint     = '1. Type your rule';
  static const String createAddRule       = '+ Add more rules';
  static const String createButton        = 'Create';

  // Profile screen
  static const String profileRateUser  = 'Rate this user';
  static const String profileAbout     = 'About me';
  static const String profileInterests = 'Interests';
  static const String profileComments  = 'Comments';
  static const String profileViewAll   = 'view all';
  static const String profileBio =
      "Hello everyone, I'm seeking for friend to play Badminton with me !";
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  /// Inter — body text, labels, hints, form fields, buttons, supporting copy
  static TextStyle body({
    double fontSize = AppSizes.fontM,
    FontWeight fontWeight = FontWeight.normal,
    Color color = AppColors.textDark,
    FontStyle fontStyle = FontStyle.normal,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontStyle: fontStyle,
        height: height,
      );

  /// Instrument Serif — screen titles, headings, display text
  static TextStyle title({
    double fontSize = AppSizes.fontXXL,
    FontWeight fontWeight = FontWeight.bold,
    Color color = AppColors.textDark,
    FontStyle fontStyle = FontStyle.normal,
    double? height,
  }) =>
      GoogleFonts.instrumentSerif(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontStyle: fontStyle,
        height: height,
      );
}
