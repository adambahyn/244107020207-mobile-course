import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/providers.dart';

/// Detail catatan. Membaca dari [noteByIdProvider] (repository lokal), bukan
/// dari state halaman list — jadi halaman ini benar meski dibuka langsung
/// via `/note/:id`.
class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.noteId});

  final int? noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (noteId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Catatan')),
        body: const Center(
          key: Key('invalid-id'),
          child: Text('ID catatan tidak valid'),
        ),
      );
    }

    final noteAsync = ref.watch(noteByIdProvider(noteId!));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Catatan')),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal membaca catatan: $err')),
        data: (note) => note == null
            ? const Center(
                key: Key('note-not-found'),
                child: Text('Catatan tidak ditemukan'),
              )
            : _Detail(note: note),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(note.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              note.dirty
                  ? Icons.cloud_upload_outlined
                  : Icons.cloud_done_outlined,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              note.dirty ? 'Belum tersinkron' : 'Tersinkron',
              key: const Key('detail-status'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Diperbarui: ${formatTimestamp(note.updatedAt)}'),
        const Divider(height: 32),
        Text(
          note.body.isEmpty ? '(tanpa isi)' : note.body,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
