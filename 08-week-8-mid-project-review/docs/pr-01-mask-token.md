# PR: fix(core) — maskToken tidak lagi RangeError untuk token pendek

Cabang: `fix/mask-token-range` → `develop` · Berkas: 2 · +8 / −2

## Masalah

`maskToken` selalu memotong 12 karakter pertama:

```dart
if (token.length <= 12) return '${token.substring(0, 12)}…';
return '${token.substring(0, 12)}…';
```

Untuk token lebih pendek dari 12 karakter (mis. `'abc'`), `substring(0, 12)`
melempar `RangeError`. Dua cabang `if/else` menghasilkan string identik, jadi
bug ini tidak terlihat saat membaca diff. Reproduksi:

```bash
flutter test test/core_format_test.dart
# RangeError (end): Invalid value: Not in inclusive range 0..3: 12
#   package:campus_notify/core/format.dart 26:43  maskToken
```

Dampak nyata: token yang dipotong lebih pendek — mis. dari backend uji atau
token yang di-reset — membuat `HomePage._load()` melempar di dalam `setState`,
sehingga panel status perangkat gagal terisi.

## Solusi

```dart
const batas = 12;
final potong = token.length <= batas ? token : token.substring(0, batas);
return '$potong…';
```

Satu jalur keluar, panjang potong = `min(length, 12)`. Tidak ada dependensi
baru, tidak ada perubahan tanda tangan fungsi.

## Cara uji

1. `flutter analyze` → `No issues found!`
2. `flutter test` → `+11 All tests passed!` (9 test lama + 2 baru)
3. Manual: buka aplikasi, panel "Access token" menampilkan `mock-access-…`

## Komentar review (reviewer → penulis)

> **reviewer (request changes)** — `core/format.dart:26`
> Blocker: `substring(0, 12)` tanpa cek panjang melempar `RangeError` untuk
> token < 12 karakter. Reproduksi: `maskToken('abc')`. Tambahkan test yang
> menutup rentang ini sebelum memperbaiki kode, supaya terlihat merah dulu.

> **reviewer (saran)** — `core/format.dart:25-27`
> Cabang `if` dan `else` mengembalikan string yang sama persis. Selama keduanya
> kembar, bug di atas mustahil terlihat dari diff. Satukan jadi satu ekspresi.

> **reviewer (saran)** — `test/core_format_test.dart`
> Test lama hanya memakai token 37 karakter, jadi jalur < 12 karakter tidak
> pernah tersentuh. Tambahkan token 3 dan 12 karakter (batas tepat).

> **penulis (resolved)**
> Ketiganya ditindaklanjuti dalam satu commit: test ditulis lebih dulu dan
> dijalankan (merah, dengan stack trace di atas), lalu `maskToken` disederhanakan
> menjadi satu jalur. `flutter test` hijau 11 test, `flutter analyze` bersih.

## Status

Approve (setelah siklus request changes → perbaikan → approve), lalu merge ke
`develop` secara squash. Issue #1 tertutup otomatis.