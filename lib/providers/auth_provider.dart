import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

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
  final StorageService _storageService = StorageService();

  User? user;
  String? role;
  bool isBanned = false;
  bool isMuted = false;
  DateTime? muteExpiresAt;
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
  StreamSubscription<DocumentSnapshot>? _userSub;

  OtpState get otpState => _otpState;
  String? get otpError => _otpError;
  bool get canResend => _canResend;

  bool _pendingNotify = false;

  void _safeNotify() {
    if (_pendingNotify || !hasListeners) return;
    _pendingNotify = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pendingNotify = false;
      if (hasListeners) notifyListeners();
    });
  }

  String? _email;
  String? _password;
  String? _displayName;
  String? _phone;
  String? _bio;
  List<String>? _tags;
  String? _photoURL;
  Uint8List? _imageBytes;

  // Google registration state — populated by startGoogleRegistration(),
  // consumed by signUp(), cleared by _clearSignupData().
  bool _pendingGoogleRegistration = false;
  AuthCredential? _googleCredential;
  String? _googleDisplayName;
  String? _googleEmail;
  String? _googlePhotoURL;

  // Email registration state — true from createEmailAuthAccount() until
  // signUp() completes. Keeps the router from redirecting auth routes to
  // /home while the user is mid-onboarding.
  bool _pendingEmailRegistration = false;

  bool get pendingGoogleRegistration => _pendingGoogleRegistration;
  bool get pendingEmailRegistration  => _pendingEmailRegistration;
  String? get googleDisplayName => _googleDisplayName;
  String? get googleEmail => _googleEmail;

  AppAuthProvider() {
    _auth.authStateChanges().listen((u) {
      user = u;
      if (u != null) {
        _startUserStream(u.uid);
      } else {
        _userSub?.cancel();
        _userSub = null;
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

  void _startUserStream(String uid) {
    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) async {
      final data = doc.data() ?? {};
      role = (data['role'] as String?) ?? 'user';

      final bannedInDb = (data['isBanned'] as bool?) ?? false;
      final expiresTs = data['banExpiresAt'] as Timestamp?;

      if (bannedInDb && expiresTs != null && expiresTs.toDate().isBefore(DateTime.now())) {
        // Ban expired — auto-unban
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'isBanned': false,
          'isMuted': false,
          'violationCount': 0,
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
      final mutedInDb = (data['isMuted'] as bool?) ?? false;
      final muteExpiresTs = data['muteExpiresAt'] as Timestamp?;
      if (mutedInDb && muteExpiresTs != null && muteExpiresTs.toDate().isBefore(DateTime.now())) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'isMuted': false,
          'muteExpiresAt': FieldValue.delete(),
          'violationCount': 0,
        });
        isMuted = false;
        muteExpiresAt = null;
      } else {
        isMuted = mutedInDb;
        muteExpiresAt = muteExpiresTs?.toDate();
      }
      _safeNotify();
    }, onError: (_) {
      role = 'user';
      isBanned = false;
      isMuted = false;
      _safeNotify();
    });
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

  void setExtraInfo(String photoURL, String displayName, String bio, {Uint8List? imageBytes}) {
    debugPrint('[AuthProvider] imageBytes received: ${imageBytes?.length}');
    _photoURL = photoURL;
    _imageBytes = imageBytes;
    _displayName = displayName;
    _bio = bio;
  }

  void setInterests(List<String> tags) => _tags = tags;

  /// Creates the Firebase Auth account at signup time (step 1 of the
  /// email-registration flow). Throws [FirebaseAuthException] on failure so
  /// the signup screen can map error codes to field-level messages.
  Future<void> createEmailAuthAccount(String email, String password) async {
    _pendingEmailRegistration = true;
    notifyListeners();
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _email    = email;
      _password = password; // kept for re-auth after OTP phone sign-out
    } on FirebaseAuthException {
      _pendingEmailRegistration = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _pendingEmailRegistration = false;
      notifyListeners();
      rethrow;
    }
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
      // Clear the temporary phone-auth session. For the email registration
      // flow, immediately re-authenticate with the email account that was
      // created at signup time, which was displaced by the phone credential.
      await _authService.signOut();
      if (_pendingEmailRegistration && _email != null && _password != null) {
        await _auth.signInWithEmailAndPassword(
          email: _email!,
          password: _password!,
        );
      }
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
        // Email registration path — Firebase Auth account was already created
        // in createEmailAuthAccount(). Just write the Firestore document.
        final currentUser = _auth.currentUser;
        if (currentUser == null || _displayName == null) {
          throw Exception('Missing required signup data');
        }
        debugPrint('[SignUp] currentUser uid: ${currentUser.uid}');
        await _authService.writeUserDocument(
          user: currentUser,
          displayName: _displayName!,
          phoneNumber: _phone ?? '',
          interests: _tags ?? [],
          bio: _bio ?? '',
          photoURL: _photoURL ?? '',
        );
        if (_imageBytes != null) {
          final url = await _storageService.uploadUserAvatar(_imageBytes!, currentUser.uid);
          await _authService.updatePhotoURL(currentUser.uid, url);
        }
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
    _pendingEmailRegistration = false;
    _imageBytes = null;
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
    _userSub?.cancel();
    super.dispose();
  }
}
