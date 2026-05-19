import '../models/models.dart';
import 'api_service.dart';

/// Service untuk Activity Logs
class ActivityLogService {
  final ApiService _api = ApiService();

  /// Ambil activity log (bisa difilter berdasarkan project_id atau task_id)
  Future<List<ActivityLog>> getActivityLogs({int? projectId, int? taskId}) async {
    final queryParams = <String, String>{};
    if (projectId != null) {
      queryParams['project_id'] = projectId.toString();
    } else if (taskId != null) {
      queryParams['task_id'] = taskId.toString();
    }

    final resp = await _api.get('/activity-logs', queryParams: queryParams);
    
    if (resp.success) {
      if (resp.data is List) {
        return (resp.data as List).map((j) => ActivityLog.fromJson(j)).toList();
      } else if (resp.data is Map && resp.data['data'] is List) {
        return (resp.data['data'] as List).map((j) => ActivityLog.fromJson(j)).toList();
      }
    }
    return [];
  }
}
