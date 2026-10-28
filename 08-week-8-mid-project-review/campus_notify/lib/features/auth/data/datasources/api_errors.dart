import 'package:dio/dio.dart';

import '../../../../core/failures.dart';

/// DioException -> Failure dengan pesan Indonesia. Batas data → domain.
Failure failureFromDio(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Koneksi lambat. Coba lagi.');
      case DioExceptionType.connectionError:
        return const NetworkFailure('Tidak ada koneksi internet.');
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401) {
          return const AuthFailure('Sesi berakhir. Silakan login ulang.');
        }
        if (code == 403) return const AuthFailure('Akses ditolak.');
        if (code == 404) return const NetworkFailure('Data tidak ditemukan.');
        if (code != null && code >= 500) {
          return const NetworkFailure('Server sedang bermasalah.');
        }
        return NetworkFailure('Permintaan ditolak ($code).');
      default:
        return const NetworkFailure('Terjadi kesalahan jaringan.');
    }
  }
  return LocalFailure(error.toString().replaceFirst('Exception: ', ''));
}
