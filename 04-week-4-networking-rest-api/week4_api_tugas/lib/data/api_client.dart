import 'package:dio/dio.dart';

/// Base URL API. Bisa diganti saat build tanpa mengubah kode:
///
///   flutter run --dart-define=API_BASE_URL=http://localhost:8732
///
/// Default-nya JSONPlaceholder, jadi aplikasi biasa tetap jalan tanpa flag.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://jsonplaceholder.typicode.com',
);

/// Dio terpusat: satu-satunya tempat `baseUrl`, timeout, dan interceptor
/// didefinisikan.
///
/// UI dan provider tidak pernah menyebut URL atau membuat `Dio` sendiri;
/// semuanya lewat `dioProvider` (lihat `providers.dart`). Kalau `baseUrl`
/// berubah, cukup lewat [apiBaseUrl].
Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );
  // LogInterceptor: bukti nyata request/response saat debugging.
  // `requestBody: true` supaya query `_page`/`_limit` ikut tercetak.
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
  return dio;
}
