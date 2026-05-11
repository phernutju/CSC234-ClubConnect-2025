import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth_result.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
        'email': email,
        'phoneNumber': phoneNumber,
        'photoURL': photoURL ?? '',
        'bio': bio,
        'interests': interests,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return credential.user!;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

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
      // Preserve the raw Firebase code so callers can map to AuthResult.
      throw AuthException(_mapError(e.code), e.code);
    }
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

  /// Mock pre-check used by the register form before navigating to the phone
  /// verification step. Returns [EmailAlreadyRegistered] for
  /// 'existing@test.com'; otherwise [Success].
  ///
  /// Replace with a real Firebase email-availability check in production.
  static Future<AuthResult> preCheckSignUp(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.toLowerCase() == 'existing@test.com') {
      return const EmailAlreadyRegistered();
    }
    return const Success();
  }
}

class AuthException implements Exception {
  final String message;
  final String code;
  AuthException(this.message, [this.code = '']);
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
