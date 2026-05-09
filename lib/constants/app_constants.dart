import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Every color, size, and string used across the app lives here.
/// Widgets must NOT hardcode any values — always reference these constants.

// ─── Colors ───────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  /// Coral/terracotta: primary action color (buttons, nav bar, active tabs)
  static const Color primary = Color(0xFFFF6B4A);

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
  static const Color chipSelected = Color(0xFFFF6B4A);

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
  static const Color notifBorder = Color(0xFFFF6B4A);

  /// Salmon placeholder for avatars / profile circles
  static const Color avatarSalmon = Color(0xFFE8A598);

  /// Subtle divider line
  static const Color divider = Color(0xFFEEEEEE);

  /// Liquid glass card background — white at 20% opacity
  static const Color glassBackground = Color(0x33FFFFFF);

  /// Liquid glass card border — white at 30% opacity
  static const Color glassBorder = Color(0x4DFFFFFF);

  /// Sent message bubble background
  static const Color sentBubble     = Color(0xFFF5EBE8);
  static const Color flaggedBubble  = Color(0xFFFF6868);
  static const Color warningBoxBg   = Color(0xFFD9D9D9);
  static const Color banBannerBg    = Color(0xFFF7F5F2);

  /// Report modal accent — coral red for "Report" text, Post button, close button
  static const Color reportAccent = Color(0xFFFF6B4A);

  /// Report modal description field background
  static const Color reportFieldBg = Color(0xFFE8DFD8);

  /// Report modal subtitle text ("Your report is anonymous…")
  static const Color reportSubtitleGray = Color(0xFF837A7A);

  /// Report modal form labels ("Reason", "Description")
  static const Color reportLabelGray = Color(0xFF797979);

  /// Chat page scaffold background
  static const Color chatBackground = Color(0xFFFFFCF8);

  /// Form field underline and placeholder text (Create Community)
  static const Color fieldPlaceholder = Color(0xFFBABABA);

  /// Profile header gradient — start color (salmon)
  static const Color profileHeaderStart = Color(0xFFFFB199);

  /// Profile header gradient — end color (peach cream)
  static const Color profileHeaderEnd = Color(0xFFFFD5BE);

  /// Profile star rating icon
  static const Color starColor = Color(0xFFFFC963);

  /// Comment timestamp meta text ("1 hr ago · from …")
  static const Color commentMeta = Color(0xFFBABABA);

  /// Comment body text
  static const Color commentBody      = Color(0xFF837A7A);
  static const Color dialogHighlight  = Color(0x26FF6B4A); // #FF6B4A @ ~15% opacity

  /// Create Community page background — warm off-white
  static const Color createBackground = Color(0xFFFFF6EE);

  /// Cover image inner-shadow vignette overlay
  static const Color coverShadowEdge = Color(0x55000000);

  /// Rate User modal — user info card border and comment field border
  static const Color rateCardBorder = Color(0xFFE8DFD8);

  /// Rate User modal — unselected star icon color
  static const Color rateStarEmpty = Color(0xFFE8DFD8);

  /// Rate User modal — star box fill background
  static const Color rateStarFill = Color(0xFFFFF6EE);

  /// View All Reviews — per-star distribution bar filled portion (green)
  static const Color reviewBarFilled = Color(0xFF8CD9A7);

  /// View All Reviews — empty star icon color (near-black for contrast)
  static const Color reviewStarEmpty = Color(0xFF1D1B20);
  
  /// Alert text/icon color (e.g., Report button dropdown)
  static const Color alertRed = Color(0xFFFF6868);

  /// Edit Profile save button — green
  static const Color saveButtonColor = Color(0xFF58B97A);

  /// Host info card — rating score text
  static const Color hostRatingColor = Color(0xFF6B5F66);

  // Member sheet
  static const Color memberLightBg    = Color(0xFFFAFAFA);
  static const Color memberSheetHandle = Color(0xFFDDDDDD);
  static const Color memberCloseBtnBg  = Color(0xFFF2F2F2);
  static const Color memberRoleText    = Color(0xFF888888);
  static const Color memberAdminRowBg  = Color(0xFFFFF3EF);
  static const Color memberRowDivider  = Color(0xFFEEEEEE);
  static const Color onlineDot         = Color(0xFF4CAF50);
  static const Color memberKickBtnBg   = Color(0xFFFFEEEE);
  static const Color kickButton        = Color(0xFFFF4444);
  static const Color kickModalCircle   = Color(0xFFFFEEEE);
  static const Color kickModalNameGray = Color(0xFF888888);
  static const Color kickModalNo       = Color(0xFFF2F2F2);
  static const Color kickModalYes      = Color(0xFFFF4444);
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
  static const double radiusPill    = 100.0;

  // Chat bubble corners: main radius + small "tail" radius on the sender corner
  static const double radiusBubble     = 18.0;
  static const double radiusBubbleTail =  4.0;

  // Chat image message dimensions
  static const double chatImageMaxHeight = 200.0;

  // Report modal fixed dimensions
  static const double reportModalWidth      = 296.0;
  static const double reportModalHeight     = 458.0;
  static const double reportDescFieldHeight =  36.0;

  // Long-press popup menu dimensions (compact floating card near the bubble)
  static const double popupMenuWidth      =  94.0;
  static const double popupMenuItemHeight =  22.0;
  static const double popupMenuFontSize   =  12.0;
  static const double popupMenuIconSize   =  14.0;

  // App bar
  static const double appBarHeight = 64.0;

  // Fixed component heights / sizes
  static const double buttonHeight      = 56.0;
  static const double inputHeight       = 52.0;
  static const double bottomNavHeight   = 68.0;
  static const double stepBarHeight     = 5.0;
  static const double cardThumbnailSize = 72.0;
  static const double avatarSmall       = 42.0;
  static const double avatarLarge       = 120.0;
  static const double notifBorderWidth  =  2.0;
  static const double inboxDividerWidth =  1.0;
  static const double categoryCardSize  = 90.0;
  static const double otpBoxSize        = 58.0;
  static const double iconSize          = 22.0;
  static const double chatMenuHeight    = 105.0;
  static const double chatMenuIconSize  =  24.0;
  static const double warningBoxWidth   = 329.0;
  static const double warningBoxHeight  =  57.0;
  static const double warningBoxRadius  =   5.0;
  static const double banBannerHeight   =  40.0;
  static const double coverImageHeight  = 200.0;

  // Fixed component heights for Create Community screen
  static const double createButtonWidth  = 327.0;
  static const double createButtonHeight =  50.0;
  static const double tooltipCardWidth   = 200.0;
  static const double tooltipCardHeight  = 120.0;
  static const double tooltipPadding     =  12.0;
  static const double tooltipIconSize    =  19.0;
  static const double fieldBorderWidth   =   2.0;

  // Default rating shown before any reviews are submitted
  static const double defaultRating = 5.0;

  // View All Reviews modal
  static const double reviewModalHeight   = 575.0;
  static const double reviewSummaryHeight = 125.0;
  static const double reviewMiniStarSize  =  11.0;
  static const double reviewBarHeight     =   4.0;
  static const double reviewItemSpacing   =  12.0;

  // Rate User modal fixed dimensions
  static const double rateModalWidth         = 296.0;
  static const double rateModalRadius        =  16.0;
  static const double rateUserCardWidth      = 266.0;
  static const double rateUserCardHeight     = 132.0;
  static const double rateUserAvatarSize     =  54.0;
  static const double rateStarBoxSize        =  41.0;
  static const double rateStarBoxRadius      =   8.0;
  static const double rateStarIconSize       =  18.0;
  static const double ratePostButtonWidth    = 245.0;
  static const double ratePostButtonHeight   =  38.0;
  static const double rateCommentFieldHeight =  36.0;
  static const double rateCloseButtonSize    =  28.0;

  // Profile screen fixed dimensions
  static const double profileHeaderHeight = 200.0;
  static const double interestChipWidth   = 108.0;
  static const double interestChipHeight  =  35.0;
  static const double interestChipRadius  =  64.0;
  static const double starIconSize        =  13.0;
  static const double ratingStarSize      =  32.0;
  static const double commentBorderWidth  =   3.0;

  // Edit Profile save button
  static const double saveButtonWidth  = 67.0;
  static const double saveButtonHeight = 18.0;

  // Camera overlay button on avatar and cover photo in edit mode
  static const double profileCameraButtonSize = 28.0;

  // Create Community — minimum character counts for validation
  static const int createNameMinChars  = 1;
  static const int createAboutMinChars = 1;

  // Home screen — community card
  static const double clubCardRadius       = 16.0;
  static const double clubThumbnailSize    = 60.0;
  static const double clubArrowSize        = 12.0;
  static const double clubCardBorderWidth  =  1.0;

  // Community Info Modal
  static const double communityModalWidth      = 296.0;
  static const double communityInfoCoverHeight = 167.0;
  static const double hostCardHeight           =  84.0;
  static const double hostAvatarSize           =  50.0;
  static const double hostStarSize             =   8.0;
  static const double modalActionButtonWidth   = 247.0;
  static const double modalActionButtonHeight  =  50.0;
  static const double communityInfoContentPad  =  16.0;
  static const double communityInfoSectionGap  =  12.0;
  static const double communityInfoBottomPad   =  20.0;

  // Community Rules Modal
  static const double rulesBannerHeight    = 100.0;
  static const double rulesCheckboxSize    =  16.0;
  static const double rulesCheckboxRadius  =   2.0;
  static const double rulesContentPadH     =  20.0;
  static const double rulesContentPadV     =  20.0;
  static const double rulesItemGap         =  12.0;
  static const double rulesPreCheckboxGap  =  16.0;
  static const double rulesPreButtonGap    =  16.0;

  // Font sizes
  static const double fontXXXS    =  9.0;
  static const double fontXXS     = 10.0;
  static const double fontXS      = 11.0;
  static const double fontXII     = 12.0;
  static const double fontS       = 13.0;
  static const double fontSM      = 14.0;
  static const double fontM       = 15.0;
  static const double fontML      = 16.0;
  static const double fontL       = 17.0;
  static const double fontXL      = 22.0;
  static const double fontTitle   = 24.0;
  static const double fontXXVI    = 26.0;
  static const double fontXXL     = 28.0;
  static const double fontDisplay = 32.0;

  /// Blur sigma for BackdropFilter on liquid glass cards
  static const double glassBlurSigma = 15.0;

  // Member sheet
  static const double memberAvatarSize    = 44.0;
  static const double memberSheetRadius   = 20.0;
  static const double memberCloseBtnSize  = 32.0;
  static const double memberOnlineDotSize =  9.0;
  static const double memberKickBtnSize   = 32.0;
  static const double memberKickBtnRadius =  8.0;
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
  static const String categorySubtitle   = "Pick your interests. We'll surface live rooms in these.";
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
  static const String inboxTitle    = 'Inbox';
  static const String inboxEmpty    = 'No notifications yet';
  static const String inboxRecent   = 'Recent';
  static const String inboxHrsAgo   = ' hrs ago';
  static const String inboxDaysAgo  = ' days ago';
  static const String notifMention = ' mentioned you in ';
  static const String notifBody    = '@name Lorem ipsum dolor sit amet';

  // Chat screen
  static const String chatCommunityName = 'Community name (10)';
  static const String chatToday         = 'Today';
  static const String chatInputHint     = 'Message...';
  static const String chatCopy          = 'Copy';
  static const String chatReply         = 'Reply';
  static const String chatReport        = 'Report';
  static const String chatImageMessage    = '[Image]'; // fallback text for image-only messages
  static const String warningText         = 'Message failed to send. This content goes against our community standards. Repeated offenses will result in a ban. ';
  static const String warningReviewRules  = 'Review rules';
  static const String banText             = 'You have been restricted from using chat due to your behavior. chat again on ';
  static const String chatMenuInfo        = 'Info';
  static const String chatMenuMute        = 'Mute';
  static const String chatMenuUnmute      = 'Unmute';
  static const String chatMenuLeave       = 'leave';
  static const String chatMenuMembers     = 'Members';
  static const String chatMenuEvents      = 'Events';
  static const String chatLeaveTitle      = 'Leave this community?';
  static const String chatLeaveYes        = 'Yes';
  static const String chatLeaveNo         = 'No';
  static const String logoutTitle         = 'Log out?';
  static const String chatInfoSnackbar    = 'Community info coming soon';
  static const String chatMutedSnackbar   = 'Notifications muted';
  static const String chatUnmutedSnackbar = 'Notifications unmuted';

  // Report modal
  static const String reportTitle            = 'Why are you';
  static const String reportTitleAccent      = 'Report';
  static const String reportSubtitle         = 'Your report is anonymous.\nTell us the reason';
  static const String reportReasonLabel      = 'Reason';
  static const String reportDescriptionLabel = 'Description';
  static const String reportDescriptionHint  = 'Tell us...';
  static const String reportPost             = 'Post';
  static const List<String> reportReasons    = [
    'Hate Speech',
    'Harassment',
    'Threat',
    'Scam',
    'Others',
  ];

  // Create Community screen
  static const String createTitle          = 'Host';
  static const String editTitle            = 'Edit';
  static const String editSaveButton       = 'Save';
  static const String editSnackbar         = 'Community updated!';
  static const String createNameLabel     = 'Community Name';
  static const String createNameHint      = 'Enter Community Name';
  static const String createAboutLabel    = 'About Community';
  static const String createAboutHint     = 'Enter Community description';
  static const String createCategoryLabel = 'Category';
  static const String createRulesLabel    = 'Community Rules';
  static const String createRulesHint     = 'Type your rule';
  static const String createAddRule       = '+ Add more rules';
  static const String createButton        = 'Create';
  static const String createRuleTooltip =
      'Keep your community safe! Write your custom rules below, '
      'and our AI assistant will help enforce them by removing violators';

  // Create Community — validation error messages
  static const String createErrCover    = 'Please add a cover photo';
  static const String createErrName     = 'Please enter a community name';
  static const String createErrAbout    = 'Please tell us about your community';
  static const String createErrCategory = 'Please select at least one category';
  static const String createErrRules    = 'Please add at least one community rule';

  static const List<String> createCategories = [
    'Badminton', 'Basketball', 'Football', 'Tennis',
    'Swimming', 'Cooking', 'Music', 'Art',
    'Coding', 'Dance', 'Photography', 'Gaming',
  ];

  // Community (My club tab)
  static const String myClubEmpty            = 'No communities yet.\nTap + to create one!';
  static const String communityMemberDefault      = '1 member';
  static const String communityMemberCountDefault = '1';

  // Profile screen
  static const String profileRateUser   = 'Rate this user';
  static const String profileEditButton = 'Edit Profile';
  static const String profileRating     = '4.8';
  static const String profileAbout      = 'About me';
  static const String profileInterests  = 'Interests';
  static const String profileComments   = 'Comments';
  static const String profileViewAll    = 'view all';
  static const String profileSubmitRate = 'Submit';
  static const String profileBio =
      "Hello everyone, I'm seeking for friend to play Badminton with me !";
  static const String profileCommentBody =
      'Lorem ipsum dolor sit amet, consectetuer adipiscing elit';

  // Rate User modal — test data (used until real auth is wired)
  static const String rateTestUsername    = 'TestUser';
  static const String rateTestCommunity   = 'Badminton KMUTT';
  static const String rateTestCommunityId = '';

  // Rate User modal — display strings
  static const String rateModalTitle1     = 'What in';
  static const String rateModalTitle2     = 'Your mind?';
  static const String rateModalAnonymous  = 'Your rating is anonymous.';
  static const String rateCommentOptional = '(optional)';
  static const String rateCommentHint     = 'Type something here!';
  static const String ratePost            = 'Post';

  // Relative time labels for comment timestamps
  static const String rateJustNow  = 'just now';
  static const String rateMinAgo   = ' min ago';
  static const String rateHrAgo    = ' hr ago';

  // Comments section empty state and view-all sheet
  static const String rateNoComments   = 'No comments yet';
  static const String rateReview       = 'review';
  static const String rateReviews      = 'reviews';

  // View All Reviews modal
  static const String reviewNoReviews   = 'No reviews yet';
  static const String reviewRatingLabel = 'Rating';

  // Edit Profile
  static const String profileSaveButton = 'Save';
  static const String profileNameLabel   = 'Name';
  static const List<String> interestOptions = [
    'Design 🎨',     'Coding 💻',       'Badminton 🏸',  'Writing ✍️',   'Cycling 🚴',
    'Yoga 🧘',       'Vegan 🌿',        'Home cooking 🍳','Climbing 🧗',  'Hardware 🔧',
    'Football ⚽',   'Running 🏃',      'Baking 🥐',     'Startups 🚀',  'Wine 🍷',
    'Music 🎵',      'Art 🖼️',          'Photography 📷', 'Gaming 🎮',    'Travel ✈️',
    'Fitness 💪',    'Reading 📚',      'Film 🎬',        'Language 🗣️', 'Sports 🏅',
    'Technology ⚙️', 'Swimming 🏊',    'Tennis 🎾',      'Basketball 🏀','Dance 💃',
  ];

  // Discover tab — category filter chips
  static const String discoverFilterAll = 'All';
  static const List<String> discoverCategories = [
    'All', 'Sports', 'Coding', 'Gaming', 'Food', 'Music', 'Art',
  ];

  // Community Info Modal
  static const String communityInfoNext        = 'Next';
  static const String communityInfoViewProfile = 'view profile →';
  static const String communityMembersLabel    = 'members';

  // Community Rules Modal
  static const String rulesModalTitle  = "Admin's group rules";
  static const String rulesAcceptLabel =
      'I accept the rules and the consequences for breaking them.';
  static const String rulesJoinButton  = 'Join';

  // Events screen
  static const String eventsEmpty        = 'No events yet';
  static const String eventsMaxMembers   = 'Max members:';

  // Create Event screen
  static const String createEventTitle        = 'Events';
  static const String createEventName        = 'Event Name';
  static const String createEventNameHint    = 'Enter Event Name';
  static const String createEventHostName    = 'Host Name';
  static const String createEventHostNameHint = 'Enter Host Name';
  static const String createEventDate        = 'DATE';
  static const String createEventDateHint    = 'DD/MM/YYYY';
  static const String createEventTime        = 'TIME';
  static const String createEventTimeHint    = '00:00 AM';
  static const String createEventLocation    = 'Location';
  static const String createEventLocationHint = "Enter Event's location";
  static const String createEventDetail      = 'Event Detail';
  static const String createEventDetailHint  = 'Enter Event description';
  static const String createEventMembers     = 'Members';
  static const String createEventButton      = 'Create';
  static const String createEventSuccess     = 'Event created!';
  static const String createEventCoverHint    = 'Tap to add cover image';
  static const String createEventErrName     = 'Please enter an event name';
  static const String createEventErrDate     = 'Please select a date';

  // Member sheet
  static const String membersEmpty       = 'No members yet';
  static const String memberRoleCreator  = 'Creator';
  static const String memberRoleAdmin    = 'Admin';
  static const String memberRoleMember   = 'Member';
  static const String memberKickedToast  = 'has been removed';
  static const String kickConfirmTitle   = 'Remove member?';
  static const String kickConfirmNo      = 'Cancel';
  static const String kickConfirmYes     = 'Remove';
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

  /// Poppins — read receipts, timestamps, report modal labels, chips, and buttons
  static TextStyle poppins({
    double fontSize = AppSizes.fontM,
    FontWeight fontWeight = FontWeight.normal,
    Color color = AppColors.textDark,
    FontStyle fontStyle = FontStyle.normal,
  }) =>
      GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontStyle: fontStyle,
      );

  /// Instrument Serif — screen titles, headings, display text
  static TextStyle title({
    double fontSize = AppSizes.fontXXL,
    FontWeight fontWeight = FontWeight.w400,
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

  /// Poppins — button text
  static TextStyle button({
    double fontSize = 24.0,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.cardWhite,
  }) =>
      GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  /// Roboto — category chip labels
  static TextStyle chipLabel({
    double fontSize = AppSizes.fontS,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.textDark,
  }) =>
      GoogleFonts.roboto(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
}
