import '../models/models.dart';
import 'api_service.dart';

/// Service untuk Notifications
class NotificationService {
  final ApiService _api = ApiService();

  /// Ambil notifikasi user
  Future<Map<String, dynamic>> getNotifications() async {
    final resp = await _api.get('/notifications');
    if (resp.success && resp.data is Map<String, dynamic>) {
      final notifications = (resp.data['notifications'] as List?)
          ?.map((j) => AppNotification.fromJson(j))
          .toList() ?? [];
      final unreadCount = resp.data['unread_count'] ?? 0;
      return {
        'notifications': notifications,
        'unread_count': unreadCount,
      };
    }
    return {'notifications': <AppNotification>[], 'unread_count': 0};
  }

  /// Tandai notifikasi sebagai sudah dibaca
  Future<ApiResponse> markAsRead(int notificationId) async {
    return _api.put('/notifications/$notificationId/read');
  }

  /// Tandai semua notifikasi sebagai sudah dibaca
  Future<ApiResponse> markAllAsRead() async {
    return _api.put('/notifications/read-all');
  }

  /// Registrasi FCM Token
  Future<ApiResponse> registerFcmToken(String token, {String deviceType = 'android'}) async {
    return _api.post('/fcm/register', body: {
      'token': token,
      'device_type': deviceType,
    });
  }

  /// Hapus FCM Token
  Future<ApiResponse> unregisterFcmToken(String token) async {
    return _api.delete('/fcm/unregister?token=$token'); // Backend expect request body or query string, we can pass via body or query. Since it's DELETE, query is safer unless API handles DELETE body. But in API we used $request->token. We should use query param if using our ApiService delete method which doesn't take body.
  }
}