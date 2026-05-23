import 'dart:convert';
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
        // Verifikasi token masih valid via API
        final resp = await _api.get('/user');
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
  }) async {
    _isLoading = true;
    notifyListeners();

    final resp = await _api.post('/login/google', body: {
      'email': email,
      'username': username,
      'google_id': googleId,
      'photo_url': photoUrl,
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
