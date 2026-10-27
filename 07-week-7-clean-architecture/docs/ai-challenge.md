# AI Challenge : Reorganisasi `campus_notify` ke Clean Architecture

## 1. Prompt yang dipakai

```
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, messaging},
repository tercampur dengan implementasi, widget memanggil Dio langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

## 2. Usulan awal AI

| Usulan | Isi |
|---|---|
| Struktur | `lib/features/{auth,announcements}/{domain,data,presentation}` + `lib/core/{failures,format}.dart` |
| Pemetaan file | `data/token_store.dart` → `features/auth/data/datasources/`; `data/api_client.dart` → `features/auth/data/datasources/`; `data/auth_repository.dart` dipecah menjadi entity `Session` (domain), interface (domain), impl (data); `data/api_errors.dart` → pemetaan DioException ke `Failure` di data; `pages/*` → `features/*/presentation/pages/`; `providers/auth_provider.dart` → `features/auth/presentation/providers/`; `messaging/deeplink.dart` dilebur ke `core/format.dart` |
| Use case | `GetAnnouncements` wajib; `AddAnnouncement`, `DeleteAnnouncement`, `LoginUseCase`, `LogoutUseCase`, `RefreshTokenUseCase` diusulkan untuk "kelengkapan layer" |
| Kontrak | ganti record dengan `Either<Failure, T>` memakai `fpdart`, satu `AppRepository` besar untuk auth + announcements + FCM |
| DI | `get_it` + `injectable` (code generation) di samping Riverpod |

## 3. Keputusan final dan alasan teknis

| Butir | Keputusan | Alasan |
|---|---|---|
| Struktur feature-first 2 fitur + `core` | diterima | Satu fitur bisa dibaca dan dihapus tanpa menyentuh fitur lain. |
| `Session`, `Announcement` sebagai entity tanpa mapping | diterima | Entity tidak boleh tahu bentuk JSON/SQLite (`toJson` hanya di model). |
| Interface di domain, impl di data | diterima | Domain butuh kontrak; implementasi butuh Dio dan secure storage. Bila dibalik, domain ikut bergantung pada Flutter sehingga use case tidak bisa diuji tanpa device. |
| Use case untuk login, logout, refresh, tambah, hapus pengumuman | **ditolak** | Operasi satu baris yang hanya meneruskan panggilan. Satu use case saja (`GetAnnouncements`) dipertahankan karena operasi itu yang akan tumbuh (urutan, filter, cache). Use case baru dibuat ketika suatu operasi menggabungkan dua sumber data atau memuat aturan bisnis. |
| `fpdart` / `Either` | **ditolak** | Record `({T? data, Failure? failure})` sudah ada di SDK Dart, tanpa dependensi baru. Pola kontraknya sama. |
| `get_it` + `injectable` | **ditolak** | Riverpod sudah menjadi runtime state aplikasi; dua keranjang DI membuat siklus hidup objek tidak jelas. Wiring cukup lewat `Provider`. |
| Satu `AppRepository` besar | **ditolak** | Melanggar Interface Segregation: fitur pengumuman ikut bergantung pada token auth. Dipakai dua interface kecil per fitur. |
| `messaging/push_service.dart` dijadikan fitur penuh (domain + use case) | **ditolak** | Isinya hanya pemanggilan SDK Firebase tanpa aturan bisnis; membungkusnya menjadi use case menambah tiga lapisan tanpa nilai uji. Tetap sebagai infrastruktur `lib/messaging/`, sedangkan parsing rute (`routeFromMessage`) dipindah ke `core/format.dart` supaya murni dan teruji. |
| `TokenStore` diakses langsung dari halaman | **ditolak** | Halaman hanya butuh nilai token untuk ditampilkan; akses diberikan lewat `AuthRepository.accessToken()` sehingga presentation tidak menyentuh secure storage. |
| Formatting tanggal di widget | **ditolak** | Dipindah ke `core/format.dart` (`formatTanggal`, `maskToken`, `routeFromMessage`, `messageOf`) agar bisa diuji tanpa widget. |

## 4. Perbandingan jumlah berkas

| Lapisan | Sebelum | Sesudah |
|---|---|---|
| Titik masuk + rute | 3 (`main.dart`, `router.dart`, `routes.dart`) | 3 |
| Data | 4 | 7 (2 fitur) |
| Domain | 0 | 5 |
| Presentation | 5 (`pages/`, `providers/`) | 6 |
| Infrastruktur | 2 (`messaging/`) | 1 (`messaging/push_service.dart`) |
| Inti lintas fitur | 0 | 2 (`core/failures.dart`, `core/format.dart`) |

## 5. Verifikasi

Hasil tiga pemeriksaan grep dan `flutter analyze` tercatat di
`docs/verifikasi-grep.txt`. Ringkasnya: presentation nol hasil untuk akses
jaringan/penyimpanan langsung, domain dan `core` nol hasil untuk import Flutter,
Dio, SQLite, dan Firebase, serta tidak ada `RepositoryImpl` yang dibuat di dalam
halaman.