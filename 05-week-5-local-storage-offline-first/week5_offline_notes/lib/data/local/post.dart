import 'dart:convert';

/// Model data API Minggu 4 (`GET /posts` JSONPlaceholder), dipakai fitur
/// cache-first. Aman null: setiap field dibaca dengan fallback.
class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    this.body = '',
  });

  final int id;
  final int userId;
  final String title;
  final String body;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: _asInt(json['id']),
      userId: _asInt(json['userId']),
      title: _asString(json['title']),
      body: _asString(json['body']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'body': body,
  };

  static int _asInt(Object? v, {int fallback = 0}) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  static String _asString(Object? v, {String fallback = ''}) {
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    return fallback;
  }
}

/// Helper tabel `cached_posts`: payload JSON + waktu cache.
class CachedPost {
  const CachedPost({
    required this.id,
    required this.payload,
    required this.cachedAt,
  });

  final int id;
  final String payload;
  final DateTime cachedAt;

  factory CachedPost.fromRow(Map<String, Object?> row) => CachedPost(
    id: (row['id'] as num?)?.toInt() ?? 0,
    payload: row['payload'] as String? ?? '{}',
    cachedAt:
        DateTime.tryParse(row['cached_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Toleran terhadap payload rusak: baris yang tidak bisa diparse diabaikan.
  Post? toPost() {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      return Post.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
