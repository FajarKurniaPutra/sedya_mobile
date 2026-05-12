import '../models/models.dart';
import 'api_service.dart';

/// Service untuk operasi CRUD Task, notes, status, dan images
class TaskService {
  final ApiService _api = ApiService();

  /// Ambil daftar task berdasarkan project
  Future<List<TaskItem>> getTasks(int projectId) async {
    final resp = await _api.get('/tasks', queryParams: {'project_id': projectId.toString()});
    if (resp.success) {
      if (resp.data is List) {
        return (resp.data as List).map((j) => TaskItem.fromJson(j)).toList();
      } else if (resp.data is Map && resp.data['data'] is List) {
        return (resp.data['data'] as List).map((j) => TaskItem.fromJson(j)).toList();
      }
    }
    return [];
  }

  /// Ambil detail task (termasuk notes, PIC, images)
  Future<TaskItem?> getTaskDetail(int taskId) async {
    final resp = await _api.get('/tasks/$taskId');
    if (resp.success && resp.data != null) {
      return TaskItem.fromJson(resp.data);
    }
    return null;
  }

  /// Buat task baru
  Future<ApiResponse> createTask({
    required int projectId,
    required String name,
    String? description,
    DateTime? deadline,
    int? weight,
    String? label,
    String? priority,
    required List<int> picIds,
  }) async {
    return _api.post('/tasks', body: {
      'project_id': projectId,
      'nama_task': name,
      'detail_task': description,
      'deadline': deadline?.toIso8601String().split('T')[0],
      'bobot': weight ?? 1,
      'label': label,
      'prioritas': priority ?? 'Sedang',
      'pic_ids': picIds,
    });
  }

  /// Update task
  Future<ApiResponse> updateTask(int taskId, {
    String? name,
    String? description,
    DateTime? deadline,
    int? weight,
    String? label,
    String? priority,
    List<int>? picIds,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['nama_task'] = name;
    if (description != null) body['detail_task'] = description;
    if (deadline != null) body['deadline'] = deadline.toIso8601String().split('T')[0];
    if (weight != null) body['bobot'] = weight;
    if (label != null) body['label'] = label;
    if (priority != null) body['prioritas'] = priority;
    if (picIds != null) body['pic_ids'] = picIds;
    return _api.put('/tasks/$taskId', body: body);
  }

  /// Update status task
  Future<ApiResponse> updateStatus(int taskId, String backendStatus) async {
    return _api.put('/tasks/$taskId/status', body: {
      'status_task': backendStatus,
    });
  }

  /// Hapus task
  Future<ApiResponse> deleteTask(int taskId) async {
    return _api.delete('/tasks/$taskId');
  }

  /// Tambah catatan/note ke task
  Future<ApiResponse> addNote(int taskId, String message) async {
    return _api.post('/tasks/$taskId/notes', body: {
      'isi_catatan': message,
    });
  }

  /// Ambil log history task
  Future<List<Map<String, dynamic>>> getTaskLogs(int taskId) async {
    final resp = await _api.get('/tasks/$taskId/logs');
    if (resp.success && resp.data is List) {
      return (resp.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}
