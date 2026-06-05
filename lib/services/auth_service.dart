import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'biometric_service.dart';

/// Carries Google OAuth tokens + profile info for the multi-step registration
/// flow. No Firebase Auth session is created until onboarding completes.
class GoogleRegistrationData {
  final AuthCredential credential;
  final String? email;
  final String? displayName;
  final String? photoURL;

  const GoogleRegistrationData({
    required this.credential,
    this.email,
    this.displayName,
    this.photoURL,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
      clientId:
          '939992324681-7g8c9pafc4jf99a6cak4cpu4nmf9citr.apps.googleusercontent.com');

  Future<User> signUp({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required List<String> interests,
    required String bio,
    required String? photoURL,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': displayName,
        'email': email.trim().toLowerCase(),
        'phoneNumber': phoneNumber,
        'photoURL': photoURL ?? '',
        'bio': bio,
        'interests': interests,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'mutedCommunities': [],
      });
      return credential.user!;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> updatePhotoURL(String uid, String url) =>
      _db.collection('users').doc(uid).update({'photoURL': url});

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _AuthServiceException(_mapError(e.code));
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final User user;

      if (kIsWeb) {
        // Web: Firebase popup handles OAuth directly — no gapi/google_sign_in needed.
        final result = await _auth.signInWithPopup(GoogleAuthProvider());
        user = result.user!;
      } else {
        // Mobile: google_sign_in triggers the native account picker.
        final account = await _googleSignIn.signIn();
        if (account == null) return null; // user cancelled

        final googleAuth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await _auth.signInWithCredential(credential);
        user = result.user!;
      }

      await _ensureFirestoreDoc(user);
      return user;
    } on FirebaseAuthException catch (e) {
      throw _AuthServiceException(_mapError(e.code));
    } catch (e) {
      if (e is _AuthServiceException) rethrow;
      throw _AuthServiceException(e.toString());
    }
  }

  Future<void> _ensureFirestoreDoc(User user) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'email': (user.email ?? '').toLowerCase(),
        'phoneNumber': '',
        'photoURL': user.photoURL ?? '',
        'bio': '',
        'interests': [],
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'mutedCommunities': [],
      });
    }
  }

  /// For the REGISTRATION flow only. Gets Google credentials + profile info
  /// without keeping a Firebase Auth session open (which would trigger the
  /// router's auth-guard redirect before onboarding completes).
  ///
  /// Web: opens popup, captures credential, then immediately signs out.
  /// Mobile: uses google_sign_in to get tokens without calling Firebase at all.
  /// Returns null if the user cancels.
  Future<GoogleRegistrationData?> fetchGoogleRegistrationData() async {
    if (kIsWeb) {
      try {
        final result = await _auth.signInWithPopup(GoogleAuthProvider());
        final credential = result.credential;
        if (credential == null) return null;
        final data = GoogleRegistrationData(
          credential: credential,
          email: result.user?.email,
          displayName: result.user?.displayName,
          photoURL: result.user?.photoURL,
        );
        await _auth
            .signOut(); // clear session — account finalised at onboarding end
        return data;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request') {
          return null;
        }
        rethrow;
      }
    } else {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      final googleAuth = await account.authentication;
      return GoogleRegistrationData(
        credential: GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ),
        email: account.email,
        displayName: account.displayName,
        photoURL: account.photoUrl,
      );
    }
  }

  /// Called at the end of onboarding for Google-registered users.
  /// Authenticates with Firebase using the stored credential and writes the
  /// complete user document (all onboarding data collected).
  Future<User> signUpWithGoogle({
    required AuthCredential credential,
    required String displayName,
    required String phoneNumber,
    required List<String> interests,
    required String bio,
    required String photoURL,
  }) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      final user = result.user!;
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': displayName,
        'email': (user.email ?? '').toLowerCase(),
        'phoneNumber': phoneNumber,
        'photoURL': photoURL,
        'bio': bio,
        'interests': interests,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'mutedCommunities': [],
      });
      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserCredential?> signInWithBiometric() async {
    final creds = await BiometricService().authenticate();
    if (creds == null) return null;
    return signIn(email: creds['email']!, password: creds['password']!);
  }

  Future<void> signOut() async => _auth.signOut();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (e) => throw Exception(e.message),
      codeSent: (verificationId, _) => codeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> confirmOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
  }

  /// Writes the Firestore user document for an already-authenticated user.
  /// Called at the end of email-signup onboarding when the Firebase Auth
  /// account was created at the start of the flow.
  Future<void> writeUserDocument({
    required User user,
    required String displayName,
    required String phoneNumber,
    required List<String> interests,
    required String bio,
    required String photoURL,
  }) async {
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'displayName': displayName,
      'email': (user.email ?? '').trim().toLowerCase(),
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'bio': bio,
      'interests': interests,
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'mutedCommunities': [],
    });
  }
}

class _AuthServiceException implements Exception {
  final String message;
  _AuthServiceException(this.message);
}

String _mapError(String code) {
  switch (code) {
    case 'user-not-found':
      return 'No user found with this email';
    case 'wrong-password':
      return 'Incorrect password';
    case 'invalid-email':
      return 'Invalid email format';
    default:
      return 'Something went wrong';
  }
}
