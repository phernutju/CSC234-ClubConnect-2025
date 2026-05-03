import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ///  Sign Up
  Future<User?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // create Firestore user document
        await _db.collection('users').doc(user.uid).set({
          'displayName': displayName,
          'email': email,
          'bio': '',
          'interests': [],
          'phoneNumber': '',
          'photoURL': '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  ///  Sign In
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// 🚪 Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 👤 Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 📱 Phone verification (basic)
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (e) {
        throw Exception(e.message);
      },
      codeSent: (verificationId, _) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// 🔢 Confirm OTP
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
}