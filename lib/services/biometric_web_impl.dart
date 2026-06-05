import 'dart:js_util' as js_util;

Future<bool> bioWebAvailable() async {
  try {
    final pkc = js_util.getProperty<Object?>(js_util.globalThis, 'PublicKeyCredential');
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
    final ls = js_util.getProperty<Object>(js_util.globalThis, 'localStorage');
    final id = js_util.callMethod<Object?>(ls, 'getItem', ['webauthn_id']);
    // ignore: avoid_print
    print('[BiometricWeb] bioWebEnrolled webauthn_id=$id');
    return id != null;
  } catch (e) {
    // ignore: avoid_print
    print('[BiometricWeb] bioWebEnrolled error: $e');
    return false;
  }
}

Future<bool> bioWebRegister(String email) async {
  try {
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

Future<String?> bioWebAuthenticate() async {
  try {
    // ignore: avoid_print
    print('[BiometricWeb] bioWebAuthenticate calling JS webAuthnAuthenticate()');
    final result = await js_util.promiseToFuture<Object?>(
      js_util.callMethod(js_util.globalThis, 'webAuthnAuthenticate', []),
    );
    // ignore: avoid_print
    print('[BiometricWeb] bioWebAuthenticate result=$result');
    if (result == null) return null;
    return result.toString();
  } catch (e) {
    // ignore: avoid_print
    print('[BiometricWeb] bioWebAuthenticate error: $e');
    return null;
  }
}
