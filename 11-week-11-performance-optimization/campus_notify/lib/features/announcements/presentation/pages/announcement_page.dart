import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../providers/announcement_providers.dart';

/// Halaman tujuan deep link FCM: /pengumuman/:id
///
/// Minggu 11: halaman ini tidak lagi memantau seluruh daftar
/// (`announcementsProvider`), hanya item dengan id yang dibuka, lewat
/// `announcementByIdProvider`. Perubahan pada item lain tidak membangun ulang
/// halaman ini.
class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementByIdProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text('Pengumuman #$id')),
      // Data belum siap bukan berarti pengumuman tidak ada: tampilkan loader,
      // jangan teks "belum tersedia" (deep link dibuka sebelum fetch selesai).
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(key: Key('announcement-loading')),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(messageOf(e)),
        ),
        data: (item) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(
                label: Text('route: /pengumuman/$id'),
                avatar: const Icon(Icons.link, size: 16),
              ),
              const SizedBox(height: 16),
              Text(
                item?.body ??
                    'Detail pengumuman #$id belum tersedia di data contoh.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (item != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Diperbarui ${formatTanggal(item.updatedAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Halaman ini dibuka dari deep link notifikasi FCM.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
