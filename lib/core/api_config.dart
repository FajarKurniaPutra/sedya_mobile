/// Konfigurasi koneksi API backend Sedya
class ApiConfig {
  // Gunakan 10.0.2.2 untuk Android emulator (alias ke localhost host machine)
  // Gunakan localhost atau IP lokal untuk iOS simulator / device fisik
  static const String baseUrl = 'http://10.66.66.56:8000';
  static const String apiUrl = '$baseUrl/api';

  // Timeout dalam detik
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
}
