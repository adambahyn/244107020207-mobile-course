# Week 4 — Testing: unit test model + mock repository

Dokumentasi hasil pengerjaan + verifikasi mandiri checklist Week 4.
Semua klaim di bawah berasal dari perintah yang benar-benar dijalankan;
keluaran mentahnya disalin apa adanya.

Perintah dijalankan dari `04-week-4-networking-rest-api/week4_api`.

---

## 1. Yang dikerjakan

| File | Isi |
|------|-----|
| `test/post_test.dart` | **baru** — sesuai spesifikasi tugas: import + `FakePostRepository` + `main()` 4 test |
| `test/paged_posts_test.dart` | **baru** — verifikasi pagination (checklist butir 3) tanpa internet |
| `lib/data/network_errors.dart` | dipakai test; **tidak diubah** |
| `lib/data/providers.dart` | helper `readPostsOnce` / `readPostsErrorOnce` dipakai test; **tidak diubah** |

`test/post_test.dart` berisi tepat 4 test:

1. `fromJson aman terhadap field yang hilang` — `Post.fromJson({'id': 7})` →
   `id == 7`, `title == ''`, `userId == 0` (tidak melempar).
2. `friendlyErrorMessage untuk connection error` — `contains('terhubung')`.
3. `provider sukses dengan repository palsu` — lewat `readPostsOnce`.
4. `provider error dengan repository palsu` — lewat `readPostsErrorOnce`.

Tambahan kecil di luar naskah yang diminta: import `network_errors.dart`
(agar simbol `friendlyErrorMessage` tidak ambigu, hasil pemindahan fungsi di
commit sebelumnya) dan format `dart format` pada blok konstruktor
`FakePostRepository` (naskah asli satu baris lebih panjang dari 80 kolom).

### Tidak ada HTTP sungguhan di dalam test

`FakePostRepository` menimpa **kedua** method repository
(`fetchPosts` dan `fetchPostsPage`), dan `dioProvider` tidak pernah
di-resolve pada test mana pun — `Dio()` di konstruktor hanya memenuhi
parameter `super`, tidak pernah dipakai menelepon.

```bash
$ grep -rln "http\|HttpClient\|createDio\|dioProvider" test/
test/post_test.dart      # <- hanya import dio untuk DioException
```

Tidak ada `createDio()` / `dioProvider` di folder `test/`. Test juga tidak
butuh jaringan: di bawah ini `flutter test` (37 test) lulus tanpa memanggil
`jsonplaceholder.typicode.com`.

---

## 2. Bukti eksekusi

```bash
$ flutter analyze
Analyzing week4_api...
No issues found! (ran in 12.6s)
```

```bash
$ flutter test
00:15 +35: .../test/widget_test.dart: menampilkan daftar komentar dari provider
00:18 +36: .../test/widget_test.dart: menampilkan pesan kosong bila tidak ada komentar
00:18 +37: All tests passed!
```

4 test yang diminta tugas:

```bash
$ flutter test test/post_test.dart -r expanded
00:00 +0: fromJson aman terhadap field yang hilang
00:00 +1: friendlyErrorMessage untuk connection error
00:00 +2: provider sukses dengan repository palsu
00:00 +3: provider error dengan repository palsu
00:00 +4: All tests passed!
```

Pagination (tanpa internet, repository palsu yang mencatat nomor halaman):

```bash
$ flutter test test/paged_posts_test.dart -r expanded
00:00 +0: halaman berikutnya dimuat sekali, lalu hasMore jadi false
00:00 +1: error halaman berikutnya: data lama tetap ada, tidak menggandakan
00:00 +2: All tests passed!
```

---

## 3. Checklist verifikasi mandiri

### 3.1 UI tidak memanggil Dio langsung

```bash
$ grep -rn "dio\|Dio" lib/pages lib/widgets lib/main.dart lib/router
lib/pages/comment_list_page.dart:13:/// Perhatikan: halaman ini **tidak** tahu apa itu Dio, URL, atau `DioException`.
```

