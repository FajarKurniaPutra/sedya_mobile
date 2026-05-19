import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../global_layout.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Login via Google Sign-In SDK → kirim ke backend Laravel
  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    // Capture reference before async gap
    final auth = context.read<AuthProvider>();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User membatalkan login
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final error = await auth.loginWithGoogle(
        email: googleUser.email,
        username: googleUser.displayName ?? googleUser.email.split('@')[0],
        googleId: googleUser.id,
        photoUrl: googleUser.photoUrl,
      );

      if (!mounted) return;

      if (error != null) {
        setState(() => _errorMessage = error);
      } else {
        Navigator.pushReplacementNamed(context, '/projects');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Login gagal: ${e.toString()}');
      }
    }

    if (mounted) {
      setState(() => _isGoogleLoading = false);
    }
  }

  // Menghapus demo login method

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      showNavbar: false,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              const Text(
                'SEDYA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk ke akun Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusOverdue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.statusOverdue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: AppColors.statusOverdue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.statusOverdue, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Google Sign-In button (Primary)
              _isGoogleLoading
                  ? const Center(child: CircularProgressIndicator())
                  : OutlinedButton.icon(
                      onPressed: _handleGoogleLogin,
                      icon: const Icon(LucideIcons.mail, color: AppColors.textSecondary),
                      label: const Text('Login dengan Google'),
                    ),
              const SizedBox(height: 24),

              // TODO: [TUGAS REKAN] Task 6 - Tampilkan pesan ScaffoldMessenger bertuliskan "Selamat Datang, [Nama User]" saat proses login sukses (sebelum Navigator.pushReplacementNamed).
            ],
          ),
        ),
      ),
    );
  }
}
