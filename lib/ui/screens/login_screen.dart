import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
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
  bool _isManualLoading = false;
  String? _errorMessage;

  bool _isLoginMode = true; // Toggle between Login and Register

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController(); // For register only
  bool _obscurePassword = true;

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
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _usernameController.clear();
    });
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final error = await auth.loginWithGoogle(
        email: googleUser.email,
        username: googleUser.displayName ?? googleUser.email.split('@')[0],
        googleId: googleUser.id,
        photoUrl: googleUser.photoUrl,
        isRegistering: !_isLoginMode,
      );

      if (!mounted) return;

      if (error != null) {
        setState(() => _errorMessage = error);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Selamat Datang, ${auth.currentUser?.name ?? 'User'}"),
            backgroundColor: AppColors.primary,
          ),
        );
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

  Future<void> _submitManual() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isManualLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    String? error;

    if (_isLoginMode) {
      error = await auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      error = await auth.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isManualLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selamat Datang, ${auth.currentUser?.name ?? 'User'}"),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pushReplacementNamed(context, '/projects');
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController();
    bool isSending = false;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Lupa Password', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Masukkan alamat email Anda. Kami akan mengirimkan tautan untuk mengatur ulang password.', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email Anda',
                    prefixIcon: const Icon(LucideIcons.mail),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSending ? null : () async {
                  if (emailCtrl.text.trim().isEmpty || !emailCtrl.text.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Format email tidak valid!'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  setStateDialog(() => isSending = true);

                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: emailCtrl.text.trim());
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link reset password telah dikirim. Periksa inbox atau folder spam Anda.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    setStateDialog(() => isSending = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message ?? 'Gagal mengirim link reset.'), backgroundColor: Colors.red),
                      );
                    }
                  } catch (e) {
                    setStateDialog(() => isSending = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terjadi kesalahan. Coba lagi nanti.'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSending
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Kirim', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (!_isLoginMode) {
      if (value.length < 8) {
        return 'Password minimal 8 karakter';
      }
      final hasUppercase = value.contains(RegExp(r'[A-Z]'));
      final hasLowercase = value.contains(RegExp(r'[a-z]'));
      final hasDigits = value.contains(RegExp(r'[0-9]'));
      final hasSpecialCharacters = value.contains(RegExp(r'[@$!%*#?&]'));
      
      if (!hasUppercase || !hasLowercase || !hasDigits || !hasSpecialCharacters) {
        return 'Password harus mengandung huruf besar, huruf kecil,\nangka, dan simbol (@\$!%*#?&).';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      showNavbar: false,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  _isLoginMode ? 'Selamat Datang Kembali' : 'Buat Akun Baru',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode 
                      ? 'Silakan masuk menggunakan email dan password Anda.' 
                      : 'Lengkapi data di bawah untuk mendaftar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

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
                        Icon(LucideIcons.alertCircle, color: AppColors.statusOverdue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: AppColors.statusOverdue, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],



                if (!_isLoginMode) ...[
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(LucideIcons.user),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Username tidak boleh kosong';
                      if (val.trim().length < 3) return 'Username minimal 3 karakter';
                      if (val.trim().length > 50) return 'Username maksimal 50 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Email',
                    prefixIcon: Icon(LucideIcons.mail),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email tidak boleh kosong';
                    if (!val.contains('@') || !val.contains('.')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: _isLoginMode ? null : 'Min 8 karakter (huruf, simbol, dan angka)',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(LucideIcons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                
                if (_isLoginMode) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text('Lupa Password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  const SizedBox(height: 32),
                ],

                // Submit Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isManualLoading || _isGoogleLoading ? null : _submitManual,
                    child: _isManualLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isLoginMode ? 'Masuk' : 'Daftar'),
                  ),
                ),
                
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('ATAU', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 24),

                // Google Sign-In button
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isManualLoading || _isGoogleLoading ? null : _handleGoogleLogin,
                    icon: _isGoogleLoading
                        ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(LucideIcons.chrome, color: AppColors.textSecondary, size: 20),
                    label: Text(_isGoogleLoading ? 'Memproses...' : (_isLoginMode ? 'Masuk dengan Google' : 'Daftar dengan Google')),
                  ),
                ),
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoginMode ? 'Belum punya akun?' : 'Sudah punya akun?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: _isManualLoading || _isGoogleLoading ? null : _switchMode,
                      child: Text(
                        _isLoginMode ? 'Daftar sekarang' : 'Masuk',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
