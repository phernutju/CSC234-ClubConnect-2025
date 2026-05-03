import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? user;
  bool isLoading = false;

  AuthProvider() {
    _authService.authStateChanges.listen((u) {
      user = u;
      notifyListeners();
    });
  }

  Future<void> signUp(String email, String password, String name) async {
    isLoading = true;
    notifyListeners();

    await _authService.signUp(
      email: email,
      password: password,
      displayName: name,
    );

    isLoading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    notifyListeners();
  
    await _authService.signIn(
      email: email,
      password: password,
    );

    isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}