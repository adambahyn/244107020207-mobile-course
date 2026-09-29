import 'package:dio/dio.dart';

/// Menerjemahkan error jaringan menjadi pesan yang bisa dibaca pengguna.
///
/// Dipisah dari `comment_provider.dart` supaya:
/// - file provider tetap fokus pada state management, dan
/// - fungsi ini bisa diuji sendiri tanpa Flutter/Riverpod.
///
/// Semua cabang menangani [DioException] karena itulah tipe error yang
/// dikeluarkan Dio. Error lain (mis. bug parsing) jatuh ke cabang terakhir.
String friendlyCommentError(Object? error) {
  switch (error) {
    // ── 1. TIMEOUT ────────────────────────────────────────────────────────
    // Penyebab: koneksi lambat atau server tidak menjawab dalam 10 detik.
    // Pesannya sengaja menyarankan aksi konkret, bukan menyebut istilah
    // teknis ("connectTimeout") yang tidak dimengerti pengguna.
    case DioException(type: DioExceptionType.connectionTimeout):
    case DioException(type: DioExceptionType.sendTimeout):
    case DioException(type: DioExceptionType.receiveTimeout):
      return 'Koneksi ke server terlalu lama (timeout 10 detik). '
          'Periksa internet Anda lalu coba lagi.';

    // ── 2. CONNECTION ERROR ───────────────────────────────────────────────
    // Penyebab: tidak ada internet, DNS gagal, atau host tidak terjangkau.
    case DioException(type: DioExceptionType.connectionError):
      return 'Tidak dapat terhubung ke server. '
          'Pastikan perangkat Anda terhubung ke internet.';

    // ── 3. SERTIFIKAT SSL/TLS ─────────────────────────────────────────────
    case DioException(type: DioExceptionType.badCertificate):
      return 'Koneksi tidak aman (sertifikat server tidak valid).';

    // ── 4. REQUEST DIBATALKAN ─────────────────────────────────────────────
    case DioException(type: DioExceptionType.cancel):
      return 'Permintaan dibatalkan.';

    // ── 5. BODY TIDAK BISA DIBACA ─────────────────────────────────────────
    case DioException(type: DioExceptionType.transformTimeout):
      return 'Data dari server terlalu besar / rusak sehingga gagal dibaca.';

    // ── 6. STATUS CODE 4xx / 5xx ──────────────────────────────────────────
    // `badResponse` = server menjawab, tetapi statusnya di luar 2xx.
    // Di sini kita bercabang berdasarkan kode status.
    case DioException(type: DioExceptionType.badResponse):
      final code = error.response?.statusCode;
      return switch (code) {
        404 =>
          'Data tidak ditemukan (404). '
              'Komentar untuk post ini tidak tersedia.',
        401 || 403 =>
          'Akses ditolak ($code). Anda tidak punya izin '
              'membuka data ini.',
        500 =>
          'Terjadi kesalahan di server (500). '
              'Silakan coba beberapa saat lagi.',
        502 ||
        503 ||
        504 => 'Server sedang tidak tersedia ($code). Coba lagi nanti.',
        _ => 'Permintaan gagal dengan kode $code. Coba lagi nanti.',
      };

    // ── 7. DIOEXCEPTION LAIN YANG BELUM DICAKUP ───────────────────────────
    case DioException():
      return 'Terjadi gangguan jaringan. Periksa koneksi lalu coba lagi.';

    // ── 8. ERROR NON-JARINGAN ─────────────────────────────────────────────
    // Mis. bug parsing JSON atau kesalahan programming. Ditampilkan singkat
    // agar tetap bisa dilaporkan tanpa membingungkan pengguna.
    default:
      return 'Terjadi kesalahan tak terduga. Silakan coba lagi.';
  }
}

/// Versi ringkas untuk log/debug: menyertakan detail teknis.
/// Jangan dipakai sebagai teks yang tampil di layar pengguna.
String debugCommentError(Object? error) {
  if (error is DioException) {
    return '${error.type.name} '
        'path=${error.requestOptions.path} '
        'query=${error.requestOptions.queryParameters} '
        'status=${error.response?.statusCode}';
  }
  return error.toString();
}
