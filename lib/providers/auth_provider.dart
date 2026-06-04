import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../core/api_config.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Provider global untuk state autentikasi & user aktif.
/// Menggantikan pattern `DummyData.currentUser` yang statis.
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  AppUser? _currentUser;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;

  AppUser? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _currentUser != null && _token != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Role user saat ini di konteks project tertentu
  String get userRole => _currentUser?.role ?? 'Anggota';

  /// Inisialisasi: cek apakah ada token tersimpan
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(ApiConfig.tokenKey);
      final userJson = prefs.getString(ApiConfig.userKey);
      if (_token != null && userJson != null) {
        _currentUser = AppUser.fromJson(jsonDecode(userJson));
        // Validasi token ke server (opsional, tp bagus buat security)
        // Di sini kita sekalian fetch data user terbaru jika diperlukan.
        final resp = await _api.get('/me');
        if (resp.success && resp.data != null) {
          _currentUser = AppUser.fromJson(resp.data);
          await _saveUserLocally(_currentUser!);
        } else {
          // Token expired/invalid
          await logout();
        }
      }
    } catch (_) {
      // Jika gagal, tetap lanjut tanpa login
    }

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  /// Login via Google Sign-In
  Future<String?> loginWithGoogle({
    required String email,
    required String username,
    required String googleId,
    String? photoUrl,
    bool isRegistering = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    final resp = await _api.post('/login/google', body: {
      'email': email,
      'username': username,
      'google_id': googleId,
      'photo_url': photoUrl,
      'is_registering': isRegistering,
    }, withAuth: false);

    _isLoading = false;

    if (resp.success && resp.data != null) {
      _token = resp.data['access_token'];
      _currentUser = AppUser.fromJson(resp.data['user']);

      await _api.saveToken(_token!);
      await _saveUserLocally(_currentUser!);

      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          final deviceType = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
          await NotificationService().registerFcmToken(fcmToken, deviceType: deviceType);
        }
      } catch (e) {
        debugPrint('Gagal register FCM Token: $e');
      }

      notifyListeners();
      return null; // success, no error
    }

    notifyListeners();
    return resp.message.isNotEmpty ? resp.message : 'Login gagal. Coba lagi.';
  }

  /// Manual Login (Email & Password)
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final resp = await _api.post('/login', body: {
      'email': email,
      'password': password,
    }, withAuth: false);

    _isLoading = false;

    if (resp.success && resp.data != null) {
      _token = resp.data['access_token'];
      _currentUser = AppUser.fromJson(resp.data['user']);

      await _api.saveToken(_token!);
      await _saveUserLocally(_currentUser!);

      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          final deviceType = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
          await NotificationService().registerFcmToken(fcmToken, deviceType: deviceType);
        }
      } catch (e) {
        debugPrint('Gagal register FCM Token: $e');
      }

      notifyListeners();
      return null;
    }

    notifyListeners();
    return resp.message.isNotEmpty ? resp.message : 'Login gagal. Email atau password salah.';
  }

  /// Register (Email & Password)
  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final resp = await _api.post('/register', body: {
      'username': username,
      'email': email,
      'password': password,
      'is_registering': true,
    }, withAuth: false);

    _isLoading = false;

    if (resp.success && resp.data != null) {
      _token = resp.data['access_token'];
      _currentUser = AppUser.fromJson(resp.data['user']);

      await _api.saveToken(_token!);
      await _saveUserLocally(_currentUser!);

      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          final deviceType = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
          await NotificationService().registerFcmToken(fcmToken, deviceType: deviceType);
        }
      } catch (e) {
        debugPrint('Gagal register FCM Token: $e');
      }

      notifyListeners();
      return null;
    }

    notifyListeners();
    return resp.message.isNotEmpty ? resp.message : 'Pendaftaran gagal. Periksa kembali data Anda.';
  }

  /// Update username
  Future<String?> updateUsername(String newUsername) async {
    _isLoading = true;
    notifyListeners();
    
    final resp = await _api.put('/user/username', body: {'username': newUsername});
    if (resp.success) {
      await refreshUser();
      _isLoading = false;
      notifyListeners();
      return null;
    }
    
    _isLoading = false;
    notifyListeners();
    return resp.message.isNotEmpty ? resp.message : 'Gagal memperbarui username';
  }

  /// Update foto profil
  Future<String?> updateProfilePhoto(String filePath) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final file = await http.MultipartFile.fromPath('photo', filePath);
      final resp = await _api.postMultipart('/user/photo', files: [file]);
      if (resp.success) {
        await refreshUser();
        _isLoading = false;
        notifyListeners();
        return null;
      }
      _isLoading = false;
      notifyListeners();
      return resp.message.isNotEmpty ? resp.message : 'Gagal memperbarui foto profil';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Gagal memproses file gambar';
    }
  }

  /// Logout — hapus token & data lokal
  Future<void> logout() async {
    if (_token != null) {
      await _api.post('/logout'); // Best-effort, ignore error
    }
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await NotificationService().unregisterFcmToken(fcmToken);
      }
    } catch (_) {}

    await _api.clearToken();
    try {
      await GoogleSignIn().disconnect();
    } catch (_) {}
    _currentUser = null;
    _token = null;
    notifyListeners();
  }

  /// Update role user di konteks proyek tertentu
  void setProjectRole(String role) {
    if (_currentUser != null) {
      _currentUser!.role = role;
      notifyListeners();
    }
  }

  /// Simpan user data ke SharedPreferences
  Future<void> _saveUserLocally(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.userKey, jsonEncode(user.toJson()));
  }

  /// Refresh data user dari server
  Future<void> refreshUser() async {
    final resp = await _api.get('/user');
    if (resp.success && resp.data != null) {
      _currentUser = AppUser.fromJson(resp.data);
      await _saveUserLocally(_currentUser!);
      notifyListeners();
    }
  }
}
