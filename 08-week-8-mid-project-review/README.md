# Minggu 8 — Mid Project Review & Code Review

Status paruh semester proyek **Campus Notify** (lanjutan Minggu 5–7, bukan proyek
baru). Folder ini berisi penilaian diri, disiplin kolaborasi, dan bukti mesin
hijau — bukan fitur baru.

## Status paruh semester

| Aspek | Keadaan |
|-------|---------|
| Arsitektur | feature-first Clean Architecture: `presentation -> domain <- data` |
| Domain steril | tidak mengimpor Flutter, Dio, sqflite, Firebase (`docs/verifikasi-grep.txt`) |
| `flutter analyze` | `No issues found!` |
| `flutter test` | 14 test hijau (3 berkas) |
| `dart format` | 0 berkas berubah |
| CI | `.github/workflows/ci.yml` — format + analyze + test pada setiap PR |
| Aplikasi | berjalan di Infinix X6851 (Android 14, 1080×2436), tampilan sama dengan akhir Minggu 7 |

## Peta issue dan PR

| Item | Isi | Status |
|------|-----|--------|
| Issue #1 | `maskToken` melempar `RangeError` untuk token < 12 karakter | ditutup oleh PR `fix/mask-token-range` |
| PR `fix/mask-token-range` | perbaikan + 2 test baru | 2 berkas, +8/−2 |
| PR `fix/announcement-loading-state` | deep link tidak lagi mengklaim "belum tersedia" saat loading | 2 berkas, +95/−30 |
| PR `chore/ci-workflow` | workflow `verify` untuk PR | 1 berkas, +20/−0 |

Setiap PR berisi: masalah, solusi, cara uji, dan screenshot (template di
`docs/pr-template.md`). Review dilakukan sendiri dengan dua peran terpisah —
penulis dan reviewer — karena tidak ada rekan tim; hasil review, komentar, dan
penyelesaiannya dicatat di `docs/pr-01-mask-token.md` dan
`docs/pr-02-announcement-loading.md`.

## Fitur utama (warisan Minggu 5–7)

1. Login tiruan dengan penyimpanan token aman dan refresh otomatis saat 401.
2. Daftar pengumuman kampus dari satu `FutureProvider`.
3. Deep link `campusnotify://pengumuman/:id` dan rute `/pengumuman/:id`.
4. Notifikasi FCM: izin, token, topik `pengumuman-kampus`, pesan foreground.
5. Panel status perangkat yang selalu memotong token (tidak pernah penuh).

## Stack teknologi

Flutter 3.47.2 · Dart 3.11 · Riverpod 3.4 · GoRouter 16 · Dio 5 ·
flutter_secure_storage · firebase_core + firebase_messaging ·
flutter_local_notifications · flutter_test

## Cara menjalankan

```bash
cd campus_notify
flutter pub get
flutter analyze          # harus: No issues found!
flutter test             # harus: All tests passed!
flutter run -d <device>  # Android; google-services.json sudah ada
```

Bangun APK: `flutter build apk --debug`, lalu
`adb install -r build/app/outputs/flutter-apk/app-debug.apk`.

## Hasil yang dicapai

- Dua bug nyata ditemukan lewat review dan diperbaiki dengan bukti test merah →
  hijau, bukan lewat klaim: `RangeError` pada token pendek, dan teks
  "belum tersedia" saat data masih dimuat.
- Tiga PR kecil (< 300 baris), masing-masing bisa direview di bawah 15 menit.
- Satu temuan AI ditolak dengan bukti test, satu ditunda dengan alasan lingkup
  (`docs/ai-review-vs-keputusan.md`).
- CI aktif: PR yang meninggalkan `flutter analyze` kotor atau test merah akan
  ditolak mesin sebelum dibaca manusia.

## Struktur folder

```
08-week-8-mid-project-review/
├── campus_notify/        proyek Flutter (lanjutan Minggu 7)
├── docs/                 review checklist, audit commit, AI vs keputusan, bukti mesin
├── screenshots/          bukti aplikasi berjalan di perangkat
└── README.md
```

Laporan jobsheet: `Laporan Jobsheet Minggu 8 - Adam Bahy Maulana.docx` (+ `.pdf`),
dibangun lewat WordCraft (`gen_wc8.py` → `job-laporan8.json`).