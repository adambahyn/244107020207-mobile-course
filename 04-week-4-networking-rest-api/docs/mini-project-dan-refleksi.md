# Week 4 — Mini Project: Daftar Data dari REST API

Dokumentasi pengerjaan mini project Week 4 di `04-week-4-networking-rest-api/week4_api_tugas/`.
Semua klaim di bawah disertai perintah yang benar-benar dijalankan dan keluarannya.

---

## 1. Ringkasan

Aplikasi daftar post dari JSONPlaceholder (`GET /posts?_page=1&_limit=10`) dengan
infinite scroll. Dibangun di project baru `week4_api_tugas/` (scaffold Flutter
kosong, bukan menyalin `week4_api/`).

### Pemenuhan ketentuan tugas

| Ketentuan | Implementasi | Bukti |
|-----------|--------------|-------|
| Data dari API dummy tanpa key | JSONPlaceholder `/posts` | `test_live_api.dart` 4/4 lulus |
| Repository + Riverpod | `providers.dart`, `paged_posts.dart`, `post_repository.dart` | UI hanya `ref.watch` |
| Dio terpusat (base URL, timeout, interceptor) | `api_client.dart` — 1 file | grep: Dio tidak muncul di UI |
| `fromJson` aman null | `json_utils.dart` + `models/post.dart` | 4 unit test |
| 4 state: loading, error+retry, empty, success | `post_list_page.dart` | 5 widget test + 4 screenshot |
| Pagination 10 item + guard request ganda | `paged_posts.dart` | 6 test provider |
| Minimal 2 test lulus | 19 test offline + 4 test live | `flutter test` |
| Struktur `lib/ test/ docs/ README.md screenshots/` | ada semua | — |

---

## 2. Struktur

```
week4_api_tugas/
  lib/
    main.dart                        ProviderScope + MaterialApp
    data/
      api_client.dart                Dio terpusat: baseUrl, timeout, LogInterceptor
      providers.dart                 dioProvider, postRepositoryProvider
      json_utils.dart                asIntSafe / asStringSafe (tidak pernah melempar)
      network_errors.dart            friendlyErrorMessage (semua DioExceptionType)
      paged_posts.dart               PagedPostsState + PagedPostsNotifier + provider
      models/post.dart               Post + fromJson aman null
      repositories/post_repository.dart  fetchPostsPage(page, limit)
    pages/
      post_list_page.dart            4 state + infinite scroll (tanpa Dio)
  test/
    post_test.dart                   9 test: fromJson + mapping error
    paged_posts_test.dart            6 test provider + pagination (repo palsu)
    post_list_page_test.dart         5 widget test: 4 state + scroll
  test_live_api.dart                 4 test ke server sungguhan (butuh internet)
  tools/
    mock_api_server.py               server tiruan untuk screenshot empty/error/loading
    shot_cdp.py                      screenshot via CDP (untuk state loading)
```

---

## 3. Hasil verifikasi

```bash
$ flutter analyze
No issues found! (ran in 6.9s)
```

```bash
$ flutter test                 # tanpa internet
00:03 +18: ... post_list_page_test.dart: infinite scroll: data bertambah...
00:04 +19: All tests passed!
```

```bash
$ flutter test test_live_api.dart   # ke jsonplaceholder.typicode.com
00:01 +4: All tests passed!
```

```bash
$ flutter build web --release
√ Built build\web                      # compile end-to-end sungguhan
```

Andaikan hanya ini yang dijalankan pun, klaim "pagination server benar" sudah
terbukti: `test_live_api.dart` memeriksa halaman 2 berisi id 11..20, `limit: 3`
dihormati, dan halaman 11 kosong.

### Screenshot (dari aplikasi yang benar-benar berjalan)

| File | State | Cara didapat |
|------|-------|--------------|
| `screenshots/01-loading.png` | loading | mock mode `slow` (balas 6 s), foto pada detik 4,5 via CDP |
| `screenshots/02-error-retry.png` | error + retry | mock mode `error` (socket diputus → `connectionError`) |
| `screenshots/03-empty.png` | empty | mock mode `empty` (200 OK + `[]`) |
| `screenshots/04-success.png` | success | server sungguhan, 10 post pertama |

