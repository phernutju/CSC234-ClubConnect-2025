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
      debugPrint(
          '[BiometricService] native supported=$supported canCheck=$canCheck');
      // isDeviceSupported covers PIN/pattern/password; canCheckBiometrics is
      // only true when a biometric sensor is present. We allow PIN fallback
      // (biometricOnly: false), so supported alone is sufficient.
      return supported;
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
      return bio_web.bioWebRegister(email, password);
    }
    debugPrint(
        '[BiometricService] SAVE email=$email passwordLen=${password.length}');
    await _storage.write(
      key: _credKey,
      value: jsonEncode({'email': email, 'password': password}),
    );
    final verify = await _storage.read(key: _credKey);
    debugPrint(
        '[BiometricService] VERIFY stored=${verify != null} rawLen=${verify?.length}');
    return true;
  }

  Future<Map<String, String>?> authenticate() async {
    if (kIsWeb) {
      final creds = await bio_web.bioWebAuthenticate();
      if (creds == null) return null;
      final email = creds['email'] ?? '';
      final password = creds['password'] ?? '';
      if (email.isEmpty || password.isEmpty) {
        throw Exception('BiometricService: web credentials are incomplete');
      }
      return creds;
    }
    final bool ok;
    try {
      ok = await _localAuth.authenticate(
        localizedReason: 'Sign in to ClubConnect',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('[BiometricService] local_auth error: $e');
      return null;
    }
    if (!ok) return null; // user cancelled — do NOT clear credentials

    // Local auth passed. Validate stored credentials separately so bad data
    // throws instead of silently returning null (caller clears enrollment).
    final raw = await _storage.read(key: _credKey);
    if (raw == null) {
      throw Exception('BiometricService: no credentials in storage');
    }
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final email = (map['email'] as String?) ?? '';
    final password = (map['password'] as String?) ?? '';
    debugPrint(
        '[BiometricService] READ email=$email passwordLen=${password.length}');
    if (email.isEmpty || password.isEmpty) {
      debugPrint('[BiometricService] READ incomplete — throwing');
      throw Exception('BiometricService: stored credentials are incomplete');
    }
    return {'email': email, 'password': password};
  }

  Future<void> clearCredentials() async {
    if (kIsWeb) return;
    await _storage.delete(key: _credKey);
  }
}
