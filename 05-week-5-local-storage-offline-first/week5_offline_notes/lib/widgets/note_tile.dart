import 'package:flutter/material.dart';

import '../data/local/note.dart';

/// Baris catatan. Menampilkan badge "Belum tersinkron" bila [Note.dirty].
class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, this.onTap, this.onDelete});

  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        note.body.isEmpty ? '(tanpa isi)' : note.body,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Icon(
        note.dirty ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
        color: note.dirty ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note.dirty)
            Chip(
              key: const Key('dirty-badge'),
              label: const Text('Belum tersinkron'),
              labelStyle: theme.textTheme.labelSmall,
              visualDensity: VisualDensity.compact,
              backgroundColor: theme.colorScheme.errorContainer,
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
