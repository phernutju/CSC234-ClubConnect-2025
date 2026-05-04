import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../../../services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm  = _confirmController.text;
    String? emailErr;
    String? passErr;
    String? confirmErr;

    if (email.isEmpty) {
      emailErr = 'Email is required';
    } else if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email)) {
      emailErr = 'Enter a valid email address';
    }

    if (password.isEmpty) {
      passErr = 'Password is required';
    } else if (password.length < 6) {
      passErr = 'Password must be at least 6 characters';
    }

    if (confirm.isEmpty) {
      confirmErr = 'Please confirm your password';
    } else if (confirm != password) {
      confirmErr = 'Passwords do not match';
    }

    setState(() {
      _emailError    = emailErr;
      _passwordError = passErr;
      _confirmError  = confirmErr;
    });

    return emailErr == null && passErr == null && confirmErr == null;
  }

  void _onNext() {
    if (_validate()) {
      // TODO: create account on backend
      context.push('/verify-phone');
    }
  }

  Future<void> _onGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final account = await GoogleAuthService.signInWithGoogle();
      if (!mounted) return;
      if (account != null) {
        context.push('/set-profile', extra: {
          'googleDisplayName': account.displayName,
          'email': account.email,
        });
      }
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('Google Sign-In Error: $e');
      // ignore: avoid_print
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF0EC),
      body: SingleChildScrollView(
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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

                    AuthTextField(
                      label: AppStrings.signupEmail,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      fillColor: Colors.white,
                      fieldBorderRadius: 30,
                      enabledBorderColor: const Color(0xFFDDDDDD),
                      contentPaddingVertical: 14,
                    ),
                    const SizedBox(height: 16),

                    AuthTextField(
                      label: AppStrings.signupPassword,
                      controller: _passwordController,
                      obscureText: true,
                      errorText: _passwordError,
                      fillColor: Colors.white,
                      fieldBorderRadius: 30,
                      enabledBorderColor: const Color(0xFFDDDDDD),
                      contentPaddingVertical: 14,
                    ),
                    const SizedBox(height: 16),

                    AuthTextField(
                      label: AppStrings.signupConfirm,
                      controller: _confirmController,
                      obscureText: true,
                      errorText: _confirmError,
                      fillColor: Colors.white,
                      fieldBorderRadius: 30,
                      enabledBorderColor: const Color(0xFFDDDDDD),
                      contentPaddingVertical: 14,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B4A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
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
    );
  }
}
