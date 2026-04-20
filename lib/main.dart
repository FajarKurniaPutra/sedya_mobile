import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/theme_notifier.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/project_list_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() {
  runApp(const SedyaApp());
}

class SedyaApp extends StatelessWidget {
  const SedyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'SEDYA',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/projects': (context) => const ProjectListScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
