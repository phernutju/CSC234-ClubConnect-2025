import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? user;
  bool isLoading = false;

  String? _email;
  String? _password;
  String? _displayName;
  String? _phone;
  String? _bio;
  List<String>? _tags;
  String? _photoURL;

  AppAuthProvider() {
    _auth.authStateChanges().listen((u) {
      user = u;
      notifyListeners();
    });
  }

  void setEmailPassword(String email, String password) {
    _email = email;
    _password = password;
  }

  void setPhoneNumber(String phonenum) => _phone = phonenum;

  void setExtraInfo(String photoURL, String displayName, String bio) {
    _photoURL = photoURL;
    _displayName = displayName;
    _bio = bio;
  }

  void setInterests(List<String> tags) => _tags = tags;

  Future<void> signUp() async {
    isLoading = true;
    notifyListeners();
    try {
      if (_email == null || _password == null || _displayName == null) {
        throw AuthException('Missing required signup data');
      }
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _email!,
        password: _password!,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'displayName': _displayName,
        'email': _email,
        'phoneNumber': _phone ?? '',
        'photoURL': _photoURL ?? '',
        'bio': _bio ?? '',
        'interests': _tags ?? [],
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _clearSignupData();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    } finally {
      isLoading = false;
      notifyListeners();
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
      throw AuthException(_mapError(e.code));
    }
  }

  Future<void> signOut() async => _auth.signOut();

  void _clearSignupData() {
    _email = null;
    _password = null;
    _displayName = null;
    _phone = null;
    _tags = null;
    _bio = null;
    _photoURL = null;
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email format';
      case 'email-already-in-use':
        return 'This email is already registered';
      default:
        return 'Something went wrong';
    }
  }
}
