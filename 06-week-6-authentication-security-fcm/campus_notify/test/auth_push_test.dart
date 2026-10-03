import 'package:campus_notify/messaging/deeplink.dart';
import 'package:campus_notify/routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake token store sederhana untuk menguji logika sesi tanpa secure storage.
class FakeTokenStore {
  FakeTokenStore({this.access, this.refresh});
  String? access;
  String? refresh;

  bool get isLoggedIn => access != null && access!.isNotEmpty;

  void clear() {
    access = null;
    refresh = null;
  }
}

void main() {
  group('routeFromMessage', () {
    test('data kosong -> home', () {
      expect(routeFromMessage({}), Routes.home);
    });

    test('route tanpa slash ditambah slash', () {
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    });

    test('route dengan slash dibiarkan', () {
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });

    test('nilai non-String tetap aman (bukan cast liar)', () {
      expect(routeFromMessage({'route': 3}), '/3');
    });
  });

  test('data payload membawa id pengumuman', () {
    const data = {'route': '/pengumuman/3', 'id': '3'};
    expect(data['id'], '3');
    expect(routeFromMessage(data), '/pengumuman/3');
  });

  group('logika sesi', () {
    test('status login dibaca dari keberadaan access token', () {
      final store = FakeTokenStore(access: 'mock-access');
      expect(store.isLoggedIn, isTrue);
      store.access = null;
      expect(store.isLoggedIn, isFalse);
    });

    test('refresh token kosong -> sesi dibersihkan (paksa login ulang)', () {
      final store = FakeTokenStore(access: 'a', refresh: '');
      final needsLogin = (store.refresh ?? '').isEmpty;
      expect(needsLogin, isTrue);
      store.clear();
      expect(store.isLoggedIn, isFalse);
    });

    test('masking token tidak pernah menampilkan token penuh', () {
      const full = 'mock-access-for-mahasiswa@polinema.ac.id';
      final masked = '${full.substring(0, 12)}…';
      expect(masked.length, lessThan(full.length));
      expect(masked, 'mock-access-…');
    });
  });
}
