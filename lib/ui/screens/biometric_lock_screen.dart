import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Silakan autentikasi untuk masuk ke Sedya',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate && mounted) {
        context.read<AuthProvider>().unlockBiometric();
      }
    } catch (e) {
      debugPrint('Error auth: $e');
    }

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.fingerprint, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Aplikasi Terkunci',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan biometrik untuk membuka kunci',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            if (_isAuthenticating)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(LucideIcons.unlock),
                label: const Text('Buka Kunci'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
