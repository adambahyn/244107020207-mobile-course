import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/usecases/search_announcements.dart';
import 'package:flutter_test/flutter_test.dart';

final _waktu = DateTime(2026, 10, 20);

Announcement _a(String id, String title) => Announcement(
  id: id,
  title: title,
  summary: 'ringkas $id',
  body: 'isi $id',
  updatedAt: _waktu,
);

final _data = [
  _a('3', 'Politeknik Negeri Malang'),
  _a('7', 'Beasiswa Semester Ganjil'),
];

void main() {
  const search = SearchAnnouncements();

  test('query cocok mengabaikan huruf besar dan spasi tepi', () {
    final hasil = search(_data, '  BEASISWA  ');
    expect(hasil.map((e) => e.id), ['7']);
  });

  test('query tak cocok mengembalikan daftar kosong', () {
    expect(search(_data, 'zzz-tak-ada'), isEmpty);
  });

  test('query kosong mengembalikan semua item apa adanya', () {
    expect(search(_data, '   '), hasLength(2));
    expect(identical(search(_data, ''), _data), isTrue);
  });

  test('kata tengah judul juga cocok', () {
    expect(search(_data, 'negeri').single.id, '3');
  });
}
