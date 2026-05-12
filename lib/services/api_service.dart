import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';

/// Centralized HTTP client yang menangani:
/// - Auto-attach Bearer token dari SharedPreferences
/// - Standardized JSON parsing
/// - Error handling terpusat
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Mendapatkan token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }

  /// Menyimpan token ke SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.tokenKey, token);
  }

  /// Menghapus token (logout)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.tokenKey);
    await prefs.remove(ApiConfig.userKey);
  }

  /// Cek apakah user sudah login (token tersedia)
  Future<bool> hasToken() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  /// Build headers dengan Authorization Bearer
  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// GET request
  Future<ApiResponse> get(String endpoint, {Map<String, String>? queryParams, bool withAuth = true, int retries = 1}) async {
    int attempt = 0;
    while (attempt <= retries) {
      try {
        var uri = Uri.parse('${ApiConfig.apiUrl}$endpoint');
        if (queryParams != null && queryParams.isNotEmpty) {
          uri = uri.replace(queryParameters: queryParams);
        }
        final response = await http.get(uri, headers: await _headers(withAuth: withAuth))
            .timeout(const Duration(seconds: ApiConfig.connectTimeout));
        return _handleResponse(response);
      } catch (e) {
        if (attempt == retries) {
          return ApiResponse(success: false, message: _parseError(e), statusCode: 0);
        }
        attempt++;
        await Future.delayed(const Duration(milliseconds: 1500)); // Wait before retry
      }
    }
    return ApiResponse(success: false, message: 'Gagal memuat', statusCode: 0);
  }

  /// POST request (JSON body)
  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body, bool withAuth = true, int retries = 1}) async {
    int attempt = 0;
    while (attempt <= retries) {
      try {
        final uri = Uri.parse('${ApiConfig.apiUrl}$endpoint');
        final response = await http.post(uri, headers: await _headers(withAuth: withAuth), body: body != null ? jsonEncode(body) : null)
            .timeout(const Duration(seconds: ApiConfig.connectTimeout));
        return _handleResponse(response);
      } catch (e) {
        if (attempt == retries) {
          return ApiResponse(success: false, message: _parseError(e), statusCode: 0);
        }
        attempt++;
        await Future.delayed(const Duration(milliseconds: 1500)); // Wait before retry
      }
    }
    return ApiResponse(success: false, message: 'Gagal memuat', statusCode: 0);
  }

  /// PUT request
  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiUrl}$endpoint');
      final response = await http.put(uri, headers: await _headers(), body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: ApiConfig.connectTimeout));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: _parseError(e), statusCode: 0);
    }
  }

  /// DELETE request
  Future<ApiResponse> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiUrl}$endpoint');
      final response = await http.delete(uri, headers: await _headers())
          .timeout(const Duration(seconds: ApiConfig.connectTimeout));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: _parseError(e), statusCode: 0);
    }
  }

  /// POST multipart (untuk upload file/gambar)
  Future<ApiResponse> postMultipart(String endpoint, {Map<String, String>? fields, List<http.MultipartFile>? files}) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);
      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      if (fields != null) request.fields.addAll(fields);
      if (files != null) request.files.addAll(files);

      final streamed = await request.send().timeout(const Duration(seconds: ApiConfig.receiveTimeout));
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: _parseError(e), statusCode: 0);
    }
  }

  /// Parse response dari server
  ApiResponse _handleResponse(http.Response response) {
    dynamic data;
    String message = '';

    try {
      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }
    } catch (_) {
      data = null;
    }

    final success = response.statusCode >= 200 && response.statusCode < 300;

    if (!success && data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? 'Terjadi kesalahan pada server.';
    }

    if (response.statusCode == 401) {
      message = 'Sesi telah berakhir. Silakan login kembali.';
      clearToken(); // auto-clear expired token
    }

    return ApiResponse(
      success: success,
      data: data,
      message: message,
      statusCode: response.statusCode,
    );
  }

  /// Parse error exception menjadi pesan user-friendly
  String _parseError(Object e) {
    if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
      return 'Tidak dapat terhubung ke server. Pastikan server backend aktif.';
    }
    if (e.toString().contains('TimeoutException')) {
      return 'Koneksi timeout. Periksa jaringan Anda.';
    }
    return 'Terjadi kesalahan: ${e.toString()}';
  }
}

/// Model response standar dari API
class ApiResponse {
  final bool success;
  final dynamic data;
  final String message;
  final int statusCode;

  ApiResponse({required this.success, this.data, this.message = '', this.statusCode = 0});
}
