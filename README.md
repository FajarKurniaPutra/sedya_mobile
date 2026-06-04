# 📱 Sedya Mobile App

Sedya Mobile adalah aplikasi manajemen proyek (Project Management) dan evaluasi kinerja SDM berbasis seluler yang dirancang untuk membantu tim dan perusahaan mengelola tugas, merencanakan sprint, serta mengevaluasi kinerja anggota tim secara kolaboratif. Aplikasi ini terintegrasi langsung dengan backend web Laravel.
---

## 🌟 Fitur Utama

### 1. Manajemen Proyek (Project Management)
- **Daftar Proyek**: Menampilkan proyek-proyek yang melibatkan pengguna dengan indikator status (Aktif/Selesai).
- **Detail Proyek**: Ringkasan informasi, tahapan (Perencanaan, Pengerjaan, Review, dll), dan pencipta proyek.
- **Anggota & Peran**: Mengelola tim di dalam proyek dengan peran khusus (Pemimpin Projek, Human Resource, Anggota).

### 2. Manajemen Tugas (Task Management)
- **Tugas Harian & Labeling**: Pembuatan tugas dengan rincian deskripsi, bobot tugas, prioritas, deadline, dan label area (Desain, Frontend, Backend, dll).
- **Sprint Management**: Perencanaan siklus kerja berjangka waktu (Weekly Sprint).
- **Multi-PIC**: Satu tugas dapat ditugaskan kepada lebih dari satu anggota.

### 3. Evaluasi Kinerja (HR Dashboard)
- **Rapor Kinerja**: Perhitungan bobot tugas yang telah diselesaikan untuk mengukur efektivitas dan kontribusi anggota.
- **Status Mingguan**: Visibilitas performa tim di tingkat HR dan pimpinan.

### 4. Fitur Tambahan
- **Authentication**: Dukungan login dengan Google Sign-In terintegrasi sistem Backend.
- **Dark Mode**: Tema gelap responsif yang memanjakan mata.
- **Push Notification** *(in development)*: Menggunakan Firebase Cloud Messaging.

---

## 🗂 Struktur Direktori Aplikasi

Aplikasi dibangun menggunakan **Flutter** dengan arsitektur MVCS (Model-View-Controller/Service) yang disederhanakan:

```text
lib/
 ┣ core/                # Inti konfigurasi aplikasi
 ┃ ┣ api_config.dart    # Konfigurasi endpoint & IP Backend
 ┃ ┣ constants.dart     # Token Warna, Tema & Styling (Light/Dark Mode)
 ┃ ┗ theme_notifier.dart# Pengelola state untuk mode tema
 ┣ models/              # Struktur data (Class Models)
 ┃ ┗ models.dart        # Model Project, Task, AppUser, Sprint, Note, dll.
 ┣ providers/           # State Management (Provider)
 ┃ ┗ auth_provider.dart # Mengurus otentikasi user & token JWT
 ┣ services/            # Komunikasi API dengan Backend
 ┃ ┣ api_service.dart   # Base HTTP Client & Interceptors
 ┃ ┣ project_service.dart
 ┃ ┣ sprint_service.dart
 ┃ ┗ task_service.dart
 ┣ ui/                  # Tampilan Antarmuka Pengguna
 ┃ ┣ screens/           # Halaman Utama (Login, Dashboard, Detail)
 ┃ ┗ global_layout.dart # Kerangka dasar aplikasi (AppBar, Bottom Nav)
 ┗ main.dart            # Entry point aplikasi Flutter
```

---

## 📈 Log Perubahan & Progress (Changelog)

