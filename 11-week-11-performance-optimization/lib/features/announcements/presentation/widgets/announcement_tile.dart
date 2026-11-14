import 'package:flutter/material.dart';

import '../../domain/entities/announcement.dart';

/// Satu baris pengumuman. Dipisah dari halaman supaya:
/// - bisa `const` selama parameternya tidak berubah,
/// - parent yang rebuild tidak membangun ulang seluruh isi daftar.
class AnnouncementTile extends StatelessWidget {
  const AnnouncementTile({super.key, required this.item, required this.onTap});

  final Announcement item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: Key('announcement-${item.id}'),
      leading: Icon(item.id == '3' ? Icons.school : Icons.campaign),
      title: Text(item.title),
      subtitle: Text(item.summary),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