State 04 memakai data asli JSONPlaceholder. State 01–03 sengaja memakai
`tools/mock_api_server.py` karena JSONPlaceholder selalu membalas 200 dan tidak
bisa dipaksa error atau kosong. Build web dengan base URL berbeda:

```bash
flutter build web --release --dart-define=API_BASE_URL=http://127.0.0.1:8732
```

`apiBaseUrl` (`api_client.dart`) adalah `String.fromEnvironment` dengan default
JSONPlaceholder, jadi aplikasi biasa tetap jalan tanpa flag apa pun.

---

## 4. AI Challenge — prompt, hasil AI, dan perbaikan

### Prompt yang dipakai

> Buat aplikasi Flutter daftar post dari JSONPlaceholder dengan Dio + Riverpod:
> repository terpisah, model `fromJson` aman null, empat state UI (loading,
> error + retry, empty, success), dan infinite scroll 10 item per halaman
> dengan guard request ganda.

### Yang AI hasilkan dan langsung dipakai

- Kerangka `PostRepository.fetchPostsPage({page, limit})` dengan
  `queryParameters: {'_page': page, '_limit': limit}` — cocok dengan API, tidak
  diubah.
- Bentuk `DioExceptionType` switch untuk pesan error — dipakai, tetapi
  dilengkapi kasus `badCertificate`, `cancel`, dan `transformTimeout` yang
  semula hilang.
- Pola `AsyncValue` → `when(loading/error/data)` pada awalnya, tapi lihat
  catatan 3 di bawah.

### Perbaikan yang saya lakukan, dan alasannya

**(1) `as int? ?? 0` diganti helper `is`-check.**
AI awalnya memakai cast nullable. Cast nullable hanya menoleransi `null`, bukan
tipe lain: `{"id": [1,2,3]}` atau `{"id": "7"}` tetap melempar `TypeError` dan
layar crash. Diganti `asIntSafe` / `asStringSafe` yang memakai `is num` /
`is String`. Ada test khusus untuk ini
(`test/post_test.dart`: "null eksplisit dan tipe salah tidak melempar").

**(2) Guard request ganda ditambahkan, tidak ada di hasil AI.**
Versi AI hanya memanggil `fetchPostsPage` dari listener scroll. Karena listener
dipanggil puluhan kali per detik saat pengguna menggulir, halaman yang sama bisa
diminta berkali-kali dan data jadi dobel. Ditambahkan `isLoadingMore` +
`hasMore` sebagai penahan di dalam notifier. Dibuktikan dengan memanggil
`loadNextPage()` dua kali **tanpa await** dan memeriksa repository palsu hanya
menerima `[1, 2]`.

**(3) `FutureProvider` → `Notifier` dengan satu kelas state.**
`FutureProvider` tidak bisa menampung "10 item lama + sedang memuat halaman
berikutnya + halaman terakhir gagal" sekaligus. Diganti `PagedPostsState`
dengan field final, sehingga kombinasi mustahil tidak bisa dibentuk.

**(4) `retry` Riverpod 3 dimatikan.**
AI tidak menyebut ini. Riverpod 3 mencoba ulang provider yang gagal sampai 10
kali dengan backoff 200 ms → 6,4 s, jadi pesan error baru muncul setelah puluhan
detik dan test provider menggantung. Karena notifier di sini menangani error
sendiri lewat `try/catch`, retry otomatis itu tidak perlu.

**(5) State empty dipisah dari state error.**
Hasil AI menampilkan pesan error untuk `items.isEmpty`. Padahal "server balas
`[]`" adalah sukses tanpa data, bukan kegagalan — pengguna tidak perlu melihat
tombol "Coba lagi" dan kalimat soal internet. Sekarang ada flag `isEmpty`.
Widget test khusus membedakan keduanya.

### Keputusan teknis lain

**Base URL lewat `--dart-define`.** Dibutuhkan agar screenshot state
empty/error/loading bisa diambil (ketiganya mustahil dari JSONPlaceholder).
Alternatifnya mock HTTP di dalam aplikasi — jauh lebih rumit dan hanya jalan di
mode debug. Satu konstanta lebih sederhana dan berguna juga untuk ganti backend.

