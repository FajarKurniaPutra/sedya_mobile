import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../global_layout.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../services/notification_service.dart';
import 'package:intl/intl.dart';
import '../widgets/skeleton.dart';
import 'task_detail_screen.dart';
import 'project_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notifService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final result = await _notifService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = result['notifications'] as List<AppNotification>;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification notif) async {
    if (notif.isRead) return;
    final success = await _notifService.markAsRead(notif.id).then((r) => r.success);
    if (success) {
      _loadNotifications();
    }
  }

  void _handleNotificationTap(AppNotification notif) {
    if (!notif.isRead) {
      _markAsRead(notif); // fire and forget agar tidak membuat UI nge-freeze
    }
    
    if (notif.referenceType == 'Task' && notif.referenceId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => TaskDetailScreen(
            taskId: notif.referenceId!,
            projectId: 0, // projectId diambil dari task detail API
          ),
        ),
      );
    } else if (notif.referenceType == 'Project' && notif.referenceId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ProjectDetailScreen(
            projectId: notif.referenceId!,
          ),
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _notifService.markAllAsRead().then((r) => r.success);
    if (success) {
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      title: 'Notifikasi',
      child: Column(
        children: [
          if (_notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(LucideIcons.checkCheck, size: 16),
                  label: const Text('Tandai Semua Dibaca'),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => const Skeleton(height: 80),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.bellOff, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada notifikasi',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    // TODO: [TUGAS REKAN] Task 2 - Bungkus ListView.separated di bawah ini dengan widget RefreshIndicator agar user bisa menarik layar ke bawah untuk memuat ulang daftar.
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final notif = _notifications[i];
                          final dateStr = notif.createdAt != null
                              ? DateFormat('dd MMM yyyy, HH:mm').format(notif.createdAt!)
                              : '';
                          
                          return InkWell(
                            onTap: () => _handleNotificationTap(notif),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: notif.isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: notif.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    notif.referenceType == 'Task'
                                        ? LucideIcons.clipboardList
                                        : notif.referenceType == 'Project'
                                            ? LucideIcons.folder
                                            : LucideIcons.bellRing,
                                    color: notif.isRead ? AppColors.textSecondary : AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notif.message,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          dateStr,
                                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}