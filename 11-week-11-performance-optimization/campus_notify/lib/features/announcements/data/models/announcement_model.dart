import '../../domain/entities/announcement.dart';

/// Mapping hanya di model: JSON/SQLite -> entity.
class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.summary,
    required super.body,
    required super.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, Object?> json) {
    return AnnouncementModel(
      id: json['id']! as String,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      body: json['body'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'body': body,
    'updated_at': updatedAt.toIso8601String(),
  };

  Announcement toEntity() => Announcement(
    id: id,
    title: title,
    summary: summary,
    body: body,
    updatedAt: updatedAt,
  );
}
