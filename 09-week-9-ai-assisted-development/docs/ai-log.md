# AI Log — Minggu 9 (AI-Assisted Development)

Catatan lengkap siklus **prompt → generate → verify → test → refactor → explain**
untuk fitur *search judul pengumuman + empty state* di `campus_notify`.

Peran generator dan reviewer diisi dua sesi AI terpisah (subagent terisolasi,
saling tidak melihat konteks), sesuai kebijakan minggu 9: AI mengusulkan,
mahasiswa memverifikasi dan memutuskan.

---

## Praktikum 1 — Prompt dan context engineering

Formula 5 slot yang dikirim ke generator:

```text
Peran: senior Flutter dev.
Konteks: project `campus_notify`, feature-first (presentation -> domain <- data),
Riverpod, pengumuman diambil lewat repository. Versi package:
flutter_riverpod 3.4.3, dio 5.11.1, go_router 18.0.2, Dart SDK ^3.13.2.
Kontrak yang ditempel: Announcement (entity), AnnouncementRepository (kontrak),
GetAnnouncements (use case), announcementsProvider (FutureProvider).
Tugas: tambah pencarian judul pengumuman (search) + empty state.
Batas: jangan ubah arsitektur, jangan panggil repository dari widget, maksimal 80 baris.
Output: kode + 3 test case + cara uji.
```

Yang **tidak** ditempel ke AI: token, API key, isi `token_store.dart`, dan sisa
repo. Yang ditempel hanya satu entity, satu kontrak repository, satu use case,
dan satu provider — sesuai aturan "beri konteks, bukan secret".

## Praktikum 2 — Output mentah generator

<!-- RAW_GENERATOR_OUTPUT -->

### Berkas 1 — `announcement_search.dart` (provider)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/announcement.dart';

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(SearchQuery.new);

