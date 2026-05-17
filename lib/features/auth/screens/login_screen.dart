import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/auth_result.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/validators.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/validated_field.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submitting    = false;
  bool _googleLoading = false;

  // Post-submit auth error — null when no error is present.
  AuthResult? _authError;

  static const _emailRules = [
    FieldRule(label: 'Valid email format', validate: isValidEmailFormat),
    FieldRule(label: 'No spaces',          validate: hasNoSpaces),
  ];

  static const _passwordRules = [
    FieldRule(label: 'Required', validate: isNotEmpty),
  ];

  bool get _canSubmit =>
      !_submitting &&
      _emailRules.every((r) => r.validate(_emailController.text)) &&
      _passwordRules.every((r) => r.validate(_passwordController.text));

  @override
  void initState() {
    super.initState();
    // Rebuild for _canSubmit; clear any existing auth-error banner on edit.
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() => _authError = null);

  // Wraps the Firebase call and maps exceptions to AuthResult variants.
  Future<AuthResult> _doSignIn() async {
    try {
      await context.read<AppAuthProvider>().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      return const Success();
    } on AuthException catch (e) {
      // These codes all mean "wrong credentials" — never reveal which.
      const invalidCodes = {
        'user-not-found',
        'wrong-password',
        'invalid-credential',
        'invalid-login-credentials',
        'INVALID_LOGIN_CREDENTIALS',
      };
      return invalidCodes.contains(e.code)
          ? const InvalidCredentials()
          : const NetworkError();
    } catch (_) {
      return const NetworkError();
    }
  }

  Future<void> _onNext() async {
    // Admin shortcut — bypasses Firebase.
    if (_emailController.text.trim() == 'nonlada1@gmail.com' &&
        _passwordController.text == '123456') {
      context.go('/admin');
      return;
    }

    setState(() { _submitting = true; _authError = null; });
    try {
      final result = await _doSignIn();
      if (!mounted) return;
      switch (result) {
        case Success():
          break; // authStateChanges fires; router handles redirect.
        case InvalidCredentials():
          setState(() => _authError = result);
        default:
          setState(() => _authError = const NetworkError());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _onGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      await context.read<AppAuthProvider>().signInWithGoogle();
      // null = user cancelled; authStateChanges handles redirect on success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final statusBarH   = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF0EC),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              height: screenHeight,
              child: Column(
                children: [
                  Expanded(
                    flex: 45,
                    child: Image.asset(
                      'assets/images/background.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Expanded(
                    flex: 55,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft:  Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.loginTitle,
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Auth-error banner — only after a failed submit.
                            if (_authError != null) ...[
                              AuthErrorBanner(
                                message: switch (_authError!) {
                                  InvalidCredentials() =>
                                    'Email or password is incorrect.',
                                  _ => 'Something went wrong. Please try again.',
                                },
                                onClose: () => setState(() => _authError = null),
                              ),
                              const SizedBox(height: 16),
                            ],

                            ValidatedField(
                              label: AppStrings.loginEmail,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              rules: _emailRules,
                            ),
                            const SizedBox(height: 16),

                            ValidatedField(
                              label: AppStrings.loginPassword,
                              controller: _passwordController,
                              isObscurable: true,
                              rules: _passwordRules,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(height: screenHeight * 0.07),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _canSubmit ? _onNext : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B4A),
                                  disabledBackgroundColor:
                                      const Color(0xFFFF6B4A).withValues(alpha: 0.4),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        AppStrings.loginNext,
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            GoogleSignInButton(
                              isLoading: _googleLoading,
                              onPressed: _onGoogleSignIn,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: statusBarH + 8,
            left: 4,
            child: IconButton(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
              iconSize: 24,
              tooltip: 'Back',
            ),
          ),
        ],
      ),
    );
  }
}
