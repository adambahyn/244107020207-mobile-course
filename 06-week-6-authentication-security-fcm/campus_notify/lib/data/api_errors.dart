import 'package:dio/dio.dart';

/// Pesan ramah pengguna dari DioException. UI hanya menerima String.
String friendlyError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat. Coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401) return 'Sesi berakhir. Silakan login ulang.';
        if (code == 403) return 'Akses ditolak.';
        if (code == 404) return 'Data tidak ditemukan.';
        if (code != null && code >= 500) return 'Server sedang bermasalah.';
        return 'Permintaan ditolak ($code).';
      default:
        return 'Terjadi kesalahan jaringan.';
    }
  }
  return error.toString().replaceFirst('Exception: ', '');
}
