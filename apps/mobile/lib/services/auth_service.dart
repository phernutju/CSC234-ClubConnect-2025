import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn();

  // IMPORTANT: Add your debug SHA-1 to Firebase Console → Project Settings → Android App
  // Run: cd android && ./gradlew signingReport to get your SHA-1
  static Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      return await _googleSignIn.signIn();
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('Google Sign-In Error: $e');
      // ignore: avoid_print
      print('Stack trace: $stackTrace');
      if (e is PlatformException) {
        debugPrint('Google Sign-In PlatformException: code=${e.code} message=${e.message}');
        // DEVELOPER_ERROR (code 10) means google-services.json is missing or SHA-1 is not registered
        if (e.code == 'sign_in_failed' ||
            (e.message?.contains('DEVELOPER_ERROR') ?? false) ||
            (e.message?.contains(': 10') ?? false)) {
          throw Exception(
            'Google Sign-In is not configured. Please add google-services.json',
          );
        }
      }
      rethrow;
    }
  }
}
