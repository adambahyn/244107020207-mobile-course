import '../json_utils.dart';

/// Model data untuk satu post dari endpoint `GET /posts` JSONPlaceholder.
///
/// Kontrak API (contoh satu item):
/// ```json
/// {
///   "userId": 1,
///   "id": 1,
///   "title": "sunt aut facere repellat provident",
///   "body": "quia et suscipit\nsuscipit recusandae..."
/// }
/// ```
class Post {
  /// Konstruktor `const` supaya objek immutable dan bisa dibuat di
  /// compile-time (hemat rebuild saat dipakai widget `const`).
  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  /// ID pemilik post.
  final int userId;

  /// ID unik post.
  final int id;

  /// Judul post.
  final String title;

  /// Isi post (bisa multi-baris).
  final String body;

  /// Parsing JSON yang **aman terhadap field hilang / null / tipe salah**.
  ///
  /// Sebelumnya memakai `json['userId'] as num? ?? 0` yang aman untuk `null`
  /// tetapi tetap melempar `TypeError` bila server mengirim tipe lain
  /// (mis. `"userId": "1"` atau List). Sekarang memakai helper bersama
  /// [asIntSafe] / [asStringSafe] dari `json_utils.dart`, sama seperti
  /// `Comment.fromJson`, sehingga tidak pernah melempar dan hasilnya konsisten.
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: asIntSafe(json['userId']),
      id: asIntSafe(json['id']),
      title: asStringSafe(json['title']),
      body: asStringSafe(json['body']),
    );
  }

  /// Kebalikan dari [fromJson]; berguna untuk cache lokal / unit test.
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'id': id,
    'title': title,
    'body': body,
  };

  /// Menyalin objek dengan sebagian field diganti (immutable-friendly).
  Post copyWith({int? userId, int? id, String? title, String? body}) {
    return Post(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  /// Ditampilkan di log / debug supaya mudah dilacak.
  @override
  String toString() => 'Post(id: $id, userId: $userId, title: $title)';

  /// Dua [Post] dianggap sama jika seluruh field-nya sama.
  /// Dipakai test dan widget yang membandingkan daftar post.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post &&
          other.userId == userId &&
          other.id == id &&
          other.title == title &&
          other.body == body;

  @override
  int get hashCode => Object.hash(userId, id, title, body);
}