// Turunan murni dari announcementsProvider — widget tak pernah sentuh repository.
final filteredAnnouncementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final items = await ref.watch(announcementsProvider.future);
  final q = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (q.isEmpty) return items;
  return items.where((a) => a.title.toLowerCase().contains(q)).toList();
});
```

### Berkas 2 — `announcement_search_page.dart` (halaman)

Halaman `ConsumerWidget` dengan `TextField` (hanya `onChanged`, tanpa
controller), `async.when` untuk loading/error/data, empty state berupa teks
`Belum ada pengumuman` bila query kosong atau `Tidak ada hasil untuk "<query>"`
bila ada query, dan `ListView.builder` berisi `ListTile` (judul + ringkasan).
Salinan mentah: `docs/ai-draft/2-announcement_search_page.dart`.

### Berkas 3 — `announcement_search_test.dart` (3 test case)

Test use case `query cocok judul -> hasil terfilter` (input `'  libur '`,
harapkan 1 id), `query kosong -> semua item`, dan widget test `tanpa hasil ->
empty state tampil` dengan fake repository dan `ProviderContainer` override.
Salinan mentah: `docs/ai-draft/3-announcement_search_test.dart`.

### Cara uji versi generator

`flutter pub get`, `flutter analyze` (klaim: 0 issue), `flutter test` (klaim:
3 test lulus), lalu manual: ketik `libur` (sisa 1 item), `zzz` (empty state),
kosongkan (semua muncul).

<!-- AKHIR RAW_GENERATOR_OUTPUT -->

## Verifikasi 6 langkah

<!-- VERIFY -->

| Langkah | Hasil |
|---|---|
| 1 | Draf dibaca penuh; jalur berkas yang dipakai AI tidak cocok dengan struktur proyek (`domain/announcement.dart`, `domain/get_announcements.dart`, `data/announcement_repository_impl.dart`, `presentation/announcement_search_page.dart`). |
| 2 | `grep -rn "package:flutter\|package:dio\|sqflite" lib/features/announcements/domain/` menghasilkan 0 baris: domain tetap murni. |
| 3 | `flutter analyze` pada draf: **22 issue**, termasuk 5 `uri_does_not_exist`, `Undefined class 'Failure'`, dan `Undefined name 'announcementsProvider'`. Keluaran lengkap: `docs/analyze-ai-draft.txt`. |
| 4 | Setelah jalur berkas, import, dan lapisan diperbaiki: `No issues found!`. |
| 5 | Empat test use case (`test/search_announcements_test.dart`) dan empat widget test (`test/announcement_search_page_test.dart`, termasuk cabang error) hijau; total suite **23 test lulus**. |
| 6 | Uji manual di perangkat: query kosong, cocok, dan tidak cocok (`screenshots/09-01..03`). |

### Halusinasi yang terbukti

**Temuan 1 — jalur berkas dan API fiktif.** AI menulis import ke berkas yang
tidak ada (`uri_does_not_exist` lima kali), memakai `Failure` tanpa import, dan
memanggil `announcementsProvider` seolah modul lain. Bukti:
`flutter analyze lib test` → 22 issue, tersimpan di `docs/analyze-ai-draft.txt`.
Perbaikan: import disesuaikan dengan struktur nyata, `Failure` diimpor dari
`core/failures.dart`, `announcementsProvider` diimpor dari
`announcement_providers.dart`.

**Temuan 2 — filter ditaruh di presentation.** Draf AI menaruh aturan filter di
provider presentasi: `grep -n "where(" docs/ai-draft/1-announcement_search_provider.dart`
→ baris 17. Ini melanggar dependency rule minggu 7 karena aturan bisnis tidak
bisa diuji tanpa Riverpod. Perbaikan: aturan pindah ke
`domain/usecases/search_announcements.dart` (baris 12); provider presentasi
sekarang 0 pemanggilan `where(`.

<!-- AKHIR_VERIFY -->

## AI Challenge — review oleh AI reviewer

<!-- REVIEW -->

Reviewer AI (sesi terpisah, hanya menerima teks kode) memberi tiga temuan.
Ringkasan keputusan:

| Temuan | Level | Keputusan | Alasan teknis | Bukti |
|---|---|---|---|---|
| 1. Query global persisten, `TextField` tanpa controller, tampilan dan hasil tidak sinkron | blocker | **diterima, diperbaiki** | Query hidup selama aplikasi, sedangkan `TextField` baru selalu kosong: pengguna melihat daftar terfilter atau empty state untuk teks yang tidak ada di layar | Test merah `test/announcement_search_persistence_test.dart` gagal di baris 58 sebelum perbaikan (`docs/red-test-persistence.txt`), hijau setelah `autoDispose` |
| 2. Test widget tidak mengunci perilaku state query | saran | **diterima, diperbaiki** | Siklus tutup-buka halaman adalah sumber bug dan tidak tersentuh test lama | `test/announcement_search_persistence_test.dart` + test cabang error `Key('search-error')` |
| 3. `searchAnnouncementsProvider` dianggap indirection tanpa dependensi, usul dihapus | saran | **ditolak** | Pola yang sama sudah dipakai `getAnnouncementsProvider` untuk use case stateless (`lib/features/announcements/presentation/providers/announcement_providers.dart` baris 14); menghapus satu-satunya use case yang memakai provider membuat dua gaya wiring dalam satu fitur, dan seam override hilang saat aturan filter tumbuh (debounce, riwayat query) | `grep -n "getAnnouncementsProvider = Provider" announcement_providers.dart` → baris 14 |

### Koreksi atas usulan reviewer

Usulan pertama reviewer hanya menandai `searchQueryProvider` perlu
`autoDispose`. Itu **tidak cukup**: `filteredAnnouncementsProvider` (waktu itu
`Provider` biasa) terus memegang listener ke `searchQueryProvider`, sehingga
provider query tidak pernah dibuang. Test pembukti tetap merah setelah
`searchQueryProvider` diubah. Perbaikan yang benar adalah `autoDispose` pada
kedua provider di rantai itu, ditambah `TextEditingController` yang diisi dari
nilai query saat halaman dibangun. Temuan reviewer benar, tetapi resepnya belum
lengkap — bukti di `docs/red-test-persistence.txt`.

<!-- AKHIR_REVIEW -->

## Keputusan per berkas

<!-- KEPUTUSAN -->

| Berkas | Keputusan | Tindakan |
|---|---|---|
| `presentation/providers/announcement_search.dart` | terima + refactor | Import diperbaiki, aturan filter dipindah ke domain, `FutureProvider` diganti `Provider<AsyncValue<...>>` agar status loading/error tidak hilang, kedua provider di rantai dibuat `autoDispose` |
| `presentation/pages/announcement_search_page.dart` | terima + refactor | Halaman dipindah ke `presentation/pages/`, `ConsumerWidget` menjadi `ConsumerStatefulWidget` dengan `TextEditingController`, `Key` ditambahkan untuk test, tombol cari didaftarkan di `routes.dart` + `router.dart` + app bar `home_page.dart` |
| `test/.../announcement_search_test.dart` | tolak, tulis manual | Fake repository pada draf mengimplementasikan kelas yang tidak diimpor; test ditulis ulang: empat test use case murni dan empat widget test |

### Refleksi

Halusinasi yang terbukti adalah jalur berkas fiktif: lima `uri_does_not_exist`
dan satu `Failure` tanpa import, dibuktikan `flutter analyze` (22 issue) dan
diperbaiki satu per satu sampai nol issue.

Prompt yang paling membantu adalah versi 5 slot dengan kontrak repository
ditempel apa adanya, karena hasilnya memakai bentuk record
`({List<Announcement> items, Failure? failure})` yang sama dengan domain.
Perubahan yang dilakukan: menambahkan larangan eksplisit memakai Riverpod di
domain dan menyebutkan nama berkas nyata, karena versi pertama tetap menaruh
filter di presentation.

Refactor yang dilakukan: aturan filter dipindah dari provider presentasi ke
`SearchAnnouncements` di domain, sehingga bisa diuji tanpa Riverpod, dan rantai
provider dibuat `autoDispose` agar state pencarian tidak bocor antar kunjungan
halaman.

Keputusan tersulit adalah menolak temuan ketiga reviewer. Secara prinsip "kode
paling sedikit" usulan itu benar, tetapi menerapkannya akan membuat fitur ini
memakai pola wiring yang berbeda dari `GetAnnouncements`; biaya konsistensi
lebih besar daripada tiga baris yang dihemat.

<!-- AKHIR_KEPUTUSAN -->
