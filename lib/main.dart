import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/theme_notifier.dart';
import 'providers/auth_provider.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/project_list_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/notification_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'ui/screens/task_detail_screen.dart';
import 'ui/screens/project_detail_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
      ],
      child: const SedyaApp(),
    ),
  );
}

class SedyaApp extends StatefulWidget {
  const SedyaApp({super.key});

  @override
  State<SedyaApp> createState() => _SedyaAppState();
}

class _SedyaAppState extends State<SedyaApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    // Handling click when app is terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationClick(initialMessage);
      });
    }

    // Handling click when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });
  }

  void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;
    final String? refType = data['reference_type'];
    final String? refIdStr = data['reference_id'];
    
    if (refType == 'Task' && refIdStr != null) {
      final taskId = int.tryParse(refIdStr);
      if (taskId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(taskId: taskId, projectId: 0),
          ),
        );
      }
    } else if (refType == 'Project' && refIdStr != null) {
      final projectId = int.tryParse(refIdStr);
      if (projectId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(projectId: projectId),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'SEDYA',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              // Tampilkan splash loading saat inisialisasi
              if (!auth.isInitialized) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              // Jika sudah login, langsung ke project list
              if (!auth.isLoggedIn) {
                return const LoginScreen();
              }
              return const ProjectListScreen();
            },
          ),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/projects': (context) => const ProjectListScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/notifications': (context) => const NotificationScreen(),
          },
        );
      },
    );
  }
}
