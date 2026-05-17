import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthException implements Exception {
  final String message;
  final String code;
  const AuthException(this.message, [this.code = '']);
  @override
  String toString() => message;
}

enum OtpState { idle, sendingOtp, codeSent, verifying, verified, error }

class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  User? user;
  String? role;
  bool isBanned = false;
  bool isMuted = false;
  String? banReason;
  DateTime? banExpiresAt;
  String? durationLabel;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

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

  // Google registration state — populated by startGoogleRegistration(),
  // consumed by signUp(), cleared by _clearSignupData().
  bool _pendingGoogleRegistration = false;
  AuthCredential? _googleCredential;
  String? _googleDisplayName;
  String? _googleEmail;
  String? _googlePhotoURL;

  bool get pendingGoogleRegistration => _pendingGoogleRegistration;
  String? get googleDisplayName => _googleDisplayName;
  String? get googleEmail => _googleEmail;

  AppAuthProvider() {
    _auth.authStateChanges().listen((u) {
      user = u;
      if (u != null) {
        _fetchRole(u.uid);
      } else {
        role = null;
        isBanned = false;
        isMuted = false;
        banReason = null;
        banExpiresAt = null;
        durationLabel = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? {};
      role = (data['role'] as String?) ?? 'user';

      final bannedInDb = (data['isBanned'] as bool?) ?? false;
      final expiresTs = data['banExpiresAt'] as Timestamp?;

      if (bannedInDb && expiresTs != null && expiresTs.toDate().isBefore(DateTime.now())) {
        // Ban expired — auto-unban
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'isBanned': false,
          'banReason': FieldValue.delete(),
          'durationLabel': FieldValue.delete(),
          'banExpiresAt': FieldValue.delete(),
          'bannedAt': FieldValue.delete(),
          'bannedBy': FieldValue.delete(),
        });
        isBanned = false;
        banReason = null;
        banExpiresAt = null;
        durationLabel = null;
      } else {
        isBanned = bannedInDb;
        banReason = data['banReason'] as String?;
        banExpiresAt = expiresTs?.toDate();
        durationLabel = data['durationLabel'] as String?;
      }
      isMuted = (data['isMuted'] as bool?) ?? false;
    } catch (_) {
      role = 'user';
      isBanned = false;
      isMuted = false;
    }
    notifyListeners();
  }

  void setEmailPassword(String email, String password) {
    _email = email;
    _password = password;
  }

  void setPhoneNumber(String phonenum) {
    _phone = formatPhoneNumber(phonenum);
  }

  String formatPhoneNumber(String phone) {
    // Remove any spaces or dashes
    phone = phone.replaceAll(' ', '').replaceAll('-', '');

    // Replace leading 0 with +66
    if (phone.startsWith('0')) {
      phone = '+66${phone.substring(1)}';
    }

    return phone; // +6680000000
  }

  void setExtraInfo(String photoURL, String displayName, String bio) {
    _photoURL = photoURL;
    _displayName = displayName;
    _bio = bio;
  }

  void setInterests(List<String> tags) => _tags = tags;

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
    _isLoading = true;
    notifyListeners();
    try {
      if (_googleCredential != null) {
        // Google registration path — Firebase Auth created here for the first time.
        await _authService.signUpWithGoogle(
          credential: _googleCredential!,
          displayName: _displayName ?? _googleDisplayName ?? '',
          phoneNumber: _phone ?? '',
          interests: _tags ?? [],
          bio: _bio ?? '',
          photoURL: (_photoURL != null && _photoURL!.isNotEmpty)
              ? _photoURL!
              : (_googlePhotoURL ?? ''),
        );
      } else {
        // Email / password registration path.
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
      }
      _clearSignupData();
    } catch (e) {
      debugPrint('SignUp error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _authService.signInWithGoogle();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registration flow entry point for Google sign-in.
  /// Fetches Google credentials + profile WITHOUT creating a Firebase Auth
  /// session. Sets [pendingGoogleRegistration] to prevent the router from
  /// redirecting to /home if a brief popup sign-in occurs on web.
  Future<void> startGoogleRegistration() async {
    _isLoading = true;
    _pendingGoogleRegistration = true;
    notifyListeners();
    try {
      final data = await _authService.fetchGoogleRegistrationData();
      if (data == null) {
        // User cancelled
        _pendingGoogleRegistration = false;
        return;
      }
      _googleCredential = data.credential;
      _googleDisplayName = data.displayName;
      _googleEmail = data.email;
      _googlePhotoURL = data.photoURL;
    } catch (e) {
      _pendingGoogleRegistration = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _googleCredential = null;
    _googleDisplayName = null;
    _googleEmail = null;
    _googlePhotoURL = null;
    _pendingGoogleRegistration = false;
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

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
