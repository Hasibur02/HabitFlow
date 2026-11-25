import 'app_locale.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'theme_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ---------------- EMERALD LUXURY THEME ----------------
  static const Color primary = Color(0xFF0F6B57);
  static const Color ink = Color(0xFF10332B);
  static const Color gold = Color(0xFFE2B857);
  static const Color goldLight = Color(0xFFF6E7B4);

  static const List<Color> _emeraldGradient = [
    Color(0xFF06241E),
    Color(0xFF0C4A3C),
    Color(0xFF14876B),
  ];

  static const List<Color> _screenGradient = [
    Color(0xFF06241E),
    Color(0xFF0C4A3C),
    Color(0xFF06241E),
  ];

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool obscurePassword = true;

  final FirebaseAuth auth = FirebaseAuth.instance;

  // Google Web Client ID
  static const String webClientId =
      '186104508344-46sh8rpkbtt8vkuasb06cik19iope6bf.apps.googleusercontent.com';

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Email Login and Sign Up
  Future<void> emailAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage(AppLocale.pick('Please enter your email and password', 'Email এবং Password লিখো'));
      return;
    }

    if (password.length < 6) {
      showMessage(AppLocale.pick('Password must be at least 6 characters', 'Password কমপক্ষে ৬ অক্ষরের হতে হবে'));
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? AppLocale.pick('Authentication failed', 'অথেন্টিকেশন ব্যর্থ হয়েছে'));
    } catch (e) {
      showMessage(AppLocale.pick('Something went wrong: $e', 'সমস্যা হয়েছে: $e'));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Google Login
  Future<void> googleLogin() async {
    setState(() => isLoading = true);

    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: webClientId,
      );

      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          account.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? AppLocale.pick('Google login failed', 'Google লগইন ব্যর্থ হয়েছে'));
    } catch (e) {
      showMessage(AppLocale.pick('Google login failed: $e', 'Google Login হয়নি: $e'));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Forgot Password
  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage(AppLocale.pick('Enter your email first', 'প্রথমে Email লিখো'));
      return;
    }

    try {
      await auth.sendPasswordResetEmail(email: email);
      showMessage(AppLocale.pick('Password reset email sent', 'Password reset email পাঠানো হয়েছে'));
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? AppLocale.pick('Reset failed', 'রিসেট ব্যর্থ হয়েছে'));
    } catch (e) {
      showMessage(AppLocale.pick('Something went wrong: $e', 'সমস্যা হয়েছে: $e'));
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // UI HELPERS
  // --------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final palette = AppPalette.of(context);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      floatingLabelStyle: TextStyle(color: palette.accent),
      prefixIcon: Icon(icon, color: palette.accent),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: palette.surfaceAlt,
      border: border(palette.border, 1),
      enabledBorder: border(palette.border, 1),
      focusedBorder: border(palette.accent, 1.6),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: gold.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Image.asset(
        'assets/images/habitflow_logo.png',
        width: 84,
        height: 84,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.track_changes,
            size: 70,
            color: gold,
          );
        },
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onPressed == null
              ? const [Color(0xFF2E4540), Color(0xFF3B5750)]
              : _emeraldGradient,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: gold.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: _emeraldGradient.last.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: gold,
          disabledForegroundColor: gold.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(gold),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }

  // --------------------------------------------------
  // MAIN UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    return Scaffold(
      backgroundColor: const Color(0xFF06241E),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _screenGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        AppLocale.instance.setLanguage(
                          AppLocale.isBangla ? 'en' : 'bn',
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: goldLight,
                      ),
                      child: Text(
                        AppLocale.isBangla ? 'English' : 'বাংলা',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  _buildLogo(),

                  const SizedBox(height: 16),

                  const Text(
                    'HabitFlow',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isLogin
                        ? AppLocale.tr('Welcome back!')
                        : AppLocale.tr('Create your account'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFC9E8DB),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppPalette.of(context).surface,
                          AppPalette.of(context).surfaceAlt,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Email
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: AppPalette.of(context).accent,
                          decoration: _inputDecoration(
                            label: AppLocale.tr('Email'),
                            icon: Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          cursorColor: AppPalette.of(context).accent,
                          decoration: _inputDecoration(
                            label: AppLocale.tr('Password'),
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        // Forgot Password
                        if (isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading ? null : forgotPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: AppPalette.of(context).accent,
                              ),
                              child: const Tr('Forgot Password?'),
                            ),
                          )
                        else
                          const SizedBox(height: 8),

                        const SizedBox(height: 10),

                        // Email Login / Sign Up
                        _buildGradientButton(
                          text: isLogin
                              ? AppLocale.tr('Login')
                              : AppLocale.tr('Create Account'),
                          onPressed: isLoading ? null : emailAuth,
                          loading: isLoading,
                        ),

                        const SizedBox(height: 20),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: gold.withValues(alpha: 0.5),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Tr(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: gold.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Google Login
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: isLoading ? null : googleLogin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppPalette.of(context).ink,
                              backgroundColor: AppPalette.of(context).surface,
                              side: BorderSide(
                                color: AppPalette.of(context)
                                    .accent
                                    .withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.g_mobiledata,
                              size: 30,
                            ),
                            label: const Tr(
                              'Continue with Google',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Switch Login / Sign Up
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              isLogin = !isLogin;
                            });
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: goldLight,
                    ),
                    child: Text(
                      isLogin
                          ? AppLocale.tr("Don't have an account? Sign Up")
                          : AppLocale.tr('Already have an account? Login'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
