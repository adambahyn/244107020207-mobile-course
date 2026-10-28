# Review AI vs keputusan akhir

Semua temuan di bawah diusulkan oleh AI (Hermes, model yang sama dengan yang
menulis kode Minggu 7) sebagai reviewer awal pada dua PR Minggu 8. Setiap temuan
diverifikasi ulang dengan mesin (test, analyze, grep) sebelum diterima atau
ditolak. Yang menandatangani approve tetap manusia (pemilik repo).

## Prompt yang dipakai

```
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

Prompt dijalankan dua kali: sekali untuk `fix/mask-token-range`, sekali untuk
`fix/announcement-loading-state` (berkas yang direview dilampirkan apa adanya,
tanpa ringkasan).

## Tabel usulan AI vs keputusan final

| # | Temuan AI | Level | Verifikasi | Keputusan | Bukti |
|---|-----------|-------|------------|-----------|-------|
| 1 | `maskToken` memanggil `substring(0, 12)` tanpa cek panjang → `RangeError` untuk token < 12 karakter | blocker | BENAR | **Diterima** | test RED: `RangeError (end): Invalid value: Not in inclusive range 0..3: 12` di `format.dart 26:43`, lalu GREEN setelah perbaikan |
| 2 | `AnnouncementPage` memakai `state.value ?? []` sehingga saat loading menampilkan "belum tersedia" padahal data masih dimuat | blocker | BENAR | **Diterima** | widget test `deep link saat data belum siap menampilkan loader` gagal pada kode lama, lulus setelah `state.when` |
| 3 | `announcementsProvider` melempar `Exception(failure.message)` → prefix "Exception: " bocor ke UI | saran | SALAH | **Ditolak** | `messageOf` sudah memotong prefix; test `messageOf memakai pesan Failure apa adanya` lulus sebelum PR apa pun |
| 4 | Tambahkan cache `sqflite` untuk pengumuman sekarang juga | saran | benar secara teknis, di luar lingkup | **Ditolak** | Menambah dependensi + lapisan data baru bukan bagian Minggu 8; masuk daftar issue paruh kedua, bukan PR review |
| 5 | Pindahkan bootstrap FCM dari `HomePage` ke notifier Riverpod | saran | BENAR secara arsitektur | **Ditunda (bukan ditolak)** | Perubahan menyentuh Firebase + lifecycle; dicatat di `docs/review-checklist.md` sebagai utang teknis, tidak dikerjakan di PR review |

Ringkasan: 2 temuan blocker terbukti dan diperbaiki, 2 saran ditolak dengan
alasan tertulis, 1 saran valid ditunda dengan alasan lingkup.

## Kenapa temuan #3 ditolak (contoh argumen tertulis)

Klaim "prefix Exception bocor" tidak bertahan saat dijalankan:

```bash
flutter test test/core_format_test.dart
# messageOf memakai pesan Failure apa adanya  ... lulus
```

`messageOf(Object error)` memeriksa `error is Failure` lebih dulu dan memakai
`replaceFirst('Exception: ', '')` untuk sisanya. Menambah lapisan konversi
seperti saran AI hanya menggandakan kode tanpa mengubah perilaku.

## Verifikasi bahwa saran AI tidak melanggar dependency rule

Saran #5 (pindah bootstrap FCM ke notifier) diperiksa dulu: notifier tinggal di
`presentation/`, jadi `domain` tetap tidak menyentuh Firebase. Karena itu saran
tidak ditolak karena arsitektur, hanya karena lingkup.
Bukti domain tetap bersih: `docs/verifikasi-grep.txt` (tiga grep kosong).