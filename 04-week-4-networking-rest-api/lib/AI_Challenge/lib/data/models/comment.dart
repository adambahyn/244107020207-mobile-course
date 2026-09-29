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
  /// atau berubah tipe (mis. `"id": "1"`). Karena itu setiap field diambil
  /// dengan pola `as T? ?? default` sehingga tidak pernah melempar
  /// `TypeError` / `NoSuchMethodError` dan tidak pernah membuat layar
  /// crash hanya karena satu field kosong.
  ///
  /// - angka: dibaca sebagai `num?` lalu `.toInt()` — toleran terhadap
  ///   JSON yang mengirim `1.0` atau memakai tipe num lain;
  /// - string: dibaca sebagai `String?` dengan fallback string kosong.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      // `json['postId']` bertipe dynamic: kalau field tidak ada hasilnya null,
      // kalau ada tapi bukan num maka cast `as num?` gagal? — tidak, cast ke
      // tipe nullable aman: nilai non-num akan tetap melempar, jadi kita
      // bungkus angka dengan helper `_asInt` di bawah.
      postId: _asInt(json['postId']),
      id: _asInt(json['id']),
      name: _asString(json['name']),
      email: _asString(json['email']),
      body: _asString(json['body']),
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

  /// Mengubah nilai dynamic apa pun menjadi `int` dengan aman.
  ///
  /// Urutan penanganan:
  /// 1. `null` (field hilang)              -> [fallback]
  /// 2. `int` / `double` (num)             -> `.toInt()`
  /// 3. `String` yang berisi angka ("12")  -> `int.tryParse`
  /// 4. tipe lain (List, Map, bool, ...)   -> [fallback]
  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  /// Mengubah nilai dynamic apa pun menjadi `String` dengan aman.
  ///
  /// Angka dikonversi lewat `toString()` supaya `"id": 5` tetap terbaca,
  /// sedangkan `null` / List / Map jatuh ke [fallback] (string kosong).
  static String _asString(Object? value, {String fallback = ''}) {
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return fallback;
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
