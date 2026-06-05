import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'biometric_web_stub.dart'
    if (dart.library.html) 'biometric_web_impl.dart' as bio_web;

class BiometricService {
  static const _credKey = 'biometric_credentials';

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> isAvailable() async {
    debugPrint('[BiometricService] isAvailable() kIsWeb=$kIsWeb');
    if (kIsWeb) {
      final result = await bio_web.bioWebAvailable();
      debugPrint('[BiometricService] bioWebAvailable=$result');
      return result;
    }
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      debugPrint('[BiometricService] native supported=$supported canCheck=$canCheck');
      return supported && canCheck;
    } catch (e) {
      debugPrint('[BiometricService] isAvailable error: $e');
      return false;
    }
  }

  Future<bool> hasEnrolled() async {
    if (kIsWeb) {
      final result = await bio_web.bioWebEnrolled();
      debugPrint('[BiometricService] bioWebEnrolled=$result');
      return result;
    }
    final val = await _storage.read(key: _credKey);
    debugPrint('[BiometricService] native enrolled=${val != null}');
    return val != null;
  }

  Future<bool> saveCredentials(String email, String password) async {
    if (kIsWeb) {
      return bio_web.bioWebRegister(email);
    }
    await _storage.write(
      key: _credKey,
      value: jsonEncode({'email': email, 'password': password}),
    );
    return true;
  }

  Future<Map<String, String>?> authenticate() async {
    if (kIsWeb) {
      final username = await bio_web.bioWebAuthenticate();
      if (username == null) return null;
      return {'email': username, 'password': ''};
    }
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Sign in to ClubConnect',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!ok) return null;
      final raw = await _storage.read(key: _credKey);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        'email': map['email'] as String,
        'password': map['password'] as String,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCredentials() async {
    if (kIsWeb) return;
    await _storage.delete(key: _credKey);
  }
}
