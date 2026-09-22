import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model data sederhana yang dipakai di seluruh aplikasi.
/// Dibuat immutable (`final` + constructor `const`) supaya aman dibagikan
/// antar widget tanpa risiko data berubah di tengah jalan.
class Item {
  const Item({
    required this.id,
    required this.name,
    required this.nim,
    required this.skill,
  });

  /// Dipakai sebagai bagian dari URL: '/detail/${item.id}'.
  final int id;
  final String name;
  final String nim;
  final String skill;
}

/// Simulasi proses pengambilan data dari server/API.
///
/// `await Future.delayed(Duration(seconds: 2))` sengaja dipakai supaya state
/// LOADING terlihat jelas di UI selama 2 detik sebelum data muncul.
Future<List<Item>> fetchItems() async {
  await Future.delayed(const Duration(seconds: 2));

  return const <Item>[
    Item(
      id: 1,
      name: 'Andi Pratama',
      nim: '211201231',
      skill: 'Flutter & Dart',
    ),
    Item(
      id: 2,
      name: 'Budi Santoso',
      nim: '211201232',
      skill: 'Backend & Node.js',
    ),
    Item(id: 3, name: 'Citra Dewi', nim: '211201233', skill: 'UI/UX Design'),
    Item(id: 4, name: 'Dian Permata', nim: '211201234', skill: 'Data Science'),
    Item(id: 5, name: 'Eko Nugroho', nim: '211201235', skill: 'Cyber Security'),
    Item(
      id: 6,
      name: 'Fajar Ramadhan',
      nim: '211201236',
      skill: 'Cloud & DevOps',
    ),
    Item(
      id: 7,
      name: 'Gita Larasati',
      nim: '211201237',
      skill: 'Mobile Android',
    ),
    Item(
      id: 8,
      name: 'Hendra Wijaya',
      nim: '211201238',
      skill: 'Game Development',
    ),
  ];
}

/// ---------------------------------------------------------------------------
/// PROVIDER ASINKRON
/// ---------------------------------------------------------------------------
/// `FutureProvider<T>` adalah provider yang menghasilkan nilai bertipe
/// `AsyncValue<T>` (bukan langsung `T`). AsyncValue punya 3 kemungkinan state:
///
///   1. AsyncLoading -> data masih diproses (belum selesai)
///   2. AsyncData    -> data berhasil diperoleh
///   3. AsyncError   -> terjadi exception saat pengambilan data
///
/// Di UI, ketiga state itu ditangani dengan pola `AsyncValue.when(...)`
/// (lihat home_screen.dart dan detail_screen.dart).
///
/// Provider ini bersifat "lazy": fungsi fetchItems() baru dijalankan saat ada
/// widget yang pertama kali `ref.watch(itemProvider)`. Hasilnya di-cache,
/// sehingga perpindahan halaman tidak memicu loading ulang selama cache ada.
///
/// Catatan Riverpod 3: provider yang melempar exception otomatis di-RETRY
/// (backoff 200ms -> 6.4s). Di praktikum ini retry dimatikan lewat
/// `retry: (retryCount, error) => null` supaya state error bisa diamati dengan
/// tenang, dan pemuatan ulang dilakukan manual via tombol refresh /
/// ref.invalidate().
final FutureProvider<List<Item>> itemProvider = FutureProvider<List<Item>>(
  (Ref ref) async => fetchItems(),
  retry: (int retryCount, Object error) => null,
);

/// ---------------------------------------------------------------------------
/// PROVIDER TURUNAN (family) + PARAMETER
/// ---------------------------------------------------------------------------
/// `FutureProvider.family` dipakai ketika provider membutuhkan argumen, di sini
/// argumennya adalah `int id` yang berasal dari path parameter '/detail/:id'.
///
/// Provider ini melakukan `ref.watch(itemProvider.future)` sehingga:
/// - bila data induk sudah ada di cache, hasilnya langsung tersedia;
/// - bila belum ada, dia ikut menunggu (state loading) sampai data siap.
///
/// Jika id tidak ditemukan, provider melempar error -> AsyncError -> ditangkap
/// oleh cabang `error:` pada AsyncValue.when di halaman detail.
/// (Tipe otomatis di-infer sebagai FutureProviderFamily; class-nya tidak
/// diekspor di entry point flutter_riverpod sehingga tidak ditulis eksplisit.)
final itemByIdProvider = FutureProvider.family<Item, int>((
  Ref ref,
  int id,
) async {
  final List<Item> items = await ref.watch(itemProvider.future);

  return items.firstWhere(
    (Item item) => item.id == id,
    orElse: () => throw StateError('Item dengan id $id tidak ditemukan.'),
  );
});