**Widget test ditambahkan meski hanya 2 test yang diwajibkan.** Klaim "empat
state tampil" hanya bisa dibuktikan kalau benar-benar diperiksa di widget.
Melakukannya menemukan satu hal: pengguna yang berhenti di dasar daftar memicu
halaman berikutnya sampai server kehabisan data (`[1, 2, 3]`, bukan `[1, 2]`) —
perilaku yang benar, dan asumsi awal saya yang salah.

---

## 5. Refleksi

### 5.1 Mengapa UI dilarang memanggil Dio langsung? Apa yang rusak jika dilanggar?

Karena Dio adalah detail implementasi pengiriman data, bukan bagian dari
tampilan. Kalau widget memanggil Dio langsung, lima hal rusak sekaligus:

1. **Tidak bisa diuji tanpa internet.** Sekarang seluruh test berjalan dari
   repository palsu; kalau Dio ada di dalam widget, test ikut butuh jaringan dan
   jadi lambat serta rapuh.
2. **URL tersebar.** `https://jsonplaceholder.typicode.com` akan muncul di
   banyak file. Mengganti backend berarti berburu string di seluruh project.
3. **Penanganan error terduplikasi.** Setiap widget harus tahu
   `DioExceptionType` dan menyusun pesan sendiri. Sekarang satu fungsi
   `friendlyErrorMessage` dipakai semua halaman, jadi pesan untuk kasus yang sama
   selalu identik.
4. **Perubahan sumber data merembet ke UI.** Menambah cache, retry, atau
   offline-first berarti menyentuh setiap widget yang memanggil API.
5. **State tidak konsisten.** Dua widget yang memanggil endpoint sama bisa
   punya hasil dan waktu muat berbeda. Lewat provider, satu sumber data dipakai
   bersama.

Buktinya ada di grep: `grep -rn "dio\|Dio" lib/pages lib/main.dart` hanya
menemukan **satu komentar dokumentasi**, bukan kode.

### 5.2 Kapan pagination client-side cukup, dan kapan harus pagination server?

**Client-side cukup bila** seluruh data kecil (muat di memori), jarang berubah,
dan tidak akan tumbuh. Contoh: 20 item pengaturan, daftar kategori, hasil
pencarian lokal. Saat itu satu request `GET /posts` lalu potong di Dart sudah
benar — menambah `_page`/`_limit` hanya menambah round-trip tanpa manfaat.

**Pagination server wajib bila** jumlah data tidak dibatasi atau besar.
Indikatornya:
- Total data jauh melebihi yang bisa ditampilkan (JSONPlaceholder: 100 post,
  tetapi API nyata bisa jutaan baris).
- Data sering bertambah, sehingga daftar yang di-cache cepat basi.
- Respons penuh sudah berat (mis. `GET /posts` dengan 10.000 baris × body panjang
  = megabyte terbuang untuk 10 baris pertama).
- Ada kebutuhan pengurutan/filter dari server.

Yang dipakai di project ini pagination server (`_page`/`_limit`), dan alasannya
terlihat di header respons JSONPlaceholder: `x-total-count: 100` dan
`Link: ...; rel="next"`. Artinya server memang punya kontrak pagination, dan
memanfaatkannya berarti payload per layar hanya 10 item — bukan 100.

Catatan praktis: `hasMore` di sini disimpulkan dari **panjang halaman lebih
kecil dari `limit`**, bukan dari nomor halaman. Cara itu bekerja walau jumlah
total tidak diketahui. API yang menyediakan `Link: rel="next"` atau
`x-total-count` sebaiknya memakai header itu langsung supaya tidak ada satu
request tambahan hanya untuk menemukan akhir data.

### 5.3 Bagaimana exception repository berubah menjadi `AsyncError` tanpa `try/catch` di setiap widget? Kapan `try/catch` eksplisit tetap dibutuhkan?

**Di `week4_api/` (AsyncNotifier)** rantainya begini:

