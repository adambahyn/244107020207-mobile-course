/// Nama rute dan helper pembentuk path.
///
/// Dikumpulkan di satu tempat supaya tidak ada string rute yang tersebar
/// sebagai literal di banyak widget — salah tulis satu huruf menjadi error
/// compile/runtime yang membingungkan.
library;

/// Nama unik per rute (dipakai `context.goNamed` / `context.pushNamed`).
abstract final class AppRouteName {
  /// `/` — halaman daftar komentar (contoh pemanfaatan endpoint komentar).
  static const String comments = 'comments';

  /// `/posts` — halaman daftar post (non-paged).
  static const String posts = 'posts';

  /// `/paged` — halaman daftar post dengan pagination.
  static const String pagedPosts = 'pagedPosts';

  /// `/post/:id` — halaman detail satu post.
  static const String postDetail = 'postDetail';
}

/// Path rute, termasuk pola dengan parameter.
abstract final class AppRoutePath {
  static const String comments = '/';
  static const String posts = '/posts';
  static const String pagedPosts = '/paged';

  /// Pola path detail; `:id` diganti nilai sebenarnya saat navigasi.
  static const String postDetailPattern = '/post/:id';

  /// Membentuk path detail untuk [id] tertentu.
  ///
  /// Selalu pakai helper ini supaya tidak ada yang menulis `'/post/1'`
  /// manual dan lupa menyertakan id.
  static String postDetail(int id) => '/post/$id';
}
