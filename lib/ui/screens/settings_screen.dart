import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../global_layout.dart';
import '../../core/constants.dart';
import '../../core/theme_notifier.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _handleLogout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return GlobalLayout(
      title: 'Pengaturan',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Details
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primary,
                    child: user?.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user!.photoUrl!,
                              width: 96, height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Text(
                                user.name.isNotEmpty ? user.name[0] : '?',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        : Text(
                            user?.name.isNotEmpty == true ? user!.name[0] : '?',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            
            // Application Settings
            const Text(
              'Pengaturan Aplikasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                title: const Text('Tema Aplikasi (Dark Mode)'),
                secondary: const Icon(LucideIcons.moon),
                value: themeNotifier.value == ThemeMode.dark,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Tentang Aplikasi'),
                    leading: const Icon(LucideIcons.info),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Pusat Bantuan (CS)'),
                    leading: const Icon(LucideIcons.headphones),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menghubungkan ke Customer Service...')));
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Syarat & Ketentuan'),
                    leading: const Icon(LucideIcons.fileText),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Halaman Syarat & Ketentuan akan segera hadir.')));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: const Text('Upgrade ke Fitur Pro', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                subtitle: const Text('Dapatkan fitur eksklusif', style: TextStyle(color: Colors.black54, fontSize: 12)),
                leading: const Icon(LucideIcons.crown, color: Colors.black87),
                trailing: const Icon(LucideIcons.chevronRight, color: Colors.black87, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Halaman berlangganan Sedya Pro sedang dalam pengembangan.')));
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Logout Action
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(LucideIcons.logOut, color: AppColors.statusOverdue),
              label: const Text(
                'Keluar',
                style: TextStyle(color: AppColors.statusOverdue),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.statusOverdue),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
