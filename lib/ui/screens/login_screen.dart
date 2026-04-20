import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../global_layout.dart';
import '../../core/constants.dart';
import '../../core/dummy_data.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

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

  void _handleLogin() {
    // Navigate to projects screen
    Navigator.pushReplacementNamed(context, '/projects');
  }

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
              const Icon(
                LucideIcons.boxes,
                size: 64,
                color: AppColors.primary,
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
              // Dropdown pilih akun demo (single value)
              DropdownButtonFormField<String>(
                initialValue: DummyData.currentUser.id,
                decoration: const InputDecoration(
                  labelText: 'Pilih Akun Demo',
                  prefixIcon: Icon(LucideIcons.user),
                ),
                isExpanded: true,
                // Tampilan yang muncul saat dropdown TERBUKA (menu items)
                items: DummyData.allUsers.map((user) {
                  return DropdownMenuItem<String>(
                    value: user.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(user.name[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(user.role, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                // Tampilan yang muncul saat dropdown TERTUTUP (selected)
                selectedItemBuilder: (context) {
                  return DummyData.allUsers.map((user) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${user.name} — ${user.role}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList();
                },
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      DummyData.currentUser = DummyData.allUsers.firstWhere((u) => u.id == val);
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleLogin,
                child: const Text('Login'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'atau',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _handleLogin, // mock action
                icon: const Icon(LucideIcons.mail, color: AppColors.textSecondary),
                label: const Text('Login dengan Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
