import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';
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

  /// Tambah catatan/note ke task (Mendukung pengiriman file)
  Future<ApiResponse> addNote(
    int taskId, 
    String message, {
    XFile? attachmentFile,
  }) async {
    // Siapkan teks catatannya
    final Map<String, String> fields = {
      'isi_catatan': message,
    };

    List<http.MultipartFile> files = [];

    if (attachmentFile != null) {
      final bytes = await attachmentFile.readAsBytes();
      files.add(http.MultipartFile.fromBytes(
        'attachments[]', 
        bytes,
        filename: attachmentFile.name,
      ));
    }

    // Gunakan postMultipart bawaan ApiService-mu yang sudah bersih
    return _api.postMultipart(
      '/tasks/$taskId/notes',
      fields: fields,
      files: files.isNotEmpty ? files : null,
    );
  }

  /// Ambil log history task
  Future<List<ActivityLog>> getTaskLogs(int taskId) async {
    final resp = await _api.get('/tasks/$taskId/logs');
    if (resp.success) {
      if (resp.data is List) {
        return (resp.data as List).map((j) => ActivityLog.fromJson(j)).toList();
      } else if (resp.data is Map && resp.data['data'] is List) {
        return (resp.data['data'] as List).map((j) => ActivityLog.fromJson(j)).toList();
      }
    }
    return [];
  }

  /// Upload file attachments ke task (maks 5)
  Future<ApiResponse> uploadAttachments(int taskId, List<PlatformFile> platformFiles) async {
    List<http.MultipartFile> files = [];

    for (var pf in platformFiles) {
      if (kIsWeb && pf.bytes != null) {
        files.add(http.MultipartFile.fromBytes(
          'attachments[]',
          pf.bytes!,
          filename: pf.name,
        ));
      } else if (!kIsWeb && pf.path != null) {
        files.add(await http.MultipartFile.fromPath(
          'attachments[]',
          pf.path!,
          filename: pf.name,
        ));
      }
    }

    if (files.isEmpty) return ApiResponse(success: false, message: 'Tidak ada file valid yang diplih');

    return _api.postMultipart(
      '/tasks/$taskId/attachments',
      fields: {},
      files: files,
    );
  }

  /// Menghapus lampiran pada tugas (type: 'images' atau 'documents')
  Future<ApiResponse> deleteAttachment(int taskId, String type, int attachmentId) async {
    return await _api.delete('/tasks/$taskId/$type/$attachmentId');
  }

  /// Unduh file attachment (type = 'images' | 'documents' | 'note-documents')
  Future<Uint8List> downloadAttachment(int taskId, String type, int attachmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final url = Uri.parse('${ApiConfig.apiUrl}/tasks/$taskId/$type/$attachmentId/download');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Gagal mengunduh. Status: ${response.statusCode}. Pesan: ${response.body}');
    }
  }
}