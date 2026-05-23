import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants.dart';
import '../services/notification_service.dart';

class GlobalLayout extends StatefulWidget {
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
  State<GlobalLayout> createState() => _GlobalLayoutState();
}

class _GlobalLayoutState extends State<GlobalLayout> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.showNavbar) {
      _fetchUnreadCount();
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final res = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _unreadCount = res['unread_count'] ?? 0;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showNavbar
          ? AppBar(
              title: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: false,
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.bell),
                      onPressed: () async {
                        final currentRoute = ModalRoute.of(
                          context,
                        )?.settings.name;
                        if (currentRoute == '/notifications') return;
                        if (currentRoute == '/settings') {
                          await Navigator.pushReplacementNamed(
                            context,
                            '/notifications',
                          );
                        } else {
                          await Navigator.pushNamed(context, '/notifications');
                        }
                        _fetchUnreadCount();
                      },
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.settings),
                  onPressed: () {
                    final currentRoute = ModalRoute.of(context)?.settings.name;
                    if (currentRoute == '/settings') return;
                    if (currentRoute == '/notifications') {
                      Navigator.pushReplacementNamed(context, '/settings');
                    } else {
                      Navigator.pushNamed(context, '/settings');
                    }
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(color: AppColors.border, height: 1.0),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 480,
            ), // max-w-md constraint
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
