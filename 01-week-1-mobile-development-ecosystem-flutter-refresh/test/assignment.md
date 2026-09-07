# Laporan Praktikum Minggu 1: Mobile Development Ecosystem & Flutter Refresh

## 1. Identitas Mahasiswa
- **Nama:** Adam Bahy Maulana
- **NIM:** 244107020207
- **Kelas:** TI-3E

## 2. Screenshot Aplikasi Profil Mahasiswa
![Profil Mahasiswa](screenshots/profil-mahasiswa.jpeg)

## 3. Kendala Setup Environment & Solusi
- **Kendala:** Pada saat verifikasi `flutter doctor`, toolchain Android memunculkan status `[!] Android license status unknown`. Saat menjalankan perintah `flutter doctor --android-licenses`, terminal memunculkan peringatan bahwa opsi `--licenses` sudah usang/tidak lagi didukung karena terpasangnya versi Android CLI terbaru (`cmdline-tools 23.0` dan Android SDK 36/37).
- **Solusi:** Mengatur SDK Android ke versi stabil (API 35 / Android 15), menghapus paket SDK 36/37 yang belum stabil, serta menurunkan (*downgrade*) versi Android SDK Command-line Tools dari versi 23.0 ke versi stabil (versi 13.0/12.0) melalui SDK Manager Android Studio agar perintah penerimaan lisensi dapat dijalankan dengan normal hingga `flutter doctor` bertanda centang hijau penuh.
