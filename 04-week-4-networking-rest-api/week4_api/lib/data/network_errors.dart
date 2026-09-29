/// Penerjemah error jaringan menjadi pesan yang bisa dibaca pengguna.
///
/// Satu file, satu sumber kebenaran. Dipakai bersama oleh:
/// - halaman non-paged (`post_list_page.dart`, `comment_list_page.dart`)
/// - halaman paged (`paged_post_page.dart`)
///
/// Sebelumnya fungsi ini terduplikasi: `providers.dart` menyimpan
/// `friendlyErrorMessage` (tanpa `badCertificate` / `cancel` /
/// `transformTimeout`) dan `comment_errors.dart` menyimpan versi yang lebih
/// lengkap. Sekarang keduanya digantikan file ini.
///
/// Tipe error yang ditangani:
/// - [DioException] — semua anggota `DioExceptionType`
/// - tipe lain (bug parsing, `ArgumentError`, dll) -> pesan generik
library;

import 'package:dio/dio.dart';

/// Mengubah [error] menjadi pesan ramah pengguna berbahasa Indonesia.
///
/// Tidak pernah melempar: parameter bertipe `Object?` supaya pemanggil bisa
/// langsung mengoper `AsyncValue.error` tanpa null-check.
String friendlyErrorMessage(Object? error) {
  switch (error) {
    // ── 1. TIMEOUT ────────────────────────────────────────────────────────
    // Koneksi lambat atau server tidak menjawab dalam batas waktu.
    case DioException(type: DioExceptionType.connectionTimeout):
    case DioException(type: DioExceptionType.sendTimeout):
    case DioException(type: DioExceptionType.receiveTimeout):
      return 'Koneksi ke server terlalu lama (timeout). '
          'Periksa internet Anda lalu coba lagi.';

    // ── 2. CONNECTION ERROR ───────────────────────────────────────────────
    // Tidak ada internet, DNS gagal, atau host tidak terjangkau.
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
    // Server menjawab, tetapi statusnya di luar 2xx.
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

    // ── 7. DIOEXCEPTION LAIN (unknown) ────────────────────────────────────
    case DioException():
      return 'Terjadi gangguan jaringan. Periksa koneksi lalu coba lagi.';

    // ── 8. ERROR NON-JARINGAN ─────────────────────────────────────────────
    // Mis. bug parsing. Ditampilkan singkat tanpa membocorkan stack trace.
    default:
      return 'Terjadi kesalahan tak terduga. Silakan coba lagi.';
  }
}

/// Versi ringkas untuk log/debug: menyertakan detail teknis.
///
/// **Jangan** dipakai sebagai teks yang tampil ke pengguna.
String debugNetworkError(Object? error) {
  if (error is DioException) {
    return '${error.type.name} '
        'path=${error.requestOptions.path} '
        'query=${error.requestOptions.queryParameters} '
        'status=${error.response?.statusCode}';
  }
  return error.toString();
}
