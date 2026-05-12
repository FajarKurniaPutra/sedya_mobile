// File ini dipertahankan untuk referensi development.
// Pada production, semua data diambil dari API backend via services.
// 
// File ini TIDAK digunakan lagi setelah integrasi backend.
// Lihat: lib/services/ untuk pengambilan data dari API.
// Lihat: lib/providers/auth_provider.dart untuk state user.

import '../models/models.dart';

/// Data dummy untuk fallback jika server offline (development only)
class DummyData {
  static AppUser currentUser = AppUser(
    id: 0,
    name: 'Demo User',
    username: 'demo',
    email: 'demo@sedya.app',
    role: 'Anggota',
  );

  static final List<AppUser> allUsers = [];
  static final List<Project> projects = [];
  static final List<TaskItem> tasks = [];
}
