# ClubConnect
A real-time, drop-in community app where users host and join hangout chat rooms based on shared interests — with AI-powered content moderation, a reputation-driven review system, and SMS-verified accounts.

Built for CSC231 (Agile Software Engineering) and CSC234 (Mobile Application Development) at School of Information Technology, KMUTT.

# Feature Core
| Feature | Description |
|---|---|
| **Community Rooms** | Create, browse, and join chat rooms filtered by interest tag |
| **Real-time Chat** | Live message stream via Firestore listeners; auto-scroll to latest message |
| **Authentication** | Email/password registration and login via Firebase Auth |
| **Phone Verification** | SMS OTP verification via Firebase Phone Auth to confirm account identity |
| **User Profile** | Edit avatar (Firebase Storage), username, bio, and personal interest tags |
| **Peer Review System** | Write, edit, and delete text reviews on any user's public profile |
| **Star Rating** | Rate other users (1–5 stars) after interaction; aggregate score shown on profile |
| **Home & Navigation** | Bottom navigation bar linking all core sections from a central home screen |
| **AI Content Moderation** | Each message is evaluated by Gemini against the room's own rules before it is displayed; inappropriate text, emoji abuse, and policy violations are flagged and blocked automatically |
| **Comment Source Detection** | Gemini analyses message content and context to identify which room or community a comment most likely originates from, surfacing cross-community behaviour |
| **Delete Comments** | Room creators and message authors can permanently delete any message |
| **Report System** | Users can report a message or profile; reports are stored in Firestore for admin review |


## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | ≥ 3.32.0 | Includes Dart 3.8 |
| [Dart SDK](https://dart.dev/get-dart) | ≥ 3.8.0 | Bundled with Flutter |
| [Firebase CLI](https://firebase.google.com/docs/cli) | ≥ 13.x | `npm install -g firebase-tools` |
| [FlutterFire CLI](https://firebase.flutter.dev/docs/cli) | Latest | `dart pub global activate flutterfire_cli` |
| [Google Gemini API Key](https://ai.google.dev/gemini-api/docs/api-key) | — | Free tier available at ai.google.dev |
| Android Studio | ≥ Koala (2024.1) | Android emulator and SDK tools |
| Xcode | ≥ 16 _(macOS only)_ | iOS Simulator and code signing |

---
Verify your Flutter setup before proceeding:

```bash
flutter doctor
```

All checkmarks for your target platform should be green.

---

## Setup & Run

### 1. Clone the repository

```bash
git clone https://github.com/your-org/clubconnect.git
cd clubconnect
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Create and configure a Firebase project

1. Open [console.firebase.google.com](https://console.firebase.google.com) and create a new project
2. Enable the following services:
   - **Authentication** → Sign-in method → enable **Email/Password** and **Phone**
   - **Firestore Database** → Create database → start in production mode → choose a region
   - **Storage** → Get started → choose the same region as Firestore

### 4. Connect Firebase to the app

```bash
firebase login
flutterfire configure
```

Select your Firebase project and the platforms you need (Android, iOS). This command generates `lib/firebase_options.dart` — **do not commit this file** (already in `.gitignore`).
