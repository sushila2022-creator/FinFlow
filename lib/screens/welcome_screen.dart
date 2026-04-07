import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/utils/debug_logger.dart';
import 'package:finflow/screens/signup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// WelcomeScreen - Login and authentication screen
///
/// Key changes:
/// - Removed SharedPreferences-based login flags
/// - FirebaseAuth.instance.currentUser is the single source of truth
/// - All authentication methods save user data to Firestore
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  /// Sign in with Google - creates/updates user in Firestore
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // Save/update user data in Firestore
      await _saveUserToFirestore(
        uid: userCredential.user!.uid,
        email: googleUser.email,
        name: googleUser.displayName ?? 'Google User',
        photoUrl: googleUser.photoUrl,
        provider: 'google',
      );

      logDebug('Google sign-in successful: ${userCredential.user?.email}');
      // Navigation is handled by AuthWrapper via auth state changes
    } catch (e) {
      String errorMessage = 'Google Sign In failed';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'network-request-failed':
            errorMessage =
                'Network error. Please check your internet connection';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Google sign-in is not enabled';
            break;
          default:
            errorMessage = e.message ?? 'Google Sign In failed';
        }
      } else {
        errorMessage = 'Google Sign In failed. Please try again.';
      }

      logError('Google sign-in failed', error: e);
      _showSnackBar(errorMessage, AppTheme.expenseColor);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Sign in with Apple - creates/updates user in Firestore
  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(oauthCredential);

      // Save/update user data in Firestore
      await _saveUserToFirestore(
        uid: userCredential.user!.uid,
        email: appleCredential.email ?? '',
        name:
            appleCredential.givenName != null &&
                appleCredential.familyName != null
            ? '${appleCredential.givenName} ${appleCredential.familyName}'
            : 'Apple User',
        provider: 'apple',
      );

      logDebug('Apple sign-in successful: ${userCredential.user?.email}');
      // Navigation is handled by AuthWrapper via auth state changes
    } catch (e) {
      String errorMessage = 'Apple Sign In failed';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'network-request-failed':
            errorMessage =
                'Network error. Please check your internet connection';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Apple sign-in is not enabled';
            break;
          default:
            errorMessage = e.message ?? 'Apple Sign In failed';
        }
      } else {
        errorMessage = 'Apple Sign In failed. Please try again.';
      }

      logError('Apple sign-in failed', error: e);
      _showSnackBar(errorMessage, AppTheme.expenseColor);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Save user data to Firestore
  Future<void> _saveUserToFirestore({
    required String uid,
    required String email,
    required String name,
    String? photoUrl,
    String? provider,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'provider': provider,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      logDebug('User data saved to Firestore: $uid');
    } catch (e) {
      logError('Failed to save user data to Firestore', error: e);
      // Don't fail the login if Firestore write fails
    }
  }

  void _handleLoginLoading(bool loading) {
    if (mounted) setState(() => _isLoading = loading);
  }

  @override
  Widget build(BuildContext context) {
    // Cache MediaQuery to avoid multiple lookups
    final screenSize = MediaQuery.sizeOf(context);
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const _GradientDecoration(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.03),
                  // Logo Branding
                  const _LogoWidget(),
                  SizedBox(height: screenHeight * 0.03),
                  _TitleSection(screenWidth: screenWidth),
                  const SizedBox(height: 8),
                  _SubtitleSection(),
                  SizedBox(height: screenHeight * 0.03),

                  // Centered Card (Glassmorphism Style)
                  _LoginFormCard(onLoadingChanged: _handleLoginLoading),
                  const SizedBox(height: 24),
                  const _SocialLoginDivider(),
                  const SizedBox(height: 24),
                  _SocialLoginButtons(
                    onGoogleSignIn: _signInWithGoogle,
                    onAppleSignIn: _signInWithApple,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),
                  _SignUpLink(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Extracted Widgets for Better Performance =====

/// Const gradient decoration to avoid rebuilding
class _GradientDecoration extends Decoration {
  const _GradientDecoration();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _GradientPainter();
  }
}

class _GradientPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0xFF0A2540), Color(0xFF05192D)],
          ).createShader(
            Rect.fromLTWH(
              offset.dx,
              offset.dy,
              configuration.size!.width,
              configuration.size!.height,
            ),
          );
    canvas.drawRect(
      Rect.fromLTWH(
        offset.dx,
        offset.dy,
        configuration.size!.width,
        configuration.size!.height,
      ),
      paint,
    );
  }
}

/// Logo widget with const constructor
class _LogoWidget extends StatelessWidget {
  const _LogoWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        'FinFlow',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

/// Title section widget
class _TitleSection extends StatelessWidget {
  final double screenWidth;

