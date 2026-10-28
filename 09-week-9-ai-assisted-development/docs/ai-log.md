# AI Log — Minggu 9 (AI-Assisted Development)

Catatan lengkap siklus **prompt → generate → verify → test → refactor → explain**
untuk fitur *search judul pengumuman + empty state* di `campus_notify`.

Peran generator dan reviewer diisi dua sesi AI terpisah (subagent terisolasi,
saling tidak melihat konteks), sesuai kebijakan minggu 9: AI mengusulkan,
mahasiswa memverifikasi dan memutuskan.

---

## Praktikum 1 — Prompt dan context engineering

Formula 5 slot yang dikirim ke generator:

```text
Peran: senior Flutter dev.
Konteks: project `campus_notify`, feature-first (presentation -> domain <- data),
Riverpod, pengumuman diambil lewat repository. Versi package:
flutter_riverpod 3.4.3, dio 5.11.1, go_router 18.0.2, Dart SDK ^3.13.2.
Kontrak yang ditempel: Announcement (entity), AnnouncementRepository (kontrak),
GetAnnouncements (use case), announcementsProvider (FutureProvider).
Tugas: tambah pencarian judul pengumuman (search) + empty state.
Batas: jangan ubah arsitektur, jangan panggil repository dari widget, maksimal 80 baris.
Output: kode + 3 test case + cara uji.
```

Yang **tidak** ditempel ke AI: token, API key, isi `token_store.dart`, dan sisa
repo. Yang ditempel hanya satu entity, satu kontrak repository, satu use case,
dan satu provider — sesuai aturan "beri konteks, bukan secret".

## Praktikum 2 — Output mentah generator

<!-- RAW_GENERATOR_OUTPUT -->

<!-- AKHIR RAW_GENERATOR_OUTPUT -->

## Verifikasi 6 langkah

<!-- VERIFY -->

## AI Challenge — review oleh AI reviewer

<!-- REVIEW -->

## Keputusan per berkas

<!-- KEPUTUSAN -->
