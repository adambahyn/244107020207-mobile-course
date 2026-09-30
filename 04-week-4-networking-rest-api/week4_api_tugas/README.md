# Week 4 — Daftar Data dari REST API (Mini Project)

Aplikasi Flutter daftar post dari REST API publik tanpa API key, dengan
infinite scroll, empat state UI, dan lapisan repository + Riverpod.

**Project:** `week4_api_tugas/`
**Data:** JSONPlaceholder `GET /posts?_page=1&_limit=10`
**Status verifikasi:** `flutter analyze` bersih, 19 test offline lulus,
4 test live lulus, `flutter build web --release` sukses.

---

## Tujuan

Menerapkan pemisahan tanggung jawab antara UI, state, dan jaringan:

- Data dari API dummy diambil lewat **repository**, bukan langsung dari widget.
- **Dio terpusat** (satu `baseUrl`, satu timeout, satu interceptor logging).
- **`fromJson` aman null** — JSON rusak tidak boleh mematikan layar.
- **Empat state** ditangani eksplisit: loading, error (+ tombol retry), empty, success.
- **Pagination dasar** (infinite scroll, 10 item/halaman) dengan guard request ganda.

## Fitur utama

| Fitur | Detail |
|-------|--------|
| Infinite scroll | Memuat halaman berikutnya saat scroll 300 px dari dasar |
| Guard request ganda | Flag `isLoadingMore` + `hasMore`; satu halaman tidak pernah diminta dua kali |
| Empat state UI | loading (spinner), error (+ "Coba lagi"), empty, success |
| Pull-to-refresh | Tarik ke bawah atau tombol refresh di AppBar |
| Retry cerdas | Gagal di halaman berikutnya → 10 item lama tetap tampil, footer menampilkan tombol coba lagi |
| Pesan error Indonesia | Semua `DioExceptionType` dipetakan (timeout, offline, 404, 500, 5xx, sertifikat, cancel) |
| Parsing tahan banting | Field hilang / `null` / tipe salah (String, List, Map) tidak melempar |
| Indikator akhir data | Footer "Semua data termuat." saat server kehabisan data |

## Stack teknologi

| Lapisan | Paket / berkas |
|---------|----------------|
| UI | Flutter (Material 3), `pages/post_list_page.dart` |
| State | `flutter_riverpod ^3.4.3` — `NotifierProvider` + `PagedPostsState` |
| HTTP | `dio ^5.11.1` — `data/api_client.dart` |
| Model | `data/models/post.dart` + `data/json_utils.dart` |
| Repository | `data/repositories/post_repository.dart` |
| Error mapping | `data/network_errors.dart` |
| Test | `flutter_test`, 19 test offline + 4 test live |

Tidak ada `go_router` di project ini: hanya satu layar, jadi `home:` sudah cukup
dan menambah router = menambah abstraction tanpa manfaat. Routing ada di
`week4_api/` yang memang punya beberapa halaman.

## Cara menjalankan

```bash
cd 04-week-4-networking-rest-api/week4_api_tugas

flutter pub get
flutter run                      # butuh perangkat/emulator
flutter run -d chrome            # atau di browser
```

Verifikasi:

```bash
flutter analyze                  # No issues found!
flutter test                     # 19 test, TANPA internet
flutter test test_live_api.dart  # 4 test ke server sungguhan, butuh internet
flutter build web --release      # compile end-to-end
```

Ganti backend tanpa mengubah kode:

```bash
flutter run --dart-define=API_BASE_URL=https://contoh-lain.example.com
```

Default-nya JSONPlaceholder (`data/api_client.dart`).

### Membuat ulang screenshot state empty/error/loading

Ketiga state itu tidak bisa didapat dari JSONPlaceholder (selalu 200 dan tidak
bisa dipaksa gagal), jadi dipakai server tiruan di `tools/`:

```bash
python tools/mock_api_server.py 8732        # jalankan sekali, biarkan hidup
flutter build web --release --dart-define=API_BASE_URL=http://127.0.0.1:8732 --output=build_web_mock
python -m http.server 8733 --directory build_web_mock

echo empty > tools/.mock_mode   # lalu foto  -> state empty
echo error > tools/.mock_mode   # lalu foto  -> state error
echo slow  > tools/.mock_mode   # foto pada detik ~4 -> state loading
```

