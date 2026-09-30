import '../json_utils.dart';

/// Model satu post dari `GET /posts` (JSONPlaceholder).
///
/// Kontrak API:
/// ```json
/// { "userId": 1, "id": 1, "title": "sunt aut...", "body": "quia et..." }
/// ```
class Post {
  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  final int userId;
  final int id;
  final String title;
  final String body;

  /// Parsing **aman null** dan aman tipe salah.
  ///
  /// Semua field dilewatkan helper `asIntSafe` / `asStringSafe`, jadi JSON
  /// rusak (`{}`, `{"id": "7"}`, `{"title": null}`) tidak pernah melempar —
  /// hanya menghasilkan nilai default.
  factory Post.fromJson(Map<String, dynamic> json) => Post(
    userId: asIntSafe(json['userId']),
    id: asIntSafe(json['id']),
    title: asStringSafe(json['title']),
    body: asStringSafe(json['body']),
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'id': id,
    'title': title,
    'body': body,
  };

  @override
  String toString() => 'Post(id: $id, userId: $userId, title: $title)';

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
