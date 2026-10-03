import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../router/app_router.dart';
import '../widgets/note_tile.dart';

/// Daftar catatan. Tetap berfungsi penuh dalam mode pesawat karena semua
/// data dibaca dari SQLite lokal.
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          IconButton(
            tooltip: 'Post (cache-first)',
            icon: const Icon(Icons.article_outlined),
            onPressed: () => context.push(AppRoutes.posts),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Catatan'),
      ),
      body: Column(
        children: [
          _SyncBar(dirtyAsync: dirtyAsync),
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Gagal membaca catatan: $err')),
              data: (notes) => notes.isEmpty
                  ? const Center(
                      key: Key('empty-notes'),
                      child: Text('Belum ada catatan. Tekan + untuk menambah.'),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(notesProvider.notifier).sync(),
                      child: ListView.separated(
                        itemCount: notes.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final note = notes[i];
                          return NoteTile(
                            note: note,
                            onTap: () => context.push(AppRoutes.note(note.id!)),
                            onDelete: () async {
                              await ref
                                  .read(notesProvider.notifier)
                                  .remove(note.id!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('"${note.title}" dihapus'),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final body = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catatan baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: body,
              decoration: const InputDecoration(labelText: 'Isi'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (created == true && title.text.trim().isNotEmpty) {
      await ref
          .read(notesProvider.notifier)
          .add(title.text.trim(), body.text.trim());
    }
    title.dispose();
    body.dispose();
  }
}

/// Badge antrean sync + tombol sinkronisasi.
class _SyncBar extends ConsumerWidget {
  const _SyncBar({required this.dirtyAsync});

  final AsyncValue<int> dirtyAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dirty = dirtyAsync.value ?? 0;
    final offline = ref.watch(forceOfflineProvider);
    return Material(
      color: dirty > 0
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              offline ? Icons.wifi_off : Icons.wifi,
              size: 18,
              color: offline
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                key: const Key('dirty-count'),
                dirty == 0
                    ? 'Semua catatan tersinkron'
                    : '$dirty catatan belum tersinkron',
              ),
            ),
            TextButton(
              onPressed: dirty == 0
                  ? null
                  : () async {
                      final count = await ref
                          .read(notesProvider.notifier)
                          .sync();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$count catatan tersinkron')),
                        );
                      }
                    },
              child: const Text('Sinkron'),
            ),
          ],
        ),
      ),
    );
  }
}
