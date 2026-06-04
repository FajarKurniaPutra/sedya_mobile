import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(AuthProvider auth) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mengunggah foto profil...')),
        );
        final error = await auth.updateProfilePhoto(image.path);
        if (!mounted) return;
        
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memilih gambar'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editUsername(AuthProvider auth) async {
    final currentName = auth.currentUser?.username ?? '';
    final TextEditingController ctrl = TextEditingController(text: currentName);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Username'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Username Baru',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirm == true && ctrl.text.trim().isNotEmpty && ctrl.text.trim() != currentName) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menyimpan username...')),
      );
      final error = await auth.updateUsername(ctrl.text.trim());
      if (!mounted) return;
      
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username berhasil diperbarui!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await auth.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
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
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primary,
                        child: user?.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.photoUrl!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(
                                        user.name.isNotEmpty ? user.name[0] : '?',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                ),
                              )
                            : Text(
                                user?.name.isNotEmpty == true ? user!.name[0] : '?',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: auth.isLoading ? null : () => _pickImage(auth),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.name ?? 'User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: auth.isLoading ? null : () => _editUsername(auth),
                        child: Icon(LucideIcons.edit2, size: 16, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: AppColors.textSecondary),
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
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                title: Text('Tema Aplikasi (Dark Mode)'),
                secondary: Icon(LucideIcons.moon),
                value: themeNotifier.value == ThemeMode.dark,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    themeNotifier.value = val
                        ? ThemeMode.dark
                        : ThemeMode.light;
                  });
                },
              ),
            ),
            SizedBox(height: 12),
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
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Tentang Aplikasi'),
                          content: const Text(
                            'Sedya Corp adalah platform manajemen proyek modern yang membantu tim merencanakan, berkolaborasi, dan menyelesaikan proyek secara efisien.\n\nVersi 1.0.0',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Pusat Bantuan (CS)'),
                    leading: const Icon(LucideIcons.headphones),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Pusat Bantuan (CS)'),
                          content: const Text(
                            'Butuh bantuan? Tim kami siap membantu Anda.\n\nEmail: support@sedyacorp.com\nTelepon: +62 800 1234 5678\nJam Kerja: Senin - Jumat (09:00 - 17:00)',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Syarat & Ketentuan'),
                    leading: const Icon(LucideIcons.fileText),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Syarat & Ketentuan'),
                          content: const SingleChildScrollView(
                            child: Text(
                              '1. Penerimaan Syarat\nDengan mengakses atau menggunakan layanan Sedya Corp, Anda setuju untuk terikat oleh Syarat dan Ketentuan ini. Jika Anda tidak setuju dengan bagian mana pun dari ketentuan ini, Anda tidak diperkenankan untuk menggunakan layanan kami.\n\n'
                              '2. Privasi Data\nKami sangat menjaga kerahasiaan data pengguna dan proyek. Data yang dikumpulkan (termasuk tugas, profil, dan berkas lampiran) semata-mata digunakan untuk kepentingan operasional platform dan tidak akan disebarkan ke pihak ketiga tanpa izin eksplisit.\n\n'
                              '3. Tanggung Jawab Pengguna\nAnda bertanggung jawab untuk menjaga kerahasiaan kata sandi Anda dan akun, serta bertanggung jawab penuh atas semua aktivitas yang terjadi di bawah sandi atau akun Anda.\n\n'
                              '4. Perubahan Layanan\nSedya Corp berhak untuk mengubah atau menghentikan, sementara atau secara permanen, layanan (atau bagiannya) dengan atau tanpa pemberitahuan kapan saja. Kami tidak bertanggung jawab kepada Anda atau kepada pihak ketiga atas modifikasi, penangguhan, atau penghentian layanan.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: const Text(
                  'Upgrade ke Fitur Pro',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: const Text(
                  'Dapatkan fitur eksklusif',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                leading: const Icon(LucideIcons.crown, color: Colors.black87),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  color: Colors.black87,
                  size: 16,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Halaman berlangganan Sedya Pro sedang dalam pengembangan.',
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Logout Action
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: Icon(
                LucideIcons.logOut,
                color: AppColors.statusOverdue,
              ),
              label: Text(
                'Keluar',
                style: TextStyle(color: AppColors.statusOverdue),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.statusOverdue),
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
