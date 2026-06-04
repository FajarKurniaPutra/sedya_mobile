import '../models/models.dart';
import 'api_service.dart';

/// Service untuk operasi CRUD Project
class ProjectService {
  final ApiService _api = ApiService();

  /// Ambil semua project milik user yang login
  Future<List<Project>> getProjects() async {
    final resp = await _api.get('/projects');
    if (resp.success) {
      if (resp.data is List) {
        return (resp.data as List).map((j) => Project.fromJson(j)).toList();
      } else if (resp.data is Map && resp.data['data'] is List) {
        return (resp.data['data'] as List)
            .map((j) => Project.fromJson(j))
            .toList();
      }
    }
    return [];
  }

  /// Ambil detail project termasuk members
  Future<Project?> getProjectDetail(int projectId) async {
    final resp = await _api.get('/projects/$projectId');
    if (resp.success && resp.data != null) {
      return Project.fromJson(resp.data);
    }
    return null;
  }

  /// Buat project baru
  Future<ApiResponse> createProject({
    required String name,
    String? code,
    String? description,
    String? phase,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _api.post(
      '/projects',
      body: {
        'nama_projek': name,
        'kode_projek': code,
        'deskripsi': description,
        'tahapan_projek': phase ?? 'Perencanaan',
        if (type != null) 'jenis_projek': type,
        'tgl_mulai': startDate?.toIso8601String().split('T')[0],
        'estimasi_selesai': endDate?.toIso8601String().split('T')[0],
      },
    );
  }

  /// Bergabung ke proyek menggunakan kode referral
  Future<ApiResponse> joinProject(String referralCode) async {
    // Sesuaikan endpoint '/projects/join' dan nama body 'kode_proyek'
    // dengan yang dibuat oleh teman backend-mu ya!
    return _api.post('/projects/join', body: {'kode_proyek': referralCode});
  }

  /// Update project
  Future<ApiResponse> updateProject(
    int projectId, {
    required String name,
    String? code,
    String? description,
    String? phase,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _api.put(
      '/projects/$projectId',
      body: {
        'nama_projek': name,
        'kode_projek': code,
        'deskripsi': description,
        'tahapan_projek': phase,
        if (type != null) 'jenis_projek': type,
        'tgl_mulai': startDate?.toIso8601String().split('T')[0],
        'estimasi_selesai': endDate?.toIso8601String().split('T')[0],
      },
    );
  }

  /// Toggle status aktif/nonaktif project
  Future<ApiResponse> toggleStatus(int projectId) async {
    return _api.put('/projects/$projectId/toggle-status');
  }

  /// Invite member ke project
  Future<ApiResponse> inviteMember(int projectId, int userId) async {
    return _api.post('/projects/$projectId/invite', body: {'user_id': userId});
  }

  /// Set role member
  Future<ApiResponse> setMemberRole(
    int projectId,
    int memberId,
    int roleId,
  ) async {
    return _api.put(
      '/projects/$projectId/members/$memberId/role',
      body: {'role_id': roleId},
    );
  }

  /// Hapus project
  Future<ApiResponse> deleteProject(int projectId) async {
    return _api.delete('/projects/$projectId');
  }

  /// Toggle status member (aktif/nonaktif)
  Future<ApiResponse> toggleMemberStatus(int projectId, int memberId, {String? deactivationReason}) async {
    return _api.put(
      '/projects/$projectId/members/$memberId/toggle-status',
      body: deactivationReason != null ? {'deactivation_reason': deactivationReason} : null,
    );
  }

  /// Keluarkan anggota dari proyek (hanya bisa jika status nonaktif)
  Future<ApiResponse> removeMember(int projectId, int memberId) async {
    return _api.delete('/projects/$projectId/members/$memberId');
  }

  /// Mengubah role anggota proyek (khusus Pemimpin Proyek)
  Future<ApiResponse> updateMemberRole(
    int projectId,
    int memberUserId,
    String newRole,
  ) async {
    return _api.put(
      '/projects/$projectId/members/$memberUserId/role',
      body: {
        'role': newRole, // Misal: 'Asisten' atau 'Anggota'
      },
    );
  }

  /// Mengubah status aktif/nonaktif anggota proyek (alias)
  Future<ApiResponse> toggleMemberStatusByUser(
    int projectId,
    int memberUserId,
    {String? deactivationReason}
  ) async {
    return toggleMemberStatus(projectId, memberUserId, deactivationReason: deactivationReason);
  }
}