### **Versi 1.1.0-final (Production Readiness & UI/UX Polish)**
- **Refactoring UI Riwayat Aktivitas**: Menyelaraskan tampilan *timeline* riwayat tugas (*activity log*) agar 100% konsisten dengan versi Web, lengkap dengan ikon spesifik dan teks deskripsi ramah pengguna.
- **Validasi Mandatory & Blokir Tanggal**: Kolom `Deadline` kini wajib diisi (*mandatory* ditandai bintang merah) dan kalender otomatis memblokir pemilihan tanggal di masa lampau (sebelum hari ini).
- **Optimalisasi Sorting & Filter**: Menghapus opsi *Status: Default* yang redundan. Kini daftar tugas secara otomatis diurutkan dari *Antrean* hingga *Selesai* berdasarkan waktu pembuatan tugas (ID terkecil ke terbesar).
- **Pembaruan UI Manajemen Member**: Aksi *Nonaktifkan Anggota* kini diintegrasikan langsung sebagai fitur *Switch Toggle* ke dalam modal Ubah Role, memperingkas interaksi menjadi satu alur.
- **Fitur Read-More Deskripsi**: Menambahkan interaktivitas *Tampilkan semua deskripsi* pada halaman Detail Tugas untuk membatasi panjang teks deskripsi secara *default* (maksimal 3 baris) demi menjaga proporsi UI tetap rapi.
- **Validasi Akun Google Tertaut**: Menambahkan penanganan galat (*error handling*) khusus di sisi backend dan mobile untuk mencegah pengguna mendaftar ulang secara manual apabila email tersebut sudah terdaftar menggunakan integrasi *Google Sign-In*.
- **Pembersihan Modul Biometrik**: Mencopot dependensi biometrik (`local_auth`) secara komprehensif demi keandalan aplikasi di berbagai *device* tanpa sensor biometrik.

### **Versi 1.0.0-rc.3 (Keamanan Biometrik & Interaktivitas Mobile)**
- **Proteksi Biometrik (*Fingerprint/Face ID*)**: Menambahkan integrasi `local_auth` untuk mengamankan akses aplikasi. Pengguna dapat mengaktifkan "Kunci Layar Biometrik" pada menu pengaturan.
- **Konfirmasi Keluar Aman**: Mengimplementasikan *Pop-up AlertDialog* setiap kali pengguna menekan tombol *Logout* demi mencegah aksi ketidaksengajaan.
- **Penyaringan (*Filter*) & Sortir Tugas**: Fitur baru pada layar Detail Proyek yang memungkinkan pengguna menyaring tugas secara personal ("Tugas Saya") serta mengurutkan prioritas berdasarkan kemajuan status tugas (TODO -> DONE, atau sebaliknya).
- **Interaktivitas Mobile Native (*Swipe-to-Complete*)**: Pemolesan UX dengan fungsionalitas menggeser tugas ke kanan (*swipe right*) dari daftar tugas untuk memperbarui statusnya secara instan menjadi "Selesai", lengkap dengan animasi visual dan *snackbar* respons otomatis.

### **Versi 1.0.0-rc.2 (Final UI/UX Polish & Ekstensi Fitur)**
- **Refinement UI/UX & Dark Mode Dinamis**: Mengubah *state* `AppColors` menjadi dinamis merespons pergantian tema, menambahkan *Empty States* visual berilustrasi modern, serta mengimplementasikan *Skeleton Loading* (animasi shimmer) di seluruh layar menggantikan indikator *loading* konvensional.
- **Riwayat Aktivitas & Manipulasi Anggota**: Menambahkan tab "Riwayat" pada Detail Tugas untuk memantau jejak audit proyek, dan melengkapi fungsionalitas manajemen anggota proyek oleh *Leader* (ubah *role* dan nonaktifkan anggota).
- **Integrasi Multimedia & Berkas**: Menyelesaikan integrasi unggah gambar (Kamera/Galeri) di fitur Catatan Tugas, serta fungsionalitas Unduh Laporan (PDF/CSV) di dasbor HR yang diintegrasikan langsung dengan sistem bawaan perangkat (Share/Save As).
- **Push Notification & Gabung Proyek Cerdas**: Memperbaiki alur bergabung proyek menggunakan Kode Referral untuk rute API mobile, dan mengaktifkan fungsionalitas notifikasi cerdas (*smart routing*) berbasis FCM yang dapat langsung mengarahkan layar pengguna ke Detail Tugas/Proyek spesifik setelah notifikasi diklik.

