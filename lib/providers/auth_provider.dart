import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

/// Wraps all authentication service calls.
/// Screens call this provider — never the service directly.
class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      return await GoogleAuthService.signInWithGoogle();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await AuthService.login(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> signup(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await AuthService.signup(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyPhone(String phoneNumber) =>
      AuthService.verifyPhone(phoneNumber);

  Future<bool> verifyOtp(String otp) => AuthService.verifyOtp(otp);

  Future<void> logout() => AuthService.logout();
}
