/// Sumber data pengumuman. Endpoint kampus belum tersedia, jadi isinya
/// payload contoh berbentuk JSON; tinggal diganti Dio/SQLite tanpa menyentuh
/// domain maupun presentation.
class AnnouncementLocalSource {
  const AnnouncementLocalSource();

  Future<List<Map<String, Object?>>> readAll() async => const [
    {
      'id': '3',
      'title': 'Politeknik Negeri Malang',
      'summary': '2 pengumuman terbaru',
      'body':
          'Kelas Mobile pindah ke Ruang A2, jam 13.00. '
          'Harap hadir tepat waktu dan membawa laptop.',
      'updated_at': '2026-10-12T08:30:00.000',
    },
    {
      'id': '7',
      'title': 'Beasiswa Semester Ganjil',
      'summary': 'Batas pendaftaran 20 Oktober',
      'body':
          'Pendaftaran beasiswa semester ganjil dibuka sampai 20 Oktober. '
          'Berkas diunggah melalui portal akademik.',
      'updated_at': '2026-10-20T23:59:00.000',
    },
  ];
}
