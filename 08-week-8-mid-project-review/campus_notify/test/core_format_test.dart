import 'package:campus_notify/core/format.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatTanggal', () {
    test('tanggal panjang bahasa Indonesia', () {
      expect(formatTanggal(DateTime(2026, 9, 27)), '27 September 2026');
      expect(formatTanggal(DateTime(2026, 1, 5)), '5 Januari 2026');
    });
  });

  group('maskToken', () {
    test('token kosong ditandai', () {
      expect(maskToken(null), '(kosong)');
      expect(maskToken(''), '(kosong)');
    });

    test('token panjang dipotong 12 karakter', () {
      const full = 'mock-access-for-mahasiswa@polinema.ac.id';
      expect(maskToken(full), 'mock-access-…');
      expect(maskToken(full).length, lessThan(full.length));
    });

    test('token pendek tidak melempar RangeError', () {
      expect(maskToken('abc'), 'abc…');
      expect(maskToken('123456789012'), '123456789012…');
    });
  });

  group('routeFromMessage', () {
    test('data kosong -> home', () {
      expect(routeFromMessage({}), '/');
    });

    test('route tanpa slash ditambah slash', () {
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    });

    test('route dengan slash dibiarkan', () {
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });

    test('nilai non-String tetap aman', () {
      expect(routeFromMessage({'route': 3}), '/3');
    });
  });

  test('messageOf memakai pesan Failure apa adanya', () {
    expect(messageOf(const AuthFailure('Sesi berakhir.')), 'Sesi berakhir.');
    expect(messageOf(Exception('meledak')), 'meledak');
  });
}
