import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

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
    _authService.authStateChanges.listen((u) {
      user = u;
      notifyListeners();
    });
  }

  void setEmailPassword(String email, String password) {
    _email = email;
    _password = password;
  }

  void setPhoneNumber(String phonenum) {
    _phone = phonenum;
  }

  void setExtraInfo(String photoURL, String displayName, String bio) {
    _photoURL = photoURL;
    _displayName = displayName;
    _bio = bio;
  }

  void setInterests(List<String> tags) {
    _tags = tags;
  }

  Future<void> signUp() async {
    isLoading = true;
    notifyListeners();
    if (_email == null || _password == null || _displayName == null) {
      throw Exception('Missing required signup data');
    }
    await _authService.signUp(
      email: _email!,
      password: _password!,
      displayName: _displayName!,
      phoneNumber: _phone ?? '',
      interests: _tags ?? [],
      bio: _bio ?? '',
      photoURL: _photoURL ?? '',
    );

    isLoading = false;
    notifyListeners();

    _clearSignupData();
  }

   Future<void> signIn({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final credential = await _authService.signIn(
        email: email,
        password: password,
      );
      user = credential.user;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void _clearSignupData() {
    _email = null;
    _password = null;
    _displayName = null;
    _phone = null;
    _tags = null;
    _bio = null;
    _photoURL = null;
  }


}
