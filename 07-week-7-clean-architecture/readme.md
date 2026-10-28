# Week 7 : Clean Architecture

Praktikum JTI Polinema. Project: `campus_notify` (lanjutan Minggu 6, bukan
project baru). Fokus: memecah satu project yang sudah berjalan menjadi
feature-first Clean Architecture, lalu membuktikan arah dependensinya dengan
grep dan test.

## 1. Struktur folder

```
07-week-7-clean-architecture/          <- root minggu
├── README.md                          <- laporan ringkas
├── docs/
│   ├── ai-challenge.md                <- prompt, usulan AI, keputusan final
│   └── verifikasi-grep.txt            <- keluaran grep apa adanya
├── screenshots/                       <- before-* dan after-* dari HP fisik
├── lib/  test/                        <- salinan kode yang dibahas
├── campus_notify/                     <- project Flutter
└── #07 _ Clean Architecture.html      <- modul
```

## 2. Struktur `lib/` sesudah refactor

```
lib/
├── main.dart
├── router.dart
├── routes.dart
├── core/
│   ├── failures.dart
│   └── format.dart
├── features/
│   ├── auth/
│   │   ├── domain/entities/session.dart
│   │   ├── domain/repositories/auth_repository.dart
│   │   ├── data/datasources/{token_store,api_client,api_errors}.dart
│   │   ├── data/repositories/auth_repository_impl.dart
│   │   ├── presentation/providers/auth_providers.dart
│   │   └── presentation/pages/login_page.dart
│   └── announcements/
│       ├── domain/entities/announcement.dart
│       ├── domain/repositories/announcement_repository.dart
│       ├── domain/usecases/get_announcements.dart
│       ├── data/models/announcement_model.dart
│       ├── data/datasources/announcement_local_source.dart
│       ├── data/repositories/announcement_repository_impl.dart
│       ├── presentation/providers/announcement_providers.dart
│       └── presentation/pages/{home_page,announcement_page}.dart
└── messaging/push_service.dart        <- infrastruktur FCM (tanpa aturan bisnis)
```

Arah dependensi: `presentation -> domain <- data`. `domain` dan `core` tidak
mengimpor Flutter, Dio, SQLite, atau Firebase.

## 3. Audit sebelum refactor (Minggu 6)

| Berkas lama | Layer saat itu | Masalah |
|---|---|---|
| `pages/home_page.dart` | presentation | Mengimpor `data/token_store.dart` dan `data/api_errors.dart`; memakai `TokenStore.mask` langsung |
| `pages/login_page.dart` | presentation | Mengimpor `data/api_errors.dart` untuk menerjemahkan error |
| `providers/auth_provider.dart` | presentation | `AuthRepository()` diinstansiasi di dalam provider |
| `data/auth_repository.dart` | data | Entity `AuthSession`, kontrak, dan implementasi menumpuk di satu berkas |
| `messaging/deeplink.dart` | infrastruktur | Fungsi murni tetapi tersimpan di folder messaging, sulit diuji bersama helper lain |

Grep pembanding pada project lama:

```
$ rg -n "Repository\(|Dio\(BaseOptions" lib/pages lib/providers
lib/providers/auth_provider.dart:10:  (ref) => AuthRepository(),
$ rg -n "import '\.\./data" lib/pages
lib/pages/login_page.dart:4:import '../data/api_errors.dart';
lib/pages/home_page.dart:5:import '../data/token_store.dart';
```

## 4. Verifikasi sesudah refactor

```
$ rg -n "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/*/presentation
(nol hasil)
$ rg -n "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/*/domain lib/core
(nol hasil)
$ flutter analyze
No issues found!
$ flutter test
00:00 +10: All tests passed!
```

Keluaran lengkap: `docs/verifikasi-grep.txt`.

## 5. Bukti device

Sepuluh berkas di `screenshots/` berasal dari Infinix (1080x2436) lewat
`adb exec-out screencap`. Pasangan `before-NN` (APK Minggu 6) dan `after-NN`
(APK hasil refactor) memperlihatkan alur yang sama: login, beranda, detail
pengumuman, simulasi 401, dan logout.

## 6. Menjalankan

```bash
cd campus_notify
flutter pub get
flutter test
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## 7. Stack

Flutter, Riverpod 3 (`Provider`, `AsyncNotifierProvider`, `FutureProvider`),
GoRouter, Dio dengan interceptor refresh 401, `flutter_secure_storage`,
Firebase Core + Cloud Messaging, `flutter_local_notifications`.

## 8. Membangun laporan

Isi jawaban ada di `isi_laporan7.py`; `gen_wc.py` mengubahnya menjadi
`job-laporan7.json` lalu WordCraft yang menyusun `.docx` dan `.pdf`
(author `Hermes via MCP`, track changes aktif), sesuai `C:/Kuliah/ATURAN-LAPORAN.md`
paragraf 10.

```bash
"C:/Program Files/Python313/python.exe" gen_wc.py
"C:/Users/adamb/wordcraft/app/wordcraft-cli.exe" run --script job-laporan7.json
"C:/Program Files/Python313/python.exe" C:/Kuliah/cek_laporan.py \
  "Laporan Jobsheet Minggu 7 - Adam Bahy Maulana.docx"
```

Screenshot `before-*` berasal dari APK minggu 6, `after-*` dari APK hasil
refactor; keduanya diambil dari perangkat Infinix 1080x2436 lewat `adb`.
