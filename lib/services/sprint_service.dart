import '../models/models.dart';
import 'api_service.dart';

/// Service untuk mengambil data Sprint dari backend
class SprintService {
  final ApiService _api = ApiService();

  /// Ambil daftar sprint berdasarkan project
  Future<List<Sprint>> getSprints(int projectId) async {
    final resp = await _api.get('/sprints', queryParams: {'project_id': projectId.toString()});
    if (resp.success) {
      if (resp.data is List) {
        return (resp.data as List).map((j) => Sprint.fromJson(j)).toList();
      } else if (resp.data is Map && resp.data['data'] is List) {
        return (resp.data['data'] as List).map((j) => Sprint.fromJson(j)).toList();
      }
    }
    return [];
  }

  /// Buat sprint baru
  Future<ApiResponse> createSprint({
    required int projectId,
    String? name,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? goals,
  }) async {
    return _api.post('/sprints', body: {
      'project_id': projectId,
      'nama_sprint': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'goals': goals,
    });
  }

  /// Update sprint
  Future<ApiResponse> updateSprint(int sprintId, {
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? goals,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['nama_sprint'] = name;
    if (startDate != null) body['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) body['end_date'] = endDate.toIso8601String().split('T')[0];
    if (goals != null) body['goals'] = goals;
    return _api.put('/sprints/$sprintId', body: body);
  }

  /// Hapus sprint
  Future<ApiResponse> deleteSprint(int sprintId) async {
    return _api.delete('/sprints/$sprintId');
  }
}
