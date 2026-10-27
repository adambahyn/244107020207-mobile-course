import 'failures.dart';

/// Fungsi murni lintas fitur: bisa diuji tanpa widget, Firebase, atau Dio.
const _bulan = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// DateTime -> "27 September 2026".
String formatTanggal(DateTime waktu) =>
    '${waktu.day} ${_bulan[waktu.month - 1]} ${waktu.year}';

/// Token tidak pernah ditampilkan penuh: 12 karakter pertama + elipsis.
String maskToken(String? token) {
  if (token == null || token.isEmpty) return '(kosong)';
  if (token.length <= 12) return '${token.substring(0, 12)}…';
  return '${token.substring(0, 12)}…';
}

/// RemoteMessage.data -> rute. Route tanpa garis miring depan diperbaiki.
String routeFromMessage(Map<String, dynamic> data) {
  final raw = (data['route'] ?? '').toString().trim();
  if (raw.isEmpty) return '/';
  return raw.startsWith('/') ? raw : '/$raw';
}

/// Pesan tampil untuk UI: Failure dipakai apa adanya, exception dipotong
/// prefix teknisnya.
String messageOf(Object error) => error is Failure
    ? error.message
    : error.toString().replaceFirst('Exception: ', '');
