File yang dibuat
 - lib/data/models/comment.dart — model Comment (postId, id, name, email,
 body) + fromJson aman-null. Field angka lewat helper _asInt (num → toInt,
 String angka → tryParse, tipe lain → 0); string lewat _asString. Plus toJson,
 copyWith, ==/hashCode. Semua dikomentari.
 - lib/data/repositories/comment_repository.dart — fetchComments(postId)
 memanggil GET /comments dengan queryParameters: {'postId': id}, timeout 10
 detik (Options per-request), validateStatus: <400, dan whereType<Map>()
 supaya satu elemen rusak tidak menggagalkan seluruh respons.
 - lib/data/comment_errors.dart — friendlyCommentError menangani timeout
 (connection/send/receive), connectionError, badCertificate, cancel, dan
 badResponse: 404, 401/403, 500, 502/503/504.
 - lib/data/comment_provider.dart — commentRepositoryProvider,
 CommentListNotifier + commentListProvider (AsyncNotifierProvider.family),
 commentErrorMessage, dan helper test readCommentsOnce. Error otomatis jadi
 AsyncError karena tidak ada try/catch di build(); retry: (, ) => null
 mematikan retry Riverpod 3 agar error muncul seketika.
 - lib/pages/comment_list_page.dart — halaman konsumen
 (when(loading/error/data), pull-to-refresh, tombol coba lagi).
 - test/comment_model_test.dart — 8 unit test fromJson: JSON lengkap, {}
 kosong, sebagian field, null eksplisit, tipe salah ('3', 4.0, 123, true,
 Map), string bukan angka.

 Verifikasi nyata (bukan klaim)
 - flutter test test/comment_model_test.dart → 8/8 lulus.
 - test_comment_repo_e2e.dart → 5/5 lulus melawan JSONPlaceholder sungguhan:
 post 1 mengembalikan 5 komentar, URI terbukti
 https://jsonplaceholder.typicode.com/comments?postId=3, post 999 → list
 kosong (bukan error), dan keempat pesan error ramah pengguna tercetak benar.
 - test_comment_provider_e2e.dart → 3/3 lulus: AsyncData (5 komentar),
 AsyncError 404 via repository override, dan AsyncError dari validasi postId
 <= 0.
 - flutter analyze → 0 error. 4 warning tersisa: copyWithPrevious (API baru
 Riverpod 3), unused import di main.dart yang sudah ada sebelum perubahan, dan
 2 unused import di file test e2e saya.

 Dua catatan penting
 1. FamilyAsyncNotifier dengan build(int arg) sudah tidak ada di Riverpod
 3.4.3. Argumen family harus diterima lewat konstruktor notifier
 (CommentListNotifier(this.postId)), dan AsyncNotifierProvider.family
 memanggil CommentListNotifier.new dengan postId. Saya menemukan ini setelah
 gagal dengan beberapa pendekatan akses provider.argument — sudah diverifikasi
 dengan probe yang benar-benar dijalankan.
 2. JSONPlaceholder selalu membalas 200 (bahkan 200 [] untuk postId yang tidak
 ada), jadi cabang 404 di UI tidak akan muncul dari server ini. Sudah saya
 tulis eksplisit di komentar kode dan diuji lewat response tiruan.

 Belum selesai (opsional): 4 warning analyze masih ada (3 di antaranya
 harmless), dan saya tidak menjalankan flutter build web --release karena
 batas iterasi. main.dart masih menunjuk PagedPostPage; kalau mau mencoba
 halaman komentar di emulator, ganti ke CommentListPage(postId: 1).