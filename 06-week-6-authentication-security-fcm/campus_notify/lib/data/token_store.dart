import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Satu-satunya pintu keluar-masuk token. Token TIDAK PERNAH lewat
/// SharedPreferences (tidak terenkripsi) dan tidak pernah di-log penuh.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> readAccess() => _storage.read(key: _accessKey);
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<void> clear() => _storage.deleteAll();

  /// Hanya untuk halaman Debug: 12 karakter pertama + "…".
  static String mask(String? token) {
    if (token == null || token.isEmpty) return '(kosong)';
    if (token.length <= 12) return '${token.substring(0, token.length)}…';
    return '${token.substring(0, 12)}…';
  }
}
