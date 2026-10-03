import 'package:flutter/material.dart';

/// Halaman tujuan deep link FCM: /pengumuman/:id
class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  static const _bodies = {
    '3':
        'Kelas Mobile pindah ke Ruang A2, jam 13.00. '
        'Harap hadir tepat waktu dan membawa laptop.',
    '7':
        'Pendaftaran beasiswa semester ganjil dibuka sampai 20 Oktober. '
        'Berkas diunggah melalui portal akademik.',
  };

  @override
  Widget build(BuildContext context) {
    final body =
        _bodies[id] ?? 'Detail pengumuman #$id belum tersedia di data contoh.';
    return Scaffold(
      appBar: AppBar(title: Text('Pengumuman #$id')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text('route: /pengumuman/$id'),
              avatar: const Icon(Icons.link, size: 16),
            ),
            const SizedBox(height: 16),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            const Text(
              'Halaman ini dibuka dari deep link notifikasi FCM.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
