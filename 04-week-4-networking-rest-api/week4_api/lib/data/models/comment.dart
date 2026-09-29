/// Model data untuk satu komentar dari endpoint
/// `GET /comments?postId={id}` JSONPlaceholder.
///
/// Kontrak API (contoh satu item):
/// ```json
/// {
///   "postId": 1,
///   "id": 1,
///   "name": "id labore ex et quam laborum",
///   "email": "Eliseo@gardner.biz",
///   "body": "laudantium enim quasi est quidem ..."
/// }
/// ```
library;

import '../json_utils.dart';

class Comment {
  /// Konstruktor `const` supaya objek ini immutable dan bisa dibuat
  /// di compile-time (hemat rebuild saat dipakai di widget `const`).
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  /// ID post induk. Di endpoint ini selalu ada, tapi tetap kita beri
  /// nilai default 0 saat parsing gagal.
  final int postId;

  /// ID unik komentar.
  final int id;

  /// Nama pengirim komentar.
  final String name;

  /// Email pengirim komentar.
  final String email;

  /// Isi komentar.
  final String body;

  /// Parsing JSON yang **aman terhadap field hilang / null / tipe salah**.
  ///
  /// JSONPlaceholder sebenarnya selalu mengirim kelima field, tetapi data
  /// dari jaringan tidak boleh dipercaya: field bisa hilang, bernilai `null`,
  /// atau berubah tipe (mis. `"id": "1"`). Karena itu setiap field dibaca lewat
  /// helper bersama [asIntSafe] / [asStringSafe] dari `json_utils.dart` yang
  /// mengembalikan nilai default saat tipe datanya tidak sesuai — tidak pernah
  /// melempar `TypeError` / `NoSuchMethodError`, jadi satu field kosong tidak
  /// membuat layar crash.
  ///
  /// - angka: `num` apa pun di-`.toInt()`, string angka di-`int.tryParse`,
  ///   sisanya -> 0;
  /// - string: diambil apa adanya, `num`/`bool` di-`toString()`,
  ///   sisanya -> string kosong.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: asIntSafe(json['postId']),
      id: asIntSafe(json['id']),
      name: asStringSafe(json['name']),
      email: asStringSafe(json['email']),
      body: asStringSafe(json['body']),
    );
  }

  /// Kebalikan dari [fromJson]; berguna untuk cache lokal / unit test.
  Map<String, dynamic> toJson() => {
    'postId': postId,
    'id': id,
    'name': name,
    'email': email,
    'body': body,
  };

  /// Menyalin objek dengan sebagian field diganti (immutable-friendly).
  Comment copyWith({
    int? postId,
    int? id,
    String? name,
    String? email,
    String? body,
  }) {
    return Comment(
      postId: postId ?? this.postId,
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      body: body ?? this.body,
    );
  }

  /// Ditampilkan di log / debug supaya mudah dilacak.
  @override
  String toString() =>
      'Comment(postId: $postId, id: $id, name: $name, email: $email)';

  /// Dua [Comment] dianggap sama jika seluruh field-nya sama.
  /// Dipakai oleh test & oleh widget yang membandingkan list komentar.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment &&
          other.postId == postId &&
          other.id == id &&
          other.name == name &&
          other.email == email &&
          other.body == body;

  @override
  int get hashCode => Object.hash(postId, id, name, email, body);
}