  const _TitleSection({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Secure Login',
      style: GoogleFonts.plusJakartaSans(
        fontSize: screenWidth < 360 ? 24 : 28,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
    );
  }
}

/// Subtitle section widget
class _SubtitleSection extends StatelessWidget {
  const _SubtitleSection();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Access your financial dashboard securely',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: Colors.white.withValues(alpha: 0.7),
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

/// Login form card widget
class _LoginFormCard extends StatelessWidget {
  final ValueChanged<bool>? onLoadingChanged;

  const _LoginFormCard({this.onLoadingChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: _LoginForm(onLoadingChanged: onLoadingChanged),
    );
  }
}

/// Login form with email and password fields
class _LoginForm extends StatefulWidget {
  final ValueChanged<bool>? onLoadingChanged;

  const _LoginForm({this.onLoadingChanged});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _EmailField(controller: _emailController),
          const SizedBox(height: 20),
          _PasswordField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onToggleVisibility: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 12),
          _ForgotPasswordButton(
            onTap: () => _forgotPassword(
              context,
              _emailController.text.trim(),
              widget.onLoadingChanged,
            ),
          ),
          const SizedBox(height: 24),
          _SignInButton(
            onPressed: () => _login(
              context,
              _formKey,
              _emailController,
              _passwordController,
              widget.onLoadingChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Email field widget
class _EmailField extends StatelessWidget {
  final TextEditingController controller;

  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16),
      decoration: _inputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        icon: Icons.email_outlined,
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }
}

/// Password field widget
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;

  const _PasswordField({
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16),
      decoration: _inputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.white.withValues(alpha: 0.6),
            size: 22,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }
}

/// Input decoration helper
InputDecoration _inputDecoration({
  required String labelText,
  required String hintText,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: GoogleFonts.plusJakartaSans(
      color: Colors.white.withValues(alpha: 0.7),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    hintText: hintText,
    hintStyle: GoogleFonts.plusJakartaSans(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 16,
    ),
    prefixIcon: Icon(
      icon,
      color: Colors.white.withValues(alpha: 0.6),
      size: 22,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.1),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white, width: 2),
    ),
  );
}

/// Forgot password button
class _ForgotPasswordButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ForgotPasswordButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          'Forgot Password?',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Sign in button
class _SignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A2540),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        'Sign In',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Social login divider
class _SocialLoginDivider extends StatelessWidget {
  const _SocialLoginDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
      ],
    );
  }
}

/// Social login buttons
class _SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;
  final bool isLoading;

  const _SocialLoginButtons({
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            icon: 'assets/google_icon.svg',
            label: 'Google',
            onPressed: isLoading ? null : onGoogleSignIn,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SocialButton(
            icon: null,
            label: 'Apple',
            isApple: true,
            onPressed: isLoading ? null : onAppleSignIn,
          ),
        ),
      ],
    );
  }
}

/// Sign up link
class _SignUpLink extends StatelessWidget {
  final VoidCallback onTap;

  const _SignUpLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontStyle: FontStyle.normal,
          ),
          children: [
            TextSpan(
              text: "Don't have an account? ",
              style: TextStyle(color: Colors.white70),
            ),
            TextSpan(
              text: 'Sign Up',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Social button widget (reusable)
class _SocialButton extends StatelessWidget {
  final String? icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isApple;

  const _SocialButton({
    this.icon,
    required this.label,
    required this.onPressed,
    this.isApple = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isApple)
            const Icon(Icons.apple, color: Colors.white, size: 22)
          else if (icon != null)
            SvgPicture.asset(icon!, height: 20, width: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Login Logic Helpers =====

Future<void> _login(
  BuildContext context,
  GlobalKey<FormState> formKey,
  TextEditingController emailController,
  TextEditingController passwordController,
  ValueChanged<bool>? onLoadingChanged,
) async {
  if (!formKey.currentState!.validate()) return;

  onLoadingChanged?.call(true);
  try {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Use Firebase Authentication for proper login
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    logDebug('Login successful: $email');
    // Navigation is handled by AuthWrapper via auth state changes
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No account found with this email';
        break;
      case 'wrong-password':
        errorMessage = 'Incorrect password';
        break;
      case 'invalid-email':
        errorMessage = 'Invalid email address';
        break;
      case 'user-disabled':
        errorMessage = 'This account has been disabled';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many login attempts. Please try again later.';
        break;
      case 'network-request-failed':
        errorMessage = 'Network error. Please check your internet connection';
        break;
      default:
        errorMessage = e.message ?? 'Login failed';
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.expenseColor,
        ),
      );
    }
  } catch (e) {
    logError('Login failed', error: e);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: AppTheme.expenseColor,
        ),
      );
    }
  } finally {
    onLoadingChanged?.call(false);
  }
}

Future<void> _forgotPassword(
  BuildContext context,
  String email,
  ValueChanged<bool>? onLoadingChanged,
) async {
  if (email.isEmpty || !email.contains('@')) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;
  }

  onLoadingChanged?.call(true);
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    logError('Password reset failed', error: e);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    onLoadingChanged?.call(false);
  }
}
