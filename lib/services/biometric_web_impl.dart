import 'dart:convert';
import 'dart:js_util' as js_util;

const _webCredKey = 'biometric_creds';

Future<bool> bioWebAvailable() async {
  try {
    final pkc =
        js_util.getProperty<Object?>(js_util.globalThis, 'PublicKeyCredential');
    // ignore: avoid_print
    print('[BiometricWeb] bioWebAvailable pkc=$pkc');
    return pkc != null;
  } catch (e) {
    // ignore: avoid_print
    print('[BiometricWeb] bioWebAvailable error: $e');
    return false;
  }
}

Future<bool> bioWebEnrolled() async {
  try {
    final ls =
        js_util.getProperty<Object>(js_util.globalThis, 'localStorage');
    final id =
        js_util.callMethod<Object?>(ls, 'getItem', ['webauthn_id']);
    // ignore: avoid_print
    print('[BiometricWeb] bioWebEnrolled webauthn_id=$id');
    return id != null;
  } catch (e) {
    // ignore: avoid_print
    print('[BiometricWeb] bioWebEnrolled error: $e');
    return false;
  }
}

Future<bool> bioWebRegister(String email, String password) async {
  try {
    // Store credentials in localStorage before WebAuthn registration.
    final ls =
        js_util.getProperty<Object>(js_util.globalThis, 'localStorage');
    js_util.callMethod<void>(ls, 'setItem', [
      _webCredKey,
      jsonEncode({'email': email, 'password': password}),
    ]);
    // ignore: avoid_print
    print('[BiometricWeb] bioWebRegister calling JS webAuthnRegister($email)');
    final result = await js_util.promiseToFuture<Object?>(
      js_util.callMethod(js_util.globalThis, 'webAuthnRegister', [email]),
    );
    // ignore: avoid_print
    print('[BiometricWeb] bioWebRegister result=$result');
    return result == true;
  } catch (e) {
    // ignore: avoid_print
    print('[BiometricWeb] bioWebRegister error: $e');
    return false;
  }
}

/// Returns stored credentials after WebAuthn verification, or null on failure.
Future<Map<String, String>?> bioWebAuthenticate() async {
  try {
    // ignore: avoid_print
    print('[BiometricWeb] bioWebAuthenticate calling JS webAuthnAuthenticate()');
    final result = await js_util.promiseToFuture<Object?>(
      js_util.callMethod(js_util.globalThis, 'webAuthnAuthenticate', []),
    );
    // ignore: avoid_print
    print('[BiometricWeb] bioWebAuthenticate result=$result');
    if (result == null) return null;

    final ls =
        js_util.getProperty<Object>(js_util.globalThis, 'localStorage');
    final raw =
        js_util.callMethod<Object?>(ls, 'getItem', [_webCredKey]);
    if (raw == null) {
      // ignore: avoid_print
      print('[BiometricWeb] bioWebAuthenticate: no stored creds');
      return null;
    }
    final map = jsonDecode(raw.toString()) as Map<String, dynamic>;
    return {
      'email': (map['email'] as String?) ?? '',
      'password': (map['password'] as String?) ?? '',
    };
  } catch (e) {
    // ignore: avoid_print
    print('[BiometricWeb] bioWebAuthenticate error: $e');
    return null;
  }
}
