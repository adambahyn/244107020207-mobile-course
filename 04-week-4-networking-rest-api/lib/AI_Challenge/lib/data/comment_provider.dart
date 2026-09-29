// ─────────────────────────────────────────────────────────────────────────────
// Provider Riverpod untuk komentar per post (endpoint GET /comments?postId=id)
//
// Isi file:
//   1. commentRepositoryProvider  -> menyediakan CommentRepository
//   2. CommentListNotifier        -> AsyncNotifier<List<Comment>> per postId
//   3. commentListProvider        -> AsyncNotifierProvider.family (state Async)
//   4. commentErrorMessage        -> pesan error ramah pengguna
//   5. readCommentsOnce           -> helper pengujian (tanpa jaringan)
//
// Ditulis manual (tanpa `riverpod_generator`) supaya tidak perlu build_runner.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comment_errors.dart';
import 'models/comment.dart';
import 'providers.dart';
import 'repositories/comment_repository.dart';

/// Menyediakan [CommentRepository].
///
/// `dioProvider` diambil dari `providers.dart` supaya konfigurasi Dio
/// (baseUrl `https://jsonplaceholder.typicode.com`, header Accept, interceptor
/// Log) didefinisikan satu kali dan dipakai bersama repository post maupun
/// comment. Karena ini `Provider` biasa, objeknya di-cache: Dio dan repository
/// tidak dibuat ulang setiap ada widget yang menontonnya.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

/// Notifier yang membangun `AsyncValue<List<Comment>>` untuk satu `postId`.
///
/// Kenapa `AsyncNotifier` dan bukan `FutureProvider`?
/// - State error-nya otomatis `AsyncError`: exception yang dilempar `build()`
///   ditangkap Riverpod (lihat `ElementWithFuture.handleFuture` pada paket
///   riverpod) lalu dipancarkan sebagai `AsyncError` lengkap dengan stack
///   trace. UI cukup memakai `asyncValue.when(error: ...)` — inilah "penanganan
///   error otomatis" yang diminta tugas, tanpa satu pun try/catch manual.
/// - Kita bisa menambahkan method publik seperti [refresh] untuk tombol
///   "Coba lagi" maupun pull-to-refresh.
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  /// Argumen family diterima lewat **konstruktor**, bukan lewat `build()`.
  ///
  /// `AsyncNotifierProvider.family<CommentListNotifier, List<Comment>, int>`
  /// memanggil `CommentListNotifier.new` dengan `postId` sebagai parameter,
  /// jadi setiap `postId` mendapat instance notifier sendiri. Inilah pengganti
  /// `FamilyAsyncNotifier` gaya lama yang sudah dihapus di Riverpod 3.4.3.
  CommentListNotifier(this.postId);

  /// ID post yang komentarnya sedang diambil; dipakai juga saat [refresh].
  final int postId;

  /// `build()` dijalankan saat provider pertama kali dibaca dan setiap kali
  /// dependensi yang di-`watch` berubah.
  @override
  Future<List<Comment>> build() {
    // Tolak postId yang tidak masuk akal SEBELUM menembak jaringan. Melempar di
    // sini tetap aman: Riverpod menangkapnya dan mengubahnya menjadi AsyncError.
    if (postId <= 0) {
      throw ArgumentError.value(postId, 'postId', 'postId harus lebih dari 0');
    }

    // `ref.watch` (bukan `ref.read`) supaya bila repository di-override di test,
    // notifier otomatis memakai repository versi override.
    final repository = ref.watch(commentRepositoryProvider);

    // Future ini sukses -> AsyncData, gagal -> AsyncError. Tanpa try/catch.
    return repository.fetchComments(postId);
  }

  /// Mengambil ulang data dari server (tombol refresh / pull-to-refresh).
  ///
  /// Alur state:
  /// - `AsyncLoading` → mempertahankan data lama sementara indikator loading
  ///   berjalan (`isRefreshing == true`), jadi UI tidak berkedip kosong.
  /// - sukses → `AsyncData(list)`
  /// - gagal  → `AsyncError(e, st)`, dijamin oleh `AsyncValue.guard` sehingga
  ///   tidak ada exception yang lolos ke pemanggil.
  ///
  /// Retry otomatis Riverpod 3 dimatikan di deklarasi provider (lihat `retry:`),
  /// sehingga state error muncul seketika, bukan setelah backoff 200 ms → 6,4 s.
  Future<void> refresh() async {
    final repository = ref.read(commentRepositoryProvider);

    // Tandai sedang loading tanpa membuang data yang sudah ada.
    state = const AsyncLoading<List<Comment>>().copyWithPrevious(
      state,
      isRefresh: true,
    );

    state = await AsyncValue.guard(() => repository.fetchComments(postId));
  }

  /// Pesan error siap-tampil untuk state saat ini.
  ///
  /// ```dart
  /// comments.when(
  ///   loading: () => const CircularProgressIndicator(),
  ///   error: (err, st) => Text(commentErrorMessage(err)),
  ///   data: (list) => CommentListView(list),
  /// );
  /// ```
  String get errorMessage => commentErrorMessage(state.error);
}

/// Provider keluarga (family) berparameter `postId`.
///
/// Pemakaian di widget:
/// ```dart
/// final comments = ref.watch(commentListProvider(postId));
/// ```
///
/// `retry: (retryCount, error) => null` → **matikan retry otomatis Riverpod 3**
/// (typedef `Retry = Duration? Function(int, Object)`; `null` berarti "jangan
/// ulangi"). Tanpa ini provider yang gagal dicoba ulang sampai 10 kali dengan
/// backoff 200 ms → 6,4 s: pesan error baru muncul setelah puluhan detik dan
/// widget test bisa menggantung.
final commentListProvider =
    AsyncNotifierProvider.family<CommentListNotifier, List<Comment>, int>(
      CommentListNotifier.new,
      retry: (retryCount, error) => null,
    );

/// Mengubah objek error (biasanya `DioException`) menjadi teks ramah pengguna.
///
/// Diteruskan ke [friendlyCommentError] di `comment_errors.dart` supaya logika
/// penerjemahan bisa diuji terpisah dari Flutter/Riverpod. Mencakup timeout,
/// connection error, 404, dan 500 (plus 401/403/502/503/504 sebagai bonus).
String commentErrorMessage(Object? error) => friendlyCommentError(error);

/// Helper khusus pengujian — pola sama dengan `readPostsOnce` di
/// `providers.dart`.
///
/// Menunggu state pertama yang **bukan** loading, lalu menyelesaikan
/// `Completer` dengan data atau error-nya. Dipakai supaya `flutter test` tidak
/// pernah menembak jaringan sungguhan dan tidak menunggu retry.
Future<List<Comment>> readCommentsOnce(
  ProviderContainer container,
  int postId,
) {
  final completer = Completer<List<Comment>>();
  final sub = container.listen<AsyncValue<List<Comment>>>(
    commentListProvider(postId),
    (previous, next) {
      // Abaikan state loading (termasuk refresh) dan hasil setelah selesai.
      if (next.isLoading || completer.isCompleted) return;

      switch (next) {
        case AsyncData(:final value):
          completer.complete(value);
        case AsyncError(:final error, :final stackTrace):
          completer.completeError(error, stackTrace);
        case AsyncLoading():
          break;
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}
