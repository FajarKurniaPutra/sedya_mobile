import '../models/models.dart';
import 'api_service.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';

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

  /// Unduh Laporan (CSV atau PDF)
  Future<Uint8List?> downloadReport(int projectId, String format) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    final url = Uri.parse('${ApiConfig.baseUrl}/projects/$projectId/hr/export-$format');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('Download error: $e');
    }
    return null;
  }
}
