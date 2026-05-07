import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

enum OtpState { idle, sendingOtp, codeSent, verifying, verified, error }

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? user;
  bool isLoading = false;

  OtpState _otpState = OtpState.idle;
  String? _verificationId;
  String? _otpError;
  bool _canResend = false;
  Timer? _resendTimer;

  OtpState get otpState => _otpState;
  String? get otpError => _otpError;
  bool get canResend => _canResend;

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
    _phone = formatPhoneNumber(phonenum);
    print('Formatted phone: $_phone');
  }
  String formatPhoneNumber(String phone) {
  // Remove any spaces or dashes
  phone = phone.replaceAll(' ', '').replaceAll('-', '');
  
  // Replace leading 0 with +66
  if (phone.startsWith('0')) {
    phone = '+66' + phone.substring(1);
  }
  
  return phone; // +6680000000
}
  void setExtraInfo(String photoURL, String displayName, String bio) {
    _photoURL = photoURL;
    _displayName = displayName;
    _bio = bio;
  }

  void setInterests(List<String> tags) {
    _tags = tags;
  }

  Future<void> sendOtp() async {
    if (_phone == null || _phone!.isEmpty) return;
    _otpState = OtpState.sendingOtp;
    _otpError = null;
    _canResend = false;
    notifyListeners();
    try {
      await _authService.verifyPhone(
        phoneNumber: _phone!,
        codeSent: (verificationId) {
          _verificationId = verificationId;
          _otpState = OtpState.codeSent;
          _startResendCooldown();
          notifyListeners();
        },
      );
    } catch (e) {
      _otpState = OtpState.error;
      _otpError = e.toString();
      _canResend = true;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      _otpState = OtpState.error;
      _otpError = 'No verification session. Tap Resend.';
      notifyListeners();
      return;
    }
    _otpState = OtpState.verifying;
    _otpError = null;
    notifyListeners();
    try {
      await _authService.confirmOtp(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _authService.signOut(); // clear phone-auth session; account created later at CategoryScreen
      _otpState = OtpState.verified;
      notifyListeners();
    } catch (e) {
      _otpState = OtpState.error;
      _otpError = e.toString();
      notifyListeners();
    }
  }

  void _startResendCooldown() {
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer(const Duration(seconds: 60), () {
      _canResend = true;
      notifyListeners();
    });
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

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
