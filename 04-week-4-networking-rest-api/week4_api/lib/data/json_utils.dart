/// Helper parsing JSON yang **tidak pernah melempar** exception.
///
/// Dipakai oleh semua model (`Post`, `Comment`) supaya data dari jaringan yang
/// rusak tidak membuat layar crash.
///
/// Kenapa bukan `json['id'] as int? ?? 0`?
/// Cast nullable hanya menoleransi `null`, **bukan tipe lain**. Kalau server
/// mengirim `"id": [1, 2, 3]` atau `"id": {"value": 9}`, `as int?` tetap
/// melempar `TypeError`. Helper di bawah memakai pemeriksaan tipe `is`
/// sehingga kasus itu mengembalikan nilai default.
library;

/// Mengubah nilai `dynamic` apa pun menjadi [int] dengan aman.
///
/// Urutan penanganan:
/// 1. `null` (field hilang)             -> [fallback]
/// 2. `num` (`int` / `double`)          -> `.toInt()`
/// 3. `String` berisi angka (`"12"`)    -> `int.tryParse`
/// 4. tipe lain (List, Map, bool, ...)  -> [fallback]
int asIntSafe(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

/// Mengubah nilai `dynamic` apa pun menjadi [String] dengan aman.
///
/// `num` dan `bool` dikonversi lewat `toString()` supaya `"id": 5` atau
/// `"flag": true` tetap terbaca; `null` / List / Map jatuh ke [fallback].
String asStringSafe(Object? value, {String fallback = ''}) {
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return fallback;
}
