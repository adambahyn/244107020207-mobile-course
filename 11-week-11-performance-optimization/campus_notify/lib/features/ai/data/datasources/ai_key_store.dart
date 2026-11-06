import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Satu-satunya pintu keluar-masuk API key AI. Key tidak pernah masuk kode
/// sumber, tidak pernah ditulis ke log, dan tidak pernah dikirim ke UI penuh.
class AiKeyStore {
  AiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'ai_api_key';

  Future<String?> read() => _storage.read(key: _key);

  Future<void> save(String value) =>
      _storage.write(key: _key, value: value.trim());

  Future<void> clear() => _storage.delete(key: _key);

  /// Hanya enam karakter pertama yang ditampilkan, sisanya bintang.
  static String mask(String? key) {
    if (key == null || key.isEmpty) return '(belum diatur)';
    final head = key.length <= 10 ? key.substring(0, 4) : key.substring(0, 10);
    return '$head${'*' * 6}';
  }
}
