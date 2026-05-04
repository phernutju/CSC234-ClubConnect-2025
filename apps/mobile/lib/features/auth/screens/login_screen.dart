import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import 'package:provider/provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    String? emailErr;
    String? passErr;

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

    setState(() {
      _emailError    = emailErr;
      _passwordError = passErr;
    });

    return emailErr == null && passErr == null;
  }

  void _onNext() {
    if (_validate()) {
      // TODO: authenticate user against backend
      context.push('/verify-phone');
    }
  }

  Future<void> _onGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final account = await GoogleAuthService.signInWithGoogle();
      if (!mounted) return;
      if (account != null) {
        final profile = context.read<ProfileProvider>();
        // Save Google display name; photoUrl is a remote URL (avatar download deferred until DB connected)
        profile.saveProfile(
          username: account.displayName ?? '',
          bio: profile.bio,
        );
        context.go('/home', extra: {'displayName': account.displayName ?? '', 'email': account.email});
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
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF0EC),
      body: SingleChildScrollView(
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
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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

                    AuthTextField(
                      label: AppStrings.loginEmail,
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
                      label: AppStrings.loginPassword,
                      controller: _passwordController,
                      obscureText: true,
                      errorText: _passwordError,
                      fillColor: Colors.white,
                      fieldBorderRadius: 30,
                      enabledBorderColor: const Color(0xFFDDDDDD),
                      contentPaddingVertical: 14,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(height: screenHeight * 0.07),

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
    );
  }
}