1. `Dio.get` melempar `DioException` di dalam `PostRepository`.
2. Method `build()` pada `AsyncNotifier` **tidak** menangkapnya, jadi exception
   keluar dari `build()`.
3. Riverpod menangkapnya dan mengubah state provider dari `AsyncLoading` menjadi
   `AsyncError(error, stackTrace)`.
4. Widget hanya melihat `AsyncValue` dan memakai `.when(error: ...)`.

Tidak ada satu pun `try/catch` di widget, dan itu memang tujuannya: tanggung
jawab menangani kegagalan ada di runtime state management, bukan di tampilan.

Di project mini ini (`week4_api_tugas/`) saya justru memakai `Notifier` biasa
dengan `PagedPostsState` yang menyimpan `error` sebagai field. Alasannya: satu
`AsyncValue` hanya punya satu error, sedangkan di infinite scroll perlu
dibedakan error yang membuat layar kosong (halaman 1 gagal) dari error yang
muncul di bawah 10 item yang sudah tampil (halaman berikutnya gagal). Karena
state ditulis manual, `try/catch` di notifier memang wajib — tetapi tetap **satu
tempat saja**, dan widget tetap nol `try/catch`.

**`try/catch` eksplisit tetap dibutuhkan bila:**

- **Error ditangani sebagian, bukan diteruskan.** Mis. gagal memuat halaman
  berikutnya sementara data lama dipertahankan — seperti di project ini.
  `AsyncValue` tidak punya konsep "error sambil tetap ada data lama".
- **Ada aksi tambahan setelah gagal.** Menampilkan SnackBar, mencatat ke
  Crashlytics, atau menandai percobaan gagal supaya tidak mengulang tanpa batas.
- **Kegagalan boleh diabaikan.** Mis. gagal menyimpan preferensi non-kritis —
  aplikasi tetap jalan, cukup dicatat.
- **Batasannya beda.** Kalau kegagalan parsial dapat diterima: 4 dari 5 request
  berhasil → tampilkan 4, laporkan 1 gagal (`Future.wait(eagerError: false)`).
- **`build()` tidak boleh async.** Di `PagedPostsNotifier`, `build()` hanya
  menjadwalkan lewat `scheduleMicrotask`; pemuatan sesungguhnya jalan di method
  async, jadi `try/catch` harus ditulis sendiri.

Ringkasnya: biarkan state management meneruskan error bila kegagalan berarti
"layarnya tidak bisa ditampilkan". Tangkap sendiri bila kegagalan masih bisa
dijawab dengan tampilan parsial atau perlu efek samping.

### 5.4 Bagian mana dari hasil AI yang saya perbaiki, dan mengapa?

Lima perbaikan konkret (rincian di bagian 4): helper parsing `is`-check
menggantikan cast nullable, guard request ganda pada pagination, `FutureProvider`
diganti `Notifier` + kelas state, `retry` Riverpod 3 dimatikan, dan state empty
dipisahkan dari state error.

Dua bug terakhir yang ditemukan justru dari menjalankan sesuatu, bukan membaca
kode:

- **Panggilan ganda halaman 1.** Probe awal memanggil `loadFirstPage()` manual
  setelah membaca provider, dan repository mencatat `[1, 1, 2]`. Penyebabnya
  `build()` sudah menjadwalkan pemuatan lewat microtask. Perbaikan: test tidak
  memanggil manual, cukup memutar event loop. Pelajaran: saat `build()`
  melakukan efek samping, test harus tahu itu.
- **Spinner loading tidak terekam.** Chrome headless `--screenshot` memakai
  virtual time dan langsung memajukan waktu sampai halaman tenang, sehingga
  spinner sudah hilang saat difoto. Perbaikan: `tools/shot_cdp.py`, memotret pada
  detik tertentu lewat DevTools Protocol.

Dan satu asumsi saya yang salah, yang dikoreksi oleh test: menggulir ke dasar
daftar memuat halaman 2 **dan** 3 sampai server kehabisan data (`[1, 2, 3]`),
bukan berhenti di 2. Saya perbaiki ekspektasi test-nya, bukan aplikasinya —
perilaku aplikasi memang sudah benar.
