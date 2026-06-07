/// Konfigurasi koneksi API backend Sedya
class ApiConfig {
  /// Ubah menjadi [true] jika aplikasi akan di-build untuk Rilis/Production.
  /// Ubah menjadi [false] untuk pengembangan (Development) lokal.
  static const bool isProduction = true; 

  // URL Lokal (Development)
  // Gunakan 10.0.2.2 untuk Android emulator, atau IP Wi-Fi untuk device fisik
  static const String _localUrl = 'http://192.168.1.34:8000';
  
  // URL Hosting (Production)
  // TODO: Ganti dengan URL hosting sedya_web asli Anda (misal: https://api.namadomain.com)
  static const String _productionUrl = 'https://sedya-inc.up.railway.app';

  // Base URL Otomatis
  static const String baseUrl = isProduction ? _productionUrl : _localUrl;
  static const String apiUrl = '$baseUrl/api';

  // Timeout dalam detik
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
}
