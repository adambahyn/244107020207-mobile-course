import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Lapisan repository untuk endpoint komentar JSONPlaceholder.
///
/// Tugas repository: berbicara dengan HTTP dan mengembalikan **model domain**.
/// Widget/provider tidak boleh tahu soal Dio, URL, atau bentuk JSON mentah —
/// semuanya diisolasi di sini sehingga mudah diganti (mock di test) dan
/// mudah diubah kalau endpoint berubah.
class CommentRepository {
  /// [Dio] disuntikkan dari luar (lihat `providers.dart`) alih-alih dibuat
  /// di dalam kelas: inilah yang membuat repository bisa di-unit-test tanpa
  /// jaringan.
  CommentRepository(this._dio);

  final Dio _dio;

  /// Batas waktu khusus request komentar (10 detik), sesuai ketentuan tugas.
  ///
  /// Nilai ini dipasang per-request lewat `Options` sehingga tidak
  /// bergantung pada konfigurasi `BaseOptions` global di `api_client.dart`.
  static const Duration timeout = Duration(seconds: 10);

  /// Mengambil seluruh komentar milik satu post.
  ///
  /// Endpoint: `GET /comments?postId={postId}`.
  ///
  /// Parameter `postId` dikirim sebagai query parameter (`?postId=1`),
  /// bukan sebagai path parameter, karena begitulah kontrak JSONPlaceholder.
  ///
  /// Error yang mungkin dilempar (semuanya [DioException]) dan diteruskan
  /// apa adanya — penerjemahan ke pesan ramah pengguna dilakukan di
  /// `CommentErrorMapper` (`lib/data/comment_errors.dart`):
  /// - `connectionTimeout` / `receiveTimeout` bila lewat 10 detik
  ///   (bisa juga timeout dari `BaseOptions` yang nilainya sama),
  /// - `connectionError` bila perangkat offline / DNS gagal / server
  ///   tidak bisa dihubungi,
  /// - `badResponse` untuk status di luar 2xx, mis. 404 atau 500.
  ///
  /// Catatan penting: JSONPlaceholder **selalu** mengembalikan 200 untuk
  /// `GET /comments`, termasuk saat `postId` tidak punya komentar —
  /// hasilnya `[]`. Jadi `[]` bukan error; cabang 404 di UI hanya muncul
  /// bila server (atau proxy) benar-benar membalas 404.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List<dynamic>>(
      '/comments',
      queryParameters: <String, dynamic>{'postId': postId},
      options: Options(
        // Timeout 10 detik untuk menerima response.
        receiveTimeout: timeout,
        // Timeout 10 detik saat membuka koneksi.
        sendTimeout: timeout,
        // Timeout koneksi (handshake TCP).
        // connectTimeout hanya bisa diatur lewat BaseOptions; di sini kita
        // set agar eksplisit bila BaseOptions belum mengaturnya.
        // (Dio mengabaikan `connectTimeout` di Options pada versi lama,
        // karena itu api_client.dart juga memasang 10 detik.)
        responseType: ResponseType.json,
        // 404/500 harus menjadi error, bukan dianggap sukses.
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    // `response.data` bertipe `List<dynamic>?`. Bila server menjawab dengan
    // body kosong, nilainya null -> perlakukan sebagai list kosong supaya
    // tidak ada NullPointerException di UI.
    final raw = response.data ?? const <dynamic>[];

    // `whereType` membuang elemen yang bentuknya bukan Map (mis. server
    // mengirim pesan error berbentuk string) sehingga satu elemen rusak
    // tidak menggagalkan seluruh request.
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList(growable: false);
  }
}
