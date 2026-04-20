import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants.dart';

class GlobalLayout extends StatelessWidget {
  final Widget child;
  final bool showNavbar;
  final String title;

  const GlobalLayout({
    super.key,
    required this.child,
    this.showNavbar = true,
    this.title = 'SEDYA',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showNavbar
          ? AppBar(
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.settings),
                  onPressed: () {
                    // Navigate to settings (Halaman Pengaturan)
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(
                  color: AppColors.border,
                  height: 1.0,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480), // max-w-md constraint
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