Terpenuhi — satu-satunya kemunculan adalah komentar dokumentasi. Semua akses
data lewat provider yang bergantung pada `postRepositoryProvider` /
`commentRepositoryProvider`.

### 3.2 Empat state tampil

| State | Lokasi |
|-------|--------|
| loading | `post_list_page.dart:28`, `comment_list_page.dart:41`, `post_detail_page.dart:37` (`CircularProgressIndicator`) |
| error + retry | `post_list_page.dart:29-45` (`friendlyErrorMessage` + tombol "Coba lagi" → `ref.invalidate`) |
| empty | `post_list_page.dart:47-49` ("Belum ada data dari server.") |
| success | `post_list_page.dart:50-64` (`RefreshIndicator` + `ListView.builder` + `PostTile`) |

Sudah ada sejak commit `f05fe58`; tidak diubah pada sesi ini.
Catatan jujur: halaman paged tidak punya teks "kosong" tersendiri — bila
halaman pertama balik kosong, `hasMore` langsung `false` sehingga yang tampil
adalah penanda akhir data "Semua data termuat." (`paged_post_page.dart:69-73`).

### 3.3 Pagination

Diuji eksplisit di `test/paged_posts_test.dart`:

- **data bertambah saat scroll** — halaman 1 (10 item) + halaman 2 → 20 item.
- **tidak ada request ganda** — dua `loadNextPage()` dipanggil **tanpa await**;
  `repo.requestedPages` tetap `[1, 2]`, jadi guard `isLoadingMore` benar-benar
  bekerja. Skenario ini yang realistis: listener `ScrollController` bisa
  memanggil berkali-kali dalam satu frame.
- **indikator akhir data** — halaman pendek (`< limit`) → `hasMore == false`;
  panggilan berikutnya tidak menembak repository lagi, dan UI menampilkan
  "Semua data termuat."
- Bonus: error di halaman berikutnya mempertahankan 10 item lama, `page` tidak
  maju, `isLoadingMore` kembali `false` (spinner tidak nyangkut).

**Temuan nyata dari probe.** Versi pertama test memanggil `loadFirstPage()`
secara manual setelah `container.read(pagedPostsProvider)`, dan hasilnya
`requestedPages == [1, 1, 2]` — halaman 1 diminta **dua kali**. Penyebabnya:
`PagedPostsNotifier.build()` sudah menjadwalkan `Future.microtask(loadFirstPage)`
(`paged_posts.dart:25`), jadi memanggilnya lagi = duplikat. Di aplikasi ini
tidak terjadi karena `build()` hanya dijalankan sekali per container/scope,
tetapi test yang tidak tahu soal microtask itu langsung menangkap polanya.
Test final tidak memanggil `loadFirstPage()` manual — cukup memutar event loop
(`Future.delayed(Duration.zero)` dua kali) supaya microtask selesai.

### 3.4 `flutter analyze` bersih + semua test lulus

`No issues found!` dan `37/37` test lulus (lihat bagian 2).

### 3.5 Hasil AI diverifikasi dan didokumentasikan

Dokumen ini. Setiap klaim punya perintah dan keluarannya.

---

## 4. Yang **tidak** dikerjakan

- `flutter build web --release` — tidak dijalankan; tidak diminta tugas ini
  dan tidak menambah bukti untuk test unit.
- Test HTTP sungguhan (`test_comment_repo_e2e.dart`,
  `test_comment_provider_e2e.dart` di akar `week4_api`) — butuh internet,
  sengaja di luar folder `test/`.

## 5. Pola untuk Minggu 12 (Testing & QA)

Override repository palsu lewat `postRepositoryProvider.overrideWithValue(...)`
di dalam `ProviderContainer` adalah fondasi mock API. Dua hal yang wajib
diingat saat memakainya lagi:

1. `retry: (retryCount, error) => null` pada provider. Tanpa itu Riverpod 3
   mencoba ulang 10x dengan backoff sampai ~6,4 s, sehingga test error bisa
   menggantung. Sudah dipasang di `postListProvider`.
2. `addTearDown(container.dispose)` selalu, supaya tidak ada provider yang
   bocor antar test.
