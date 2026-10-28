import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes.dart';
import '../../domain/entities/announcement.dart';
import '../providers/announcement_search.dart';

/// Halaman pencarian judul pengumuman + empty state.
/// UI saja: aturan filter ada di `SearchAnnouncements` (domain).
class AnnouncementSearchPage extends ConsumerStatefulWidget {
  const AnnouncementSearchPage({super.key});

  @override
  ConsumerState<AnnouncementSearchPage> createState() =>
      _AnnouncementSearchPageState();
}

class _AnnouncementSearchPageState
    extends ConsumerState<AnnouncementSearchPage> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(searchQueryProvider),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredAnnouncementsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cari pengumuman')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              key: const Key('search-field'),
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari judul pengumuman',
                border: OutlineInputBorder(),
              ),
              onChanged: ref.read(searchQueryProvider.notifier).set,
            ),
          ),
          Expanded(
            child: filtered.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Gagal memuat: $e', key: const Key('search-error')),
              ),
              data: (items) => items.isEmpty
                  ? _EmptyState(query: query)
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) => _tile(context, items[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Announcement item) => ListTile(
    key: Key('search-result-${item.id}'),
    leading: const Icon(Icons.campaign),
    title: Text(item.title),
    subtitle: Text(item.summary),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.push(Routes.announcementById(item.id)),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 12),
            Text(
              q.isEmpty ? 'Belum ada pengumuman' : 'Tidak ada hasil untuk "$q"',
              key: const Key('search-empty-state'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
