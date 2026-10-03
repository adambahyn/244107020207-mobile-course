/// Model catatan. Field [dirty] menandai catatan yang belum tersinkron ke server.
class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'updated_at': updatedAt.toIso8601String(),
    'dirty': dirty ? 1 : 0,
  };

  /// Aman terhadap field hilang, null, atau tipe salah — tidak ada cast yang
  /// bisa melempar `TypeError`. Catatan: `map['id'] as num?` **tidak** aman,
  /// karena cast nullable hanya menoleransi `null`, bukan tipe lain seperti
  /// `List` atau `String`.
  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: _asIntOrNull(map['id']),
      title: _asString(map['title']),
      body: _asString(map['body']),
      updatedAt:
          DateTime.tryParse(_asString(map['updated_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dirty: _asInt(map['dirty']) == 1,
    );
  }

  static int _asInt(Object? v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  static int? _asIntOrNull(Object? v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static String _asString(Object? v) {
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    return '';
  }

  Note copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? updatedAt,
    bool? dirty,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
    );
  }
}
