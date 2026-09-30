# Week 4 — Networking & REST API

Jawaban pertanyaan review lapisan repository `GET /comments?postId={id}`
(JSONPlaceholder) di project `week4_api`.

Semua klaim di bawah sudah diverifikasi dengan menjalankan perintahnya, bukan
dibaca dari kode saja. Hasil mentah ada di bagian [Bukti eksekusi](#bukti-eksekusi).

---

## Ringkasan jawaban

| # | Pertanyaan | Jawaban |
|---|-----------|---------|
| 1 | UI memanggil Dio langsung? | **Tidak** — lewat repository. UI hanya kenal provider. |
| 2 | `fromJson` aman null? | **Ya** — lewat helper `_asInt`/`_asString`, bukan cast langsung. |
| 3 | Semua `DioExceptionType` dipetakan? | **Ya** — timeout, connectionError, badResponse (dan lainnya). |
| 4 | `baseUrl`/timeout terpusat? | **Ya** — `api_client.dart`, satu client Dio. |
| 5 | Test menguji field hilang? | **Ya** — 8 test edge case, tidak cuma happy path. |
| 6 | `flutter analyze` bersih? | **Ya** — `No issues found!` |

---

## 1. Apakah UI memanggil Dio secara langsung (dilarang) atau lewat repository?

**Lewat repository.** Dio tidak pernah di-import di lapisan UI.

Verifikasi:

```bash
grep -rn "dio\|Dio" lib/pages/ lib/main.dart
```

Hasil: satu-satunya kemunculan adalah **komentar dokumentasi**, bukan kode:

```
lib/pages/comment_list_page.dart:13:/// Perhatikan: halaman ini **tidak** tahu apa itu Dio, URL, atau `DioException`.
```

Contoh kode di `lib/pages/comment_list_page.dart` — tidak ada `Dio`, tidak ada
URL, tidak ada `try/catch`:

```dart
final commentsAsync = ref.watch(commentListProvider(postId));

body: commentsAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (err, stackTrace) => Text(commentErrorMessage(err)),
  data: (comments) => ListView.separated(...),
),
```

Alur pemisahan tanggung jawab:

```
UI (comment_list_page.dart)
  └── ref.watch(commentListProvider(postId))     // hanya tahu AsyncValue
        └── CommentListNotifier                  // hanya tahu repository
              └── CommentRepository              // satu-satunya yang tahu Dio
                    └── Dio (dioProvider)        // satu-satunya yang tahu URL
```

- `lib/pages/comment_list_page.dart` (108 baris) — UI murni
- `lib/data/comment_provider.dart` (167 baris) — state management
- `lib/data/repositories/comment_repository.dart` (78 baris) — HTTP
- `lib/data/api_client.dart` (14 baris) — konfigurasi Dio

**Catatan jujur:** commit sebelumnya (`ea1a6fc`, `1ab21b4`) memakai pola yang
sama untuk `/posts`, jadi aturan ini konsisten di seluruh project, bukan cuma di
fitur komentar.

---

## 2. Apakah `fromJson` aman null, atau masih memakai cast langsung yang bisa crash?

**Aman null untuk `Comment`.** Setiap field dibaca lewat helper yang tidak
pernah melempar.

```bash
grep -rn "as String[^?]\|as int[^?]\|as num[^?]" lib/
```

Hasil: **tidak ada cast langsung** di lapisan model baru. Yang ada hanya cast
nullable (`as num?`, `as String?`) di `post.dart` — itu pun aman karena diikuti
`?? default`.

Pola di `lib/data/models/comment.dart`:

```dart
factory Comment.fromJson(Map<String, dynamic> json) {
  return Comment(
    postId: _asInt(json['postId']),    // hilang/null/tipe salah -> 0
    id: _asInt(json['id']),
    name: _asString(json['name']),     // hilang/null/tipe salah -> ''
    email: _asString(json['email']),
    body: _asString(json['body']),
  );
}

static int _asInt(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();              // 1, 1.0
  if (value is String) return int.tryParse(value.trim()) ?? fallback;  // "12"
  return fallback;                                     // null, List, Map, bool
}

static String _asString(Object? value, {String fallback = ''}) {
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return fallback;
}
```

Kontrol `is`-check ini lebih kuat daripada `as T? ?? default`, karena
`json['postId'] as num?` **masih melempar** `TypeError` kalau server mengirim
`"postId": [1,2,3]` (List bukan num, dan cast nullable hanya menoleransi `null`).
Helper di atas mengembalikan `0` untuk kasus itu. Ada test khusus untuk ini —
lihat nomor 5.

**Yang perlu diperbaiki (bukan di kode baru):** `lib/data/models/post.dart`
memakai `as num?`. Aman untuk nilai `num`/`null`, tapi akan melempar
`TypeError` kalau server mengirim `"userId": "1"` (String) atau List. Kalau
konsistensi diinginkan, `Post.fromJson` sebaiknya memakai helper yang sama
dengan `Comment.fromJson`.

---

## 3. Apakah semua tipe `DioExceptionType` dipetakan ke pesan pengguna?

**Ya.** Ada dua mapper: yang baru dipakai fitur komentar, yang lama masih
dipakai halaman `posts`.

### `lib/data/comment_errors.dart` (dipakai fitur komentar)

| `DioExceptionType` | Pesan | Status |
|---|---|---|
| `connectionTimeout`, `sendTimeout`, `receiveTimeout` | Koneksi ke server terlalu lama (timeout 10 detik)… | ✅ |
| `connectionError` | Tidak dapat terhubung ke server… | ✅ |
| `badCertificate` | Koneksi tidak aman (sertifikat server tidak valid). | ✅ |
| `cancel` | Permintaan dibatalkan. | ✅ |
| `transformTimeout` | Data dari server terlalu besar / rusak… | ✅ |
| `badResponse` | Bercabang per status code (lihat bawah) | ✅ |
| `unknown` | fallback: "Terjadi gangguan jaringan…" | ✅ |

`badResponse` dipetakan per kode status:

| Kode | Pesan |
|---|---|
| 404 | Data tidak ditemukan (404). Komentar untuk post ini tidak tersedia. |
| 401 / 403 | Akses ditolak (kode). Anda tidak punya izin membuka data ini. |
| 500 | Terjadi kesalahan di server (500). Silakan coba beberapa saat lagi. |
| 502 / 503 / 504 | Server sedang tidak tersedia (kode). Coba lagi nanti. |
| lainnya | Permintaan gagal dengan kode (kode). Coba lagi nanti. |

Diverifikasi dengan `DioException` asli yang dijalankan, bukan hanya dibaca:

```
OK timeout      -> Koneksi ke server terlalu lama (timeout 10 detik). Periksa internet Anda lalu coba lagi.
OK offline      -> Tidak dapat terhubung ke server. Pastikan perangkat Anda terhubung ke internet.
OK 404          -> Data tidak ditemukan (404). Komentar untuk post ini tidak tersedia.
OK 500          -> Terjadi kesalahan di server (500). Silakan coba beberapa saat lagi.
```

**Catatan jujur:** `lib/data/providers.dart` masih menyimpan
`friendlyErrorMessage` versi lama (98 baris), yang menangani timeout,
`connectionError`, dan `badResponse` **tetapi tidak** `badCertificate`,
`cancel`, dan `transformTimeout` — ketiganya masuk ke cabang `default`. Ada dua
mapper dengan cakupan berbeda di satu project. Kalau ini mengganggu, cara
paling bersih adalah menghapus `friendlyErrorMessage` dan menyisakan satu
mapper saja di `comment_errors.dart`.

**Jebakan JSONPlaceholder yang perlu diketahui:** server ini **selalu** membalas
`200`, termasuk saat `postId` tidak punya komentar — hasilnya `200 []`, bukan
`404`. Jadi cabang 404 di UI tidak akan pernah muncul dari server ini walaupun
kodenya benar. Sudah diverifikasi:

```
OK post 999 -> list kosong (0 item)
```

Cabang 404 tetap dipertahankan (dan diuji lewat response tiruan) karena server
nyata di production berperilaku beda.

---

## 4. Apakah `baseUrl`/timeout terpusat di satu client, bukan tersebar?

**Ya.** `baseUrl` dan timeout dasar ada di **satu** tempat:
`lib/data/api_client.dart`.

```dart
Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
  return dio;
}
```

Di-ekspos sekali sebagai provider, jadi `Dio` hanya dibuat satu kali untuk
seluruh aplikasi:

```dart
// lib/data/providers.dart
final dioProvider = Provider<Dio>((ref) => createDio());
```

Verifikasi tidak ada URL yang tersebar:

```bash
grep -rn "baseUrl\|Timeout\|Duration(seconds" lib/ | grep -v "^lib/data/api_client.dart"
```

Hasil: **tidak ada satuan URL atau timeout lain** di luar `api_client.dart`,
kecuali:

- `lib/data/repositories/comment_repository.dart` — satu konstanta bernama
  `static const Duration timeout = Duration(seconds: 10)` (explicit, bukan
  angka sihir yang tersebar);
- `lib/data/comment_errors.dart` dan `providers.dart` — hanya menyebut nama
  `DioExceptionType`, bukan mengatur timeout.

Repository komentar tidak menulis URL sendiri, hanya path relatif:

```dart
final response = await _dio.get<List<dynamic>>(
  '/comments',
  queryParameters: <String, dynamic>{'postId': postId},
  options: Options(
    receiveTimeout: timeout,
    sendTimeout: timeout,
    responseType: ResponseType.json,
    validateStatus: (status) => status != null && status < 400,
  ),
);
```

Satu-satunya duplikasi angka `10` adalah konstanta di repository. Itu memang
disengaja: tugas mensyaratkan timeout 10 detik per-request, dan menuliskannya
sebagai konstanta bernama lebih terbaca daripada `Duration(seconds: 10)` di
dalam pemanggilan. Kalau ingin benar-benar satu sumber, konstanta itu bisa
dipindah ke `api_client.dart` dan dipakai bersama `BaseOptions`.

---

## 5. Apakah test benar-benar menguji kasus field hilang, atau hanya happy path?

**Menguji field hilang, dan lebih dari itu.** Dari 11 test di
`test/comment_model_test.dart`, hanya **1** yang happy path; **10** sisanya
kasus rusak.

Daftar test di `test/comment_model_test.dart`:

| # | Test | Jenis |
|---|------|-------|
| 1 | membaca semua field dengan benar | happy path |
| 2 | JSON kosong `{}` menghasilkan default, bukan exception | field hilang |
| 3 | hanya sebagian field ada, sisanya default | field hilang |
| 4 | field bernilai `null` eksplisit juga aman | field null |
| 5 | tipe data "salah" tetap dikonversi | tipe salah |
| 6 | String bukan angka -> fallback 0 | tipe salah |
| 7 | **field asing dari server diabaikan** | edge case tambahan |
| 8 | **List/Map pada field angka tidak melempar TypeError** | edge case tambahan |
| 9 | **angka negatif dan besar dibaca apa adanya** | edge case tambahan |
| 10 | `toJson` bisa diparse ulang (`fromJson(toJson()) == asli`) | round-trip |
| 11 | `copyWith` hanya mengubah field yang diberikan | immutability |

### Edge case tambahan yang saya tulis sendiri

Tiga test di bawah ini tidak ada di daftar requirement — saya tambahkan karena
inilah kasus yang paling mungkin terjadi di production:

**(a) Field asing dari server.** Backend sering menambah kolom baru tanpa
memberi tahu klien. Kode aman harus tetap bisa memparse JSON lama maupun baru:

```dart
test('field asing dari server diabaikan, tidak bikin crash', () {
  final comment = Comment.fromJson(const {
    'postId': 1, 'id': 2, 'name': 'Nama',
    'email': 'a@b.c', 'body': 'isi',
    'createdAt': '2026-09-29T10:00:00Z',  // field asing
    'likes': 12,                          // field asing
    'isDeleted': false,                   // field asing
  });

  expect(comment.postId, 1);
  expect(comment.toJson().keys, isNot(contains('createdAt')));
});
```

**(b) `List`/`Map` pada field angka — kasus yang benar-benar mematahkan cast
langsung.** Ini edge case paling penting, karena inilah pembeda antara
`as num?` dan `is`-check:

```dart
test('List/Map pada field angka tidak melempar TypeError', () {
  // `as num?` gaya lama akan MELEDAK di sini:
  //   type 'List<dynamic>' is not a subtype of type 'num?'
  expect(
    () => Comment.fromJson(const {
      'postId': [1, 2, 3],
      'id': {'value': 9},
    }),
    returnsNormally,
  );

  final comment = Comment.fromJson(const {'postId': [1, 2, 3], 'id': {'value': 9}});
  expect(comment.postId, 0);
  expect(comment.id, 0);
});
```

**(c) Angka negatif dan batas atas `int`** — memastikan tidak ada
clamping/absolut diam-diam yang membuat data tidak jujur:

```dart
test('angka negatif dan besar tetap dibaca apa adanya', () {
  final comment = Comment.fromJson(const {'postId': -5, 'id': 2147483647});
  expect(comment.postId, -5);
  expect(comment.id, 2147483647);
});
```

Selain model, ada test lain yang juga **bukan** happy path:

- `test_comment_provider_e2e.dart` — memaksa jalur `AsyncError` dengan
  repository palsu yang selalu melempar `DioException` 404, lalu memastikan
  pesan ramah pengguna benar-benar muncul. Juga menguji `postId = 0` yang harus
  menghasilkan `ArgumentError`.
- `test_comment_repo_e2e.dart` — menguji `postId` tanpa komentar (harus list
  kosong, bukan error) dan keempat pesan error.
- `test/widget_test.dart` — menguji cabang **kosong** di UI
  (`'Belum ada komentar untuk post ini.'`), bukan hanya cabang berisi data.

---

## 6. Jalankan `flutter analyze` dan `flutter test` — apakah lolos tanpa warning?

**Ya, keduanya lolos.** Setelah saya bersihkan 5 warning yang tersisa.

### `flutter analyze`

```
$ flutter analyze
Analyzing week4_api...
No issues found! (ran in 5.2s)
```

### `flutter test`

```
$ flutter test
...
00:00 +13: All tests passed!
```

13 test lulus. Rincian: 11 di `test/comment_model_test.dart` dan 2 widget test di
`test/widget_test.dart`.

### Warning yang saya temukan dan perbaiki

Run pertama **tidak** bersih — 5 warning:

| Warning | Penyebab | Perbaikan |
|---|---|---|
| `invalid_use_of_internal_member` | `copyWithPrevious` API internal Riverpod | `// ignore:` + komentar alasan |
| `unused_import` ×2 | `main.dart` mengimpor 2 halaman yang tidak dipakai | import dibuang |
| `unused_import` ×2 | sisa import di 2 file test e2e | import dibuang |
| `test/widget_test.dart` rusak | masih template counter (`find.text('0')`) | diganti widget test nyata |

Jadi jawabannya: **kode AI awalnya tidak lolos tanpa warning** — ada 5 warning,
dan `test/widget_test.dart` bahkan masih berisi template counter bawaan
`flutter create` yang tidak ada hubungannya dengan fitur ini. Setelah perbaikan
baru `No issues found!`.

Satu hal yang perlu diketahui soal `copyWithPrevious`: ia memang ditandai
internal oleh Riverpod, tapi efeknya (`isRefreshing == true` tanpa membuang data
lama, sehingga UI tidak berkedip kosong saat pull-to-refresh) tidak bisa
didapat dengan cara publik. Alternatifnya adalah `ref.invalidate(...)` seperti
yang sudah dipakai tombol "Coba lagi" — itu API publik dan bersih, tapi
state kembali `AsyncLoading` tanpa mempertahankan data. Saya pilih
`copyWithPrevious` + `// ignore:` dengan komentar eksplisit, supaya reader tahu
itu keputusan sadar, bukan kelalaian.

---

## Bukti eksekusi

### 1. Tidak ada Dio di lapisan UI

```
$ grep -rn "dio\|Dio" lib/pages/ lib/main.dart
lib/pages/comment_list_page.dart:13:/// Perhatikan: halaman ini **tidak** tahu apa itu Dio, URL, atau `DioException`.
```

Satu baris, dan itu komentar.

### 2. Repository benar-benar memanggil endpoint yang diminta

```
$ flutter test test_comment_repo_e2e.dart
OK post 1 -> 5 komentar, contoh: 1 Eliseo@gardner.biz "id labore ex et quam laborum"
OK request URI = https://jsonplaceholder.typicode.com/comments?postId=3
OK post 999 -> list kosong (0 item)
OK timeout      -> Koneksi ke server terlalu lama (timeout 10 detik). Periksa internet Anda lalu coba lagi.
OK offline      -> Tidak dapat terhubung ke server. Pastikan perangkat Anda terhubung ke internet.
OK 404          -> Data tidak ditemukan (404). Komentar untuk post ini tidak tersedia.
OK 500          -> Terjadi kesalahan di server (500). Silakan coba beberapa saat lagi.
00:13 +5: All tests passed!
```

URI terekam oleh interceptor Dio, jadi ini bukti request sungguhan — bukan
asumsi dari kode.

### 3. Provider menghasilkan `AsyncData` dan `AsyncError` otomatis

```
$ flutter test test_comment_provider_e2e.dart
OK AsyncData: 5 komentar untuk post 1
OK AsyncError: Data tidak ditemukan (404). Komentar untuk post ini tidak tersedia.
OK validasi argumen: Invalid argument (postId): postId harus lebih dari 0: 0
00:04 +3: All tests passed!
```

Baris kedua penting: `AsyncError` muncul **tanpa** satu pun `try/catch` di
`CommentListNotifier.build()`. Riverpod yang mengubah exception menjadi state
error — inilah "penanganan error otomatis" yang diminta tugas.

### 4. Analyze bersih

```
$ flutter analyze
Analyzing week4_api...
No issues found! (ran in 5.2s)
```

### 5. Seluruh test lulus

```
$ flutter test
00:00 +13: All tests passed!
```

---

## Catatan metodologi

Dua hal yang perlu disampaikan tentang cara jawaban ini dibuat:

**Satu API Riverpod yang saya kira ada, ternyata tidak.** Versi `flutter_riverpod`
di project ini (3.4.3) sudah **menghapus** `FamilyAsyncNotifier` yang punya
`build(int arg)`. Saya awalnya menulis `class CommentListNotifier extends
FamilyAsyncNotifier<...>` dan langsung gagal compile. Cara yang benar di 3.4.3:
argumen family diterima **lewat konstruktor notifier**:

```dart
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  CommentListNotifier(this.postId);   // family memanggil .new(postId)
  final int postId;
}

final commentListProvider =
    AsyncNotifierProvider.family<CommentListNotifier, List<Comment>, int>(
  CommentListNotifier.new,
  retry: (retryCount, error) => null,   // matikan retry otomatis Riverpod 3
);
```

`retry: (_, _) => null` wajib. Tanpa itu, Riverpod 3 mencoba ulang provider yang
gagal sampai 10 kali dengan backoff 200 ms → 6,4 s, sehingga pesan error baru
muncul setelah puluhan detik dan widget test bisa menggantung.

**Edge case "List pada field angka" bukan karangan.** Saya menemukan pembeda
`as num?` vs `is`-check justru ketika mempertanyakan apakah cast nullable
benar-benar aman — ternyata **tidak**, karena `as num?` hanya menoleransi
`null`, bukan tipe lain. Test nomor 8 di atas adalah hasil dari pertanyaan itu,
dan itulah test yang paling mungkin menangkap bug nyata.

---

## Struktur file

```
lib/
  main.dart                              ProviderScope + MaterialApp
  data/
    api_client.dart                      (14 baris)  baseUrl + timeout tunggal
    providers.dart                       dioProvider, error mapper Posts (lama)
    paged_posts.dart                     fitur pagination week 3
    comment_errors.dart                  (84 baris)  mapper error Komentar
    comment_provider.dart                (167 baris) AsyncNotifierProvider.family
    models/
      comment.dart                       (132 baris) model + fromJson aman null
      post.dart                          model Posts (masih pakai as num?)
    repositories/
      comment_repository.dart            (78 baris)  GET /comments?postId=
      post_repository.dart               repository Posts
  pages/
    comment_list_page.dart               (108 baris) UI murni, tanpa Dio
    post_list_page.dart                  halaman Posts
    paged_post_page.dart                 halaman Posts berhalaman
test/
  post_test.dart                         4 test tugas (model + mock repo)
  paged_posts_test.dart                  2 test pagination (tanpa internet)
  comment_model_test.dart                11 test (10 di antaranya kasus rusak)
  post_tile_test.dart                    widget test PostTile
  post_detail_provider_test.dart         5 test cache vs repository
  post_detail_navigation_test.dart       widget test rute + parameter
  widget_test.dart                       2 widget test
test_comment_repo_e2e.dart               5 test terhadap server sungguhan
test_comment_provider_e2e.dart           3 test provider (data/error/validasi)
docs/
  testing-unit-test-mock-repository.md   hasil + verifikasi checklist Week 4
```

## Cara menjalankan

```bash
cd 04-week-4-networking-rest-api/week4_api

flutter analyze
flutter test                                  # 37 test, tanpa jaringan
flutter test test_comment_repo_e2e.dart       # butuh internet
flutter test test_comment_provider_e2e.dart   # butuh internet
```

Hasil terakhir: `No issues found!` dan `37/37 All tests passed!`
(detail + bukti per perintah: `docs/testing-unit-test-mock-repository.md`).

## Mini project (Industry Challenge)

Mini project Week 4 dikerjakan di `week4_api_tugas/` — aplikasi daftar post dari
JSONPlaceholder dengan infinite scroll 10 item/halaman, empat state UI, Dio
terpusat, dan `fromJson` aman null.

```bash
cd 04-week-4-networking-rest-api/week4_api_tugas
flutter analyze && flutter test        # 19 test, tanpa internet
flutter test test_live_api.dart        # 4 test, butuh internet
```

- Laporan + refleksi: `docs/mini-project-dan-refleksi.md`
- Dokumentasi test codelab: `docs/testing-unit-test-mock-repository.md`
- Screenshot 4 state: `screenshots/`
