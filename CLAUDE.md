# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

ClubConnect is a Flutter mobile app (CSC234 course project) for discovering and joining campus clubs. The only app is at `apps/mobile/`.

## Commands

All commands run from `apps/mobile/`:

```bash
flutter run                  # run on connected device / simulator
flutter analyze              # static analysis (uses flutter_lints)
flutter test                 # run all tests
flutter test test/foo_test.dart  # run a single test file
flutter build apk            # Android release build
flutter build ios            # iOS release build
```

## Architecture

### Navigation (`lib/router/app_router.dart`)

Declarative routing via `go_router`. Two logical sections:

- **Auth flow** (no bottom nav): `/ → /login | /signup → /verify-phone → /otp → /set-profile → /category → /home`
- **Main app** (`ShellRoute`): `/home`, `/notification`, `/profile` share a persistent bottom nav bar rendered by `ShellScreen`
- **Overlays** (pushed over the shell): `/chat`, `/create-community`

Navigation uses `context.go()` for tab switches and `context.push()` for forward navigation within a flow.

### Design system (`lib/constants/app_constants.dart`)

Single source of truth for the entire visual language — **widgets must never hardcode colors, sizes, or strings**:

- `AppColors` — all color tokens (primary coral `0xFFE07355`, background cream `0xFFFAF5F0`, etc.)
- `AppSizes` — padding scale, border-radius scale, fixed component dimensions, font sizes
- `AppStrings` — every user-visible string in the app
- `AppTextStyles` — two font families: **Inter** (`body()`) for UI copy, **Instrument Serif** (`title()`) for headings/display text

### Feature structure

```
lib/
  constants/         # AppColors, AppSizes, AppStrings, AppTextStyles
  router/            # GoRouter definition
  features/
    auth/
      screens/       # WelcomeScreen, LoginScreen, SignupScreen, VerifyPhoneScreen,
                     # OtpScreen, SetProfileScreen, CategoryScreen
      widgets/       # AuthTextField, PrimaryButton, LiquidCard, GoogleSignInButton,
                     # StepProgressBar
    home/
      screens/       # HomeScreen, ShellScreen, NotificationScreen, ProfileScreen,
                     # ChatScreen, CreateCommunityScreen
      widgets/       # AppBottomNavBar, HomeTabBar, ClubCard, CategoryTag,
                     # NotificationItem
```

### Theme

`MaterialApp.router` with Material 3, seed color `AppColors.primary`. Ripple/splash is globally disabled (`NoSplash.splashFactory`) — use `GestureDetector` for custom tap feedback.

### State management

No state management framework is used. All state is local to each screen via `StatefulWidget`. `TextEditingController` instances are disposed in `dispose()`. There is no cross-screen state sharing yet.

### Data layer

No models, repositories, or services exist yet. All displayed data is hardcoded as `List<Map<String, String>>` directly inside screen widgets. Business logic stubs (login validation, OTP verification, category saving, community creation) are marked with `// TODO` comments at their call sites.

### Widget conventions

- Screens decompose internal sections into private sub-widgets using the `_WidgetName` naming convention.
- `CategoryScreen` allows selecting **up to 3** interests; selection logic is managed with a local `Set<String>`.
- `OtpScreen` uses 4 individual `TextField` nodes with auto-focus advancing on each character entry.
- `LiquidCard` achieves its frosted-glass look via `BackdropFilter` + semi-transparent white — requires an image or gradient behind it to be visible.
