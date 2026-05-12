import '../models/models.dart';
import 'api_service.dart';

/// Service untuk HR Analytics & Report
class HRService {
  final ApiService _api = ApiService();

  /// Ambil data overview proyek (statistik umum)
  Future<Map<String, dynamic>?> getOverview(int projectId) async {
    final resp = await _api.get('/projects/$projectId/hr/overview');
    if (resp.success && resp.data is Map<String, dynamic>) {
      return resp.data;
    }
    return null;
  }

  /// Ambil data performa tim per anggota
  Future<List<HRMemberPerformance>> getTeamPerformance(int projectId) async {
    final resp = await _api.get('/projects/$projectId/hr/team-performance');
    if (resp.success && resp.data is List) {
      return (resp.data as List).map((j) => HRMemberPerformance.fromJson(j)).toList();
    }
    return [];
  }

  /// Ambil data analisa beban kerja
  Future<Map<String, dynamic>?> getWorkloadAnalysis(int projectId) async {
    final resp = await _api.get('/projects/$projectId/hr/workload');
    if (resp.success && resp.data is Map<String, dynamic>) {
      return resp.data;
    }
    return null;
  }
}
