// ─────────────────────────────────────────────────────────────────────────────
// Provider untuk halaman detail post (`/post/:id`).
//
// Requirement: "state detail diambil dari list yang sudah dimuat atau via
// repository bila langsung dibuka".
//
// Dua jalur itu diwujudkan oleh `postDetailProvider`:
//
//   1. SALDO / CACHE-HIT  -> post sudah ada di `postListProvider`
//      (mis. halaman daftar post sudah dibuka sebelumnya).
//      Hasilnya dikembalikan tanpa HTTP sama sekali.
//
//   2. AMBIL DARI SERVER  -> daftar belum dimuat (mis. `/post/3` dibuka
//      langsung lewat deep link). `postListProvider` dibaca sampai selesai,
//      lalu post dicari di dalamnya.
//
// Kenapa tetap lewat `postListProvider` (bukan memanggil repository detail
// sendiri)? Karena JSONPlaceholder tidak punya `GET /posts/{id}` yang kita
// butuhkan di sini — kita sudah punya `fetchPosts()` (`GET /posts`) yang
// mengembalikan seluruh post. Jadi "via repository" berarti daftar lengkap
// diambil sekali lalu di-cache Riverpod, dan semua halaman detail berikutnya
// langsung mendapat saldo dari cache yang sama.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/post.dart';
import 'providers.dart';

/// Mencari post dengan [postId] dari daftar yang sudah dimuat, atau mengambil
/// daftar dari server bila belum ada.
///
/// Mengembalikan `Post?`; `null` berarti post benar-benar tidak ada di server
/// (mis. `/post/999`), yang oleh halaman detail ditampilkan sebagai pesan
/// "post tidak ditemukan" — bukan error jaringan.
Future<Post?> _resolvePost(Ref ref, int postId) async {
  // Cek saldo dulu: kalau daftar sudah pernah dimuat dan berisi data, tidak
  // perlu menunggu apa pun. `AsyncValue.value` bernilai null saat masih
  // loading atau error, jadi aman dibaca tanpa memicu exception.
  final cachedPosts = ref.read(postListProvider).value;
  if (cachedPosts != null) {
    final found = _findById(cachedPosts, postId);
    // Ditemukan -> langsung kembalikan (tanpa jaringan).
    if (found != null) return found;
  }

  // Jalur 2: belum ada data (atau tidak ditemukan di data lama) -> tunggu
  // daftar dari server. `future` akan memicu `build()` di `postListProvider`,
  // dan hasilnya di-cache untuk semua pembaca berikutnya.
  final posts = await ref.watch(postListProvider.future);
  return _findById(posts, postId);
}

/// Pencarian linear sederhana; jumlah post kecil (100) dan ini hanya dijalankan
/// sekali per halaman detail, jadi tidak perlu indeks.
Post? _findById(List<Post> posts, int postId) {
  for (final post in posts) {
    if (post.id == postId) return post;
  }
  return null;
}

/// Provider keluarga berparameter `postId`.
///
/// Pemakaian di halaman detail:
/// ```dart
/// final postAsync = ref.watch(postDetailProvider(postId));
/// postAsync.when(
///   loading: () => const CircularProgressIndicator(),
///   error: (e, _) => Text(friendlyErrorMessage(e)),
///   data: (post) => post == null ? const Text('Tidak ditemukan') : ...,
/// );
/// ```
final postDetailProvider = FutureProvider.family<Post?, int>(
  (ref, postId) {
    // postId tidak valid (mis. `/post/abc` -> 0): jangan tembak jaringan.
    if (postId <= 0) return Future<Post?>.value(null);

    return _resolvePost(ref, postId);
  },
  // Matikan retry otomatis Riverpod 3 supaya error jaringan muncul seketika
  // di UI, bukan setelah 10 kali percobaan dengan backoff sampai 6,4 detik.
  retry: (retryCount, error) => null,
);