## Struktur

```
lib/
  main.dart                              ProviderScope + MaterialApp
  data/
    api_client.dart                      Dio terpusat (baseUrl, timeout, LogInterceptor)
    providers.dart                       dioProvider, postRepositoryProvider
    json_utils.dart                      asIntSafe / asStringSafe
    network_errors.dart                  friendlyErrorMessage
    paged_posts.dart                     PagedPostsState + PagedPostsNotifier
    models/post.dart                     Post + fromJson aman null
    repositories/post_repository.dart    fetchPostsPage({page, limit})
  pages/
    post_list_page.dart                  4 state + infinite scroll (tanpa Dio)
test/
  post_test.dart                         9 test: fromJson + mapping error
  paged_posts_test.dart                  6 test provider + pagination (repo palsu)
  post_list_page_test.dart               5 widget test: 4 state + scroll
test_live_api.dart                       4 test ke server sungguhan
tools/
  mock_api_server.py                     server tiruan (empty/error/slow)
  shot_cdp.py                            screenshot via DevTools Protocol
docs/
  ../docs/mini-project-dan-refleksi.md   laporan lengkap + refleksi
screenshots/
  01-loading.png  02-error-retry.png  03-empty.png  04-success.png
```

## Hasil yang dicapai

```
$ flutter analyze
No issues found! (ran in 6.9s)

$ flutter test
00:04 +19: All tests passed!          # tanpa internet

$ flutter test test_live_api.dart
00:01 +4: All tests passed!           # ke JSONPlaceholder

$ flutter build web --release
√ Built build\web
```

Test live membuktikan kontrak API yang dipakai benar-benar berlaku:
halaman 1 = 10 post, halaman 2 = id 11..20, `limit: 3` dihormati, dan halaman 11
kosong (JSONPlaceholder punya 100 post — header `x-total-count: 100`).

### Cakupan test

| Berkas | Jumlah | Isi |
|--------|--------|-----|
| `test/post_test.dart` | 9 | `fromJson` (JSON lengkap, hanya `id`, `null` + tipe salah, objek kosong) + `friendlyErrorMessage` (connection, timeout, 404/500/503, non-jaringan) |
| `test/paged_posts_test.dart` | 6 | sukses, data bertambah + guard request ganda, empty, error halaman 1, error halaman berikutnya, retry |
| `test/post_list_page_test.dart` | 5 | widget: loading, success, empty, error + retry diklik, infinite scroll |
| `test_live_api.dart` | 4 | server sungguhan: pagination & limit |

**Tidak ada HTTP sungguhan di `test/`** — repository palsu menimpa method asli
dan `dioProvider` tidak pernah di-resolve, sehingga `flutter test` jalan offline.

## Screenshot

| Berkas | State |
|--------|-------|
| `screenshots/01-loading.png` | Spinner layar penuh |
| `screenshots/02-error-retry.png` | "Tidak dapat terhubung ke server…" + tombol "Coba lagi" |
| `screenshots/03-empty.png` | "Belum ada data dari server." + tombol "Muat ulang" |
| `screenshots/04-success.png` | "Posts (10)" dengan 10 post dari JSONPlaceholder |

## Catatan desain

- **UI tidak pernah menyentuh Dio.**
  `grep -rn "dio\|Dio" lib/pages lib/main.dart` hanya menemukan satu komentar,
  bukan kode. Semua akses data lewat `postRepositoryProvider`.
- **Satu kelas state, semua field final.** Tidak ada kombinasi mustahil seperti
  "sedang memuat halaman berikutnya" bersamaan dengan "data habis".
- **`hasMore` disimpulkan dari panjang halaman** (`< limit`), bukan nomor
  halaman. Bekerja walau jumlah total tidak diketahui.
- **`build()` tidak async.** Pemuatan pertama dijadwalkan lewat
  `scheduleMicrotask`; konsekuensinya test tidak boleh memanggil
  `loadFirstPage()` manual atau halaman 1 diminta dua kali.

Refleksi lengkap (kenapa UI dilarang memanggil Dio, kapan pagination server
wajib, bagaimana exception menjadi `AsyncError`, dan apa yang diperbaiki dari
hasil AI) ada di `../docs/mini-project-dan-refleksi.md`.