### **Versi 1.0.0-rc.1 (Sinkronisasi Backend & Fix Lifecycle)**
- **Pemisahan Environment (Local & Production)**: Mengonfigurasi ulang `api_config.dart` untuk mempermudah peralihan rute API dari *Local Development* ke *Production Hosting* (Railway) tanpa bentrok.
- **Integrasi FCM Token**: Menambahkan *service* `registerFcmToken` dan `unregisterFcmToken` di sisi *mobile* untuk melengkapi sistem *Push Notification non-blocking* di backend.
- **Pembaruan Service API**: Mengimplementasikan *Soft-Delete Project* via `ProjectService`, dan menambahkan layanan riwayat terbaru dengan model dan service `ActivityLog`.
- **Perbaikan Bug Lifecycle Kritis (Red Screen Fix)**: Memperbaiki *memory leak* pada `TabController` di halaman *Project Detail* yang menyebabkan rentetan *assertion error* (`_dependents.isEmpty is not true` dan `Null check operator`), serta membetulkan aturan `context.watch` pada `Provider`.
- **Penggantian Logo**: Mengintegrasikan aset gambar logo Sedya yang resmi menggantikan ikon *default* Flutter.

### **Versi 1.0.0-beta.3 (Bug Fix Round 3 - Stabilitas & UI/UX)**
- **UI/UX Modal**: Memperbaiki masalah validasi form di mana pesan *SnackBar* tertutup oleh modal form. Sekarang digantikan dengan *Inline Error Banner* yang lebih modern.
- **Keamanan Crash (Red Screen)**: Mencegah error *async gap* dan *widget disposal* yang sering menyebabkan layar merah (red screen of death) ketika pengguna menutup halaman Detail Tugas secara cepat.
- **Sinkronisasi Dropdown**: Menyeragamkan opsi dropdown aplikasi mobile agar 100% sama dengan backend web (Tahapan Proyek & Label Tugas).
- **Optimalisasi Kode**: Membersihkan lebih dari 500 baris kode duplikat (dead code) pada file antarmuka proyek.
- **Perbaikan Login**: Mencegah crash *BuildContext* saat sinkronisasi profil Google.

### **Versi 1.0.0-beta.2 (Data Parsing & Routing)**
- Menghubungkan fungsionalitas UI dengan *API endpoint* asli dari Laravel (menggantikan *dummy data*).
- Menambahkan *refresh indicator* pada daftar proyek dan detail sprint.
- Menyempurnakan pemetaan (*mapping*) JSON untuk status tugas ("TODO", "IN_PROGRESS", "REVIEW", "DONE").

### **Versi 1.0.0-beta.1 (Struktur Dasar & Theming)**
- Inisialisasi awal proyek Flutter.
- Pembuatan antarmuka pengguna berbasis `AppColors` dengan dukungan *Dark Mode*.
- Pembuatan *Bottom Navigation* utama dan sistem perutean layar.

---

## 🚀 Instalasi & Menjalankan Aplikasi

1. Pastikan **Backend Laravel** sedang menyala di jaringan lokal Anda (`php artisan serve --host=0.0.0.0 --port=8000`).
2. Ketahui *IPv4 Address* dari Wi-Fi komputer Anda (menggunakan perintah `ipconfig` di Windows).
3. Buka file `lib/core/api_config.dart`.
4. Ubah variabel `baseUrl` dengan IP Anda:
   ```dart
   static const String baseUrl = 'http://192.168.x.x:8000';
   ```
5. Jalankan aplikasi di emulator atau perangkat fisik:
   ```bash
   flutter run
   ```