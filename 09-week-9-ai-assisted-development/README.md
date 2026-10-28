# Minggu 9 - AI-Assisted Development / Vibe Coding

Satu fitur kecil ditambahkan ke `campus_notify` dengan siklus **prompt ->
generate -> verify -> test -> refactor -> explain**: pencarian judul pengumuman
beserta *empty state*. Nilai dikerjakan pada kualitas verifikasi dan alasan
keputusan, bukan pada banyaknya kode AI.

## Fitur

Ikon cari di `AppBar` beranda membuka rute `/cari`. Kolom ketik menyaring
daftar pengumuman berdasarkan judul, tanpa membedakan huruf besar/kecil dan
mengabaikan spasi tepi. Baris hasil tetap dapat dibuka ke halaman detail.
Ketika daftar hasil kosong, halaman membedakan dua keadaan:

| Keadaan | Teks |
|---|---|
| pengumuman memang belum ada | `Belum ada pengumuman` |
| query tidak cocok dengan judul mana pun | `Tidak ada hasil untuk "<query>"` |

## Stack

Flutter (Dart SDK `^3.13.2`), `flutter_riverpod 3.4.3`, `go_router 18.0.2`,
`dio 5.11.1`, `flutter_secure_storage 11.2.0`. Arsitektur tetap seperti Minggu 7:
`presentation -> domain <- data`; aturan filter hidup di domain sebagai kelas
murni, widget dan provider tidak pernah menyentuh sumber data.

## Prompt 5 slot

```text
Peran   : senior Flutter dev.
Konteks : campus_notify, feature-first, Riverpod 3.4.3, GoRouter 18.0.2,
          Dio 5.11.1. Kontrak ditempel: Announcement, AnnouncementRepository,
          GetAnnouncements, announcementsProvider.
Tugas   : tambah pencarian judul pengumuman + empty state.
Batas   : jangan ubah arsitektur, jangan panggil repository dari widget,
          maksimal 80 baris, domain tidak boleh impor Flutter/Riverpod/Dio.
Output  : kode + 3 test case + cara uji.
```

Yang dikirim sebagai konteks hanya entity, kontrak repository, satu use case,
satu provider, dan daftar versi package. Token, `token_store.dart`, dan isi
penuh repository tidak pernah ditempel ke AI.

## Cara menjalankan

```bash
cd campus_notify
flutter pub get
flutter run              # lalu tekan ikon cari di beranda
```

Build dan pasang ke perangkat:

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Cara menguji query

| Query | Perilaku | Bukti |
|---|---|---|
| (kosong) | semua pengumuman tampil | `screenshots/09-01-cari-kosong.png` |
| `beasiswa` | 1 hasil, judul cocok | `screenshots/09-02-cari-cocok.png` |
| `zzz` | empty state "Tidak ada hasil" | `screenshots/09-03-cari-tidak-cocok.png` |

## Hasil verifikasi mesin

```text
$ flutter analyze
No issues found! (ran in 7.6s)

$ dart format lib test --set-exit-if-changed
Formatted 34 files (0 changed)

$ flutter test
00:15 +23: All tests passed!
```

Angka di atas dibaca dari keluaran perintah, bukan dari ingatan. Suite berisi
23 test: 14 warisan Minggu 7-8, 4 test use case murni
(`test/search_announcements_test.dart`), 4 widget test halaman cari
(`test/announcement_search_page_test.dart`), dan 1 test pembukti bug state
(`test/announcement_search_persistence_test.dart`).

## Yang terbukti dari AI

1. **Halusinasi jalur berkas.** Draf AI mengimpor
   `domain/announcement.dart`, `domain/get_announcements.dart`, dan
   `data/announcement_repository_impl.dart` yang tidak ada di proyek, memakai
   `Failure` tanpa import, dan memanggil `announcementsProvider` yang tidak
   diimpor. `flutter analyze` atas draf mentah menghasilkan **22 issue**
   (`docs/analyze-ai-draft.txt`). Klaim "analyze 0 issue" dari AI gugur.
2. **Filter salah lapisan.** Draf menaruh `where(...)` di provider
   presentation (`docs/ai-draft/1-announcement_search_provider.dart` baris 17),
   melanggar aturan Minggu 7. Setelah refactor aturan pindah ke
   `SearchAnnouncements` (domain) dan provider presentation tidak lagi memuat
   logika filter, diverifikasi dengan `grep`: 0 kemunculan `where(` di provider,
   1 di use case.
3. **Bug state yang lolos dari klaim AI.** Query tersimpan di provider global
   sedangkan `TextField` tanpa controller, jadi halaman yang dibuka ulang
   tampil kosong tetapi daftarnya masih terfilter query lama. Bug dibuktikan
   test merah lebih dulu (`docs/red-test-persistence.txt`, gagal di baris 58),
   lalu diperbaiki dengan `NotifierProvider.autoDispose` +
   `TextEditingController`. Usulan reviewer awal (satu `autoDispose`) belum
   cukup: `filteredAnnouncementsProvider` masih memegang listener, sehingga
   provider `autoDispose` kedua dibutuhkan.

Tiga temuan reviewer AI, tabel terima/tolak beserta alasan teknis, dan refleksi
ada di [`docs/ai-log.md`](docs/ai-log.md).

## Struktur folder

| Isi | Lokasi |
|---|---|
| Project Flutter dengan fitur cari | `campus_notify/` |
| Prompt mentah, output AI, verifikasi, tabel keputusan, refleksi | `docs/ai-log.md` |
| Draf AI apa adanya (3 berkas, sebelum perbaikan) | `docs/ai-draft/` |
| Keluaran `flutter analyze` pada draf mentah | `docs/analyze-ai-draft.txt` |
| Keluaran test merah pembukti bug | `docs/red-test-persistence.txt` |
| Screenshot perangkat (Infinix X6851, 1080x2436) | `screenshots/` |
| Laporan jobsheet | `Laporan Jobsheet Minggu 9 - Adam Bahy Maulana.docx` + `.pdf` |
| Perintah pembangun laporan (WordCraft) | `gen_wc9.py` + `job-laporan9.json` |

Salinan web codelab (`#09 _ ...html` dan folder `_files`) tidak dilacak git;
pengaturannya ada di `.gitignore` folder ini.
