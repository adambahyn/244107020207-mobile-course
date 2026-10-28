/// Entity pengumuman. Murni Dart: tanpa toMap/fromJson.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String body;
  final DateTime updatedAt;
}
