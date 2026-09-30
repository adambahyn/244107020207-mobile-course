import 'package:dio/dio.dart';

import '../models/post.dart';

/// Satu-satunya lapisan yang tahu Dio dan URL.
///
/// UI memanggil provider, provider memanggil repository, repository memanggil
/// Dio. Karena itu mengganti sumber data (mis. ke cache lokal) cukup mengubah
/// kelas ini tanpa menyentuh widget.
///
/// Method `virtual` (non-final) supaya bisa ditimpa repository palsu di test.
class PostRepository {
  PostRepository(this._dio);

  final Dio _dio;

  static const postsPath = '/posts';

  /// Satu halaman post: `GET /posts?_page=1&_limit=10`.
  ///
  /// Server mengembalikan array langsung (bukan `{data: [...]}`), jadi tipe
  /// responsnya `List`. `whereType<Map<String, dynamic>>()` membuang elemen
  /// rusak supaya satu item aneh tidak menggagalkan seluruh halaman.
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    final response = await _dio.get<List>(
      postsPath,
      queryParameters: {'_page': page, '_limit': limit},
    );
    final data = response.data ?? const [];
    return data.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }
}
