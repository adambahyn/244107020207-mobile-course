/// Sumber data pengumuman. Endpoint kampus belum tersedia, jadi isinya
/// payload contoh berbentuk JSON; tinggal diganti Dio/SQLite tanpa menyentuh
/// domain maupun presentation.
///
/// Sejak Minggu 11 data contoh diperbanyak menjadi [_total] baris supaya
/// profiling punya daftar panjang yang nyata untuk di-scroll dan pagination
/// bisa diuji. Isinya tetap data contoh, bukan data kampus.
class AnnouncementLocalSource {
  const AnnouncementLocalSource({
    this.latency = const Duration(milliseconds: 150),
  });

  /// Latensi tiruan pembacaan sumber data (SQLite/HTTP nyata juga tidak instan).
  final Duration latency;

  static const int _total = 400;

  Future<List<Map<String, Object?>>> readAll() async {
    await Future<void>.delayed(latency);
    return List<Map<String, Object?>>.generate(_total, _row, growable: false);
  }

  /// Satu halaman data. Dipakai pagination Minggu 11 supaya hanya halaman
  /// yang tampil yang dibaca, bukan seluruh tabel.
  Future<List<Map<String, Object?>>> readPage({
    required int page,
    required int pageSize,
  }) async {
    await Future<void>.delayed(latency);
    final start = page * pageSize;
    if (start >= _total) return const <Map<String, Object?>>[];
    final end = (start + pageSize) > _total ? _total : start + pageSize;
    return List<Map<String, Object?>>.generate(
      end - start,
      (i) => _row(start + i),
      growable: false,
    );
  }

  static Map<String, Object?> _row(int i) {
    if (i == 0) {
      return const {
        'id': '3',
        'title': 'Politeknik Negeri Malang',
        'summary': '2 pengumuman terbaru',
        'body':
            'Kelas Mobile pindah ke Ruang A2, jam 13.00. '
            'Harap hadir tepat waktu dan membawa laptop.',
        'updated_at': '2026-10-12T08:30:00.000',
      };
    }
    if (i == 1) {
      return const {
        'id': '7',
        'title': 'Beasiswa Semester Ganjil',
        'summary': 'Batas pendaftaran 20 Oktober',
        'body':
            'Pendaftaran beasiswa semester ganjil dibuka sampai 20 Oktober. '
            'Berkas diunggah melalui portal akademik.',
        'updated_at': '2026-10-20T23:59:00.000',
      };
    }
    final n = i + 1;
    return <String, Object?>{
      'id': '${1000 + n}',
      'title': 'Pengumuman $n - ${_topics[i % _topics.length]}',
      'summary': 'Ringkasan pengumuman $n untuk mahasiswa JTI',
      'body':
          'Isi pengumuman $n: ${_topics[i % _topics.length]}. '
          'Informasi ini diumumkan melalui kanal resmi jurusan dan berlaku '
          'untuk seluruh mahasiswa Teknik Informatika.',
      'updated_at':
          '2026-${(1 + i % 12).toString().padLeft(2, '0')}-'
          '${(1 + i % 28).toString().padLeft(2, '0')}T08:30:00.000',
    };
  }

  static const List<String> _topics = [
    'Jadwal kuliah',
    'Beasiswa',
    'Praktikum laboratorium',
    'Seminar nasional',
    'Batas pengisian KRS',
    'Libur akademik',
  ];
}
