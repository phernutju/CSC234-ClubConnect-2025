Future<bool> bioWebAvailable() async {
  // ignore: avoid_print
  print('[BiometricStub] STUB used — not web build');
  return false;
}

Future<bool> bioWebEnrolled() async {
  // ignore: avoid_print
  print('[BiometricStub] STUB used');
  return false;
}

Future<bool> bioWebRegister(String email, String password) async {
  // ignore: avoid_print
  print('[BiometricStub] STUB used');
  return false;
}

Future<Map<String, String>?> bioWebAuthenticate() async {
  // ignore: avoid_print
  print('[BiometricStub] STUB used');
  return null;
}
