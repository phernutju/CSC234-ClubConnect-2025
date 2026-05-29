import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/validators.dart';
import '../widgets/validated_field.dart';
import '../widgets/google_sign_in_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _submitting = false;
  bool _googleLoading = false;

  // Field-level errors shown after a failed submission.
  String? _emailError;
  String? _passwordError;

  static const _emailRules = [
    FieldRule(label: 'Valid email format', validate: isValidEmailFormat),
    FieldRule(label: 'No spaces', validate: hasNoSpaces),
  ];

  static const _passwordRules = [
    FieldRule(label: 'At least one letter', validate: hasLetter),
    FieldRule(label: 'At least one uppercase', validate: hasUppercase),
    FieldRule(label: 'At least one number', validate: hasNumber),
    FieldRule(label: 'At least 8 characters', validate: hasMinLength8),
  ];

  // Recomputed each build so the closure always captures the current password.
  List<FieldRule> get _confirmRules => [
        FieldRule(
          label: 'Passwords match',
          validate: (v) => v.isNotEmpty && v == _passwordController.text,
        ),
      ];

  bool get _canSubmit =>
      !_submitting &&
      _emailRules.every((r) => r.validate(_emailController.text)) &&
      _passwordRules.every((r) => r.validate(_passwordController.text)) &&
      _confirmRules.every((r) => r.validate(_confirmController.text));

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_onPasswordChanged);
    _confirmController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onEmailChanged()    => setState(() => _emailError = null);
  void _onPasswordChanged() => setState(() => _passwordError = null);
  void _onFieldChanged()    => setState(() {});

  Future<void> _onNext() async {
    setState(() { _submitting = true; _emailError = null; _passwordError = null; });
    try {
      await context.read<AppAuthProvider>().createEmailAuthAccount(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      context.push('/verify-phone');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'email-already-in-use':
          setState(() => _emailError = 'This email is already registered');
        case 'weak-password':
          setState(() => _passwordError = 'Password is too weak');
        default:
          setState(() => _emailError = 'Something went wrong. Please try again.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _emailError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _onGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final authProv = context.read<AppAuthProvider>();
      await authProv.startGoogleRegistration();
      if (!mounted) return;
      // pendingGoogleRegistration stays true after success; false means cancel.
      if (!authProv.pendingGoogleRegistration) return;
      context.push('/set-profile', extra: {
        'googleDisplayName': authProv.googleDisplayName,
        'email': authProv.googleEmail,
      });
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
    final statusBarH = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF0EC),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
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
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: AppStrings.signupHeading,
                                    style: GoogleFonts.instrumentSerif(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  TextSpan(
                                    text: AppStrings.signupHeadingAccent,
                                    style: GoogleFonts.instrumentSerif(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.italic,
                                      color: const Color(0xFFFF6B4A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            ValidatedField(
                              label: AppStrings.signupEmail,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              rules: _emailRules,
                            ),
                            if (_emailError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _emailError!,
                                style: AppTextStyles.body(
                                  fontSize: AppSizes.fontXS,
                                  color: const Color(0xFFE53935),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),

                            ValidatedField(
                              label: AppStrings.signupPassword,
                              controller: _passwordController,
                              isObscurable: true,
                              rules: _passwordRules,
                            ),
                            if (_passwordError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _passwordError!,
                                style: AppTextStyles.body(
                                  fontSize: AppSizes.fontXS,
                                  color: const Color(0xFFE53935),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),

                            ValidatedField(
                              label: AppStrings.signupConfirm,
                              controller: _confirmController,
                              isObscurable: true,
                              rules: _confirmRules,
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _canSubmit ? _onNext : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B4A),
                                  disabledBackgroundColor:
                                      const Color(0xFFFF6B4A)
                                          .withValues(alpha: 0.4),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
                                        AppStrings.signupNext,
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
              onPressed: () => context.pop(),
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
