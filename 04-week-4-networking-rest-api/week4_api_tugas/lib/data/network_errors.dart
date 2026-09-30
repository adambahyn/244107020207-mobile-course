/// Penerjemah error jaringan menjadi pesan yang bisa dibaca pengguna.
///
/// Dipakai lapisan UI (`post_list_page.dart`) supaya halaman tidak perlu tahu
/// apa itu `DioException`. Parameter bertipe `Object?` dan fungsi ini tidak
/// pernah melempar, jadi pemanggil bisa langsung mengoper `state.error`.
library;

import 'package:dio/dio.dart';

/// Mengubah [error] menjadi pesan ramah pengguna berbahasa Indonesia.
String friendlyErrorMessage(Object? error) {
  switch (error) {
    // ── 1. TIMEOUT ────────────────────────────────────────────────────────
    case DioException(type: DioExceptionType.connectionTimeout):
    case DioException(type: DioExceptionType.sendTimeout):
    case DioException(type: DioExceptionType.receiveTimeout):
      return 'Koneksi ke server terlalu lama (timeout). '
          'Periksa internet Anda lalu coba lagi.';

    // ── 2. TIDAK ADA KONEKSI ──────────────────────────────────────────────
    case DioException(type: DioExceptionType.connectionError):
      return 'Tidak dapat terhubung ke server. '
          'Pastikan perangkat Anda terhubung ke internet.';

    // ── 3. SERTIFIKAT SSL/TLS ─────────────────────────────────────────────
    case DioException(type: DioExceptionType.badCertificate):
      return 'Koneksi tidak aman (sertifikat server tidak valid).';

    // ── 4. REQUEST DIBATALKAN ─────────────────────────────────────────────
    case DioException(type: DioExceptionType.cancel):
      return 'Permintaan dibatalkan.';

    // ── 5. BODY GAGAL DIBACA ──────────────────────────────────────────────
    case DioException(type: DioExceptionType.transformTimeout):
      return 'Data dari server terlalu besar atau rusak sehingga gagal dibaca.';

    // ── 6. STATUS 4xx / 5xx ───────────────────────────────────────────────
    case DioException(type: DioExceptionType.badResponse):
      final code = error.response?.statusCode;
      return switch (code) {
        404 => 'Data tidak ditemukan (404).',
        401 || 403 =>
          'Akses ditolak ($code). Anda tidak punya izin '
              'membuka data ini.',
        500 =>
          'Terjadi kesalahan di server (500). '
              'Silakan coba beberapa saat lagi.',
        502 || 503 || 504 =>
          'Server sedang tidak tersedia ($code). '
              'Coba lagi nanti.',
        _ => 'Permintaan gagal dengan kode $code. Coba lagi nanti.',
      };

    // ── 7. DIOEXCEPTION LAIN ──────────────────────────────────────────────
    case DioException():
      return 'Terjadi gangguan jaringan. Periksa koneksi lalu coba lagi.';

    // ── 8. ERROR NON-JARINGAN (mis. bug parsing) ───────────────────────────
    default:
      return 'Terjadi kesalahan tak terduga. Silakan coba lagi.';
  }
}
