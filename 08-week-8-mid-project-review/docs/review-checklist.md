# Checklist kesiapan paruh semester

Dinilai bukan dari banyaknya fitur, melainkan fondasi yang bisa dipercaya untuk
paruh kedua.

| Butir | Status | Bukti |
|-------|--------|-------|
| Struktur feature-first terbukti | LULUS | tiga grep sterilitas kosong (`docs/verifikasi-grep.txt`) |
| `flutter analyze` bersih | LULUS | `No issues found!` (log di `docs/verifikasi-analyze.txt`) |
| `flutter test` hijau | LULUS | `+14 All tests passed!` (log di `docs/verifikasi-test.txt`) |
| `dart format` tidak mengubah apa pun | LULUS | `Formatted 25 files (0 changed)` |
| PR kecil + commit jelas | LULUS | tiga PR, tiap PR < 300 baris (`docs/commit-audit.md`) |
| README + screenshot + cara menjalankan | LULUS | `README.md`, `screenshots/` |
| Komentar review ditindaklanjuti | LULUS | `docs/pr-01-mask-token.md`, `docs/pr-02-announcement-loading.md` |
| Aplikasi berjalan identik akhir Minggu 7 | LULUS | screenshot `screenshots/08-*.png` dari perangkat Infinix |
| CI menolak PR kotor | ADA | `.github/workflows/ci.yml` (job `verify`) |

## Utang teknis yang sengaja dibiarkan (paruh kedua)

1. Bootstrap FCM masih di `HomePage` (`_bootstrapFcm`). Rencana: pindah ke
   `Notifier` di `presentation/` supaya widget tidak memegang lifecycle Firebase.
2. Belum ada cache lokal; data pengumuman masih dari sumber contoh. Rencana:
   `sqflite` sebagai implementasi kedua `AnnouncementRepository`.
3. `announcementsProvider` masih membungkus `Failure` menjadi `Exception`.
   Rencana: expose `Failure` bertipe lewat `AsyncError` saat menyentuh jaringan
   nyata, supaya UI bisa membedakan gagal jaringan vs gagal sesi.

## Tabel sebelum/sesudah pesan commit (Praktikum 1 langkah 3)

| Sebelum | Sesudah | Alasan |
|---|---|---|
| `p` | `chore(week8): salin proyek Minggu 7 sebagai baseline review` | menyebut tipe, lingkup, dan isi perubahan |
| `Hapus gitignore dan AGENTS.md` | `chore(repo): hapus .gitignore dan AGENTS.md dari pelacakan` | menjelaskan objek yang dihapus dan dampaknya |
| `Week 7: refactor campus_notify ke feature-first Clean Architecture (analyze bersih, 10 test, 3 grep nol) + docs AI challenge + builder laporan` | `refactor(arch): pisahkan campus_notify ke feature-first, presentation -> domain <- data` | satu commit satu tujuan; bukti mesin pindah ke badan commit |

Tiga masalah yang ditandai saat audit: commit `p` tanpa makna, satu commit
memuat tiga tujuan (3.411 baris), dan subjek berprefix `Week 7:` yang bukan tipe
konvensional.

## Temuan arsitektur yang ditunda

Reviewer menandai `AnnouncementPage` membaca `announcementsProvider` (daftar
global) lalu mencari id di dalamnya. Konsekuensinya halaman detail tidak bisa
memuat satu pengumuman tanpa mengunduh seluruh daftar, dan ketergantungannya
pada bentuk provider, bukan pada kontrak domain. Usulan: use case
`GetAnnouncementById` di `domain/usecases/`, diimplementasikan repository yang
sama. Tidak dikerjakan di PR perbaikan bug karena mengubah kontrak domain;
masuk rencana paruh kedua bersama dua utang teknis lain di bawah.

## Catatan penilaian diri

Yang paling rapuh di paruh pertama bukan fitur, tapi kebiasaan: kode Minggu 7
punya dua bug yang lolos karena test hanya menguji jalur bahagia (token panjang,
data sudah tersedia). Dua bug itu justru ditemukan saat review, bukan saat
menulis. Karena itu Minggu 8 menambah widget test untuk keadaan loading dan
rentang masukan pendek.