// Draf AI apa adanya (File 2). Tidak pernah dikompilasi: import
// 'providers/announcement_search.dart' menunjuk berkas yang isinya salah, dan
// halaman ini tidak didaftarkan ke router.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/announcement_search.dart';

class AnnouncementSearchPage extends ConsumerWidget {
  const AnnouncementSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(filteredAnnouncementsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari judul pengumuman…',
            ),
            onChanged: ref.read(searchQueryProvider.notifier).set,
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Gagal memuat: $e')),
            data: (items) => items.isEmpty
                ? Center(
                    child: Text(
                      query.trim().isEmpty
                          ? 'Belum ada pengumuman'
                          : 'Tidak ada hasil untuk "${query.trim()}"',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(items[i].title),
                      subtitle: Text(items[i].summary),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}
