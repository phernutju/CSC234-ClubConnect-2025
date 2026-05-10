import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn();

  /// Signs in with Google, authenticates with Firebase, and returns the
  /// [GoogleSignInAccount] (which carries displayName + email) on success,
  /// or null if the user cancelled the flow.
  static Future<GoogleSignInAccount?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
    return account;
  }
}
