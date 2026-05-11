// Outcome of a sign-in or sign-up attempt.
// Pattern-match at call sites with a switch expression.
sealed class AuthResult {
  const AuthResult();
}

final class Success extends AuthResult {
  const Success();
}

final class InvalidCredentials extends AuthResult {
  const InvalidCredentials();
}

final class EmailAlreadyRegistered extends AuthResult {
  const EmailAlreadyRegistered();
}

final class NetworkError extends AuthResult {
  const NetworkError();
}
