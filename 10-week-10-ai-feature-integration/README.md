# Minggu 10 - Integrasi Fitur AI

Satu fitur AI ditambahkan ke `campus_notify`: **asisten kampus berbasis LLM**
yang menjawab pertanyaan singkat seputar layanan kampus. Siklus kerja sama
dengan Minggu 9: *prompt → generate → verify → test → refactor → explain*,
dengan penekanan pada privasi, biaya, dan fallback.

Penyedia: Inferhub, `https://api.inferhub.dev/v1` (protokol OpenAI compatible),
model `combo/uu`.

## Fitur

Ikon bintang di `AppBar` beranda membuka rute `/asisten`. Halaman berisi kolom
pertanyaan, gelembung percakapan, penghitung permintaan, dan indikator kunci
API dalam bentuk tersamar. Tiga keadaan yang dibedakan:

| Keadaan | Tampilan |
|---|---|
| belum ada percakapan | petunjuk singkat + peringatan data pribadi |
| jawaban tersedia | gelembung pengguna dan gelembung asisten |
| gagal | bilah `Mode offline` + tombol `Coba lagi`, tanpa kehilangan pertanyaan |

## Stack

Flutter (Dart SDK `^3.13.2`), `flutter_riverpod 3.4.3`, `go_router 18.0.2`,
`http 1.6.0`, `flutter_secure_storage 11.2.0`. Arsitektur tetap
`presentation -> domain <- data`; aturan masukan dan prompt sistem berada di
domain, lapisan data satu-satunya yang mengetahui HTTP dan penyedia AI.

```
lib/features/ai/
├── domain/
│   ├── entities/chat_message.dart
│   ├── repositories/ai_assistant.dart      # kontrak, tanpa Flutter/http
│   └── usecases/ask_assistant.dart         # kSystemPrompt + batas masukan
├── data/
│   ├── datasources/ai_key_store.dart       # flutter_secure_storage
│   └── repositories/inferhub_assistant.dart
└── presentation/
    ├── providers/ai_providers.dart         # wiring + ChatNotifier
    └── pages/assistant_page.dart
```

## Prompt sistem

```text
Kamu asisten kampus Politeknik Negeri Malang. Jawab dalam Bahasa Indonesia,
maksimal 3 kalimat, tanpa membahas data pribadi pengguna. Bila pertanyaan di
luar topik kampus, tolak dengan sopan.
```

Prompt pengguna, keluaran awal AI, dan tabel keputusan ada di
[`docs/ai-log.md`](docs/ai-log.md). Keluaran mentah tersimpan di
`docs/output-awal-ai.txt`, badan permintaan di `docs/permintaan-ai.json`.

## Tabel risiko dan mitigasi

| Risiko | Mitigasi di kode | Sisa risiko |
|---|---|---|
| Data pribadi terkirim ke AI | Prompt sistem melarang membahas data pribadi; layar memperingatkan agar tidak mengirim NIK atau nomor telepon; tidak ada field profil yang dikirim | pengguna tetap dapat mengetik data pribadi secara sukarela |
| API key bocor | Key disimpan di `flutter_secure_storage`, dibaca per panggilan, tidak ada di kode sumber, tidak pernah ditampilkan penuh (hanya 10 karakter pertama) | perangkat yang sudah di-root dapat membaca penyimpanan aman |
| Biaya melonjak | `max_tokens` 400, pertanyaan dibatasi 500 karakter, maksimum 20 permintaan per sesi dengan penghitung di layar | batas di sisi klien dapat dilewati dengan membuka ulang halaman |
| Layanan AI mati | Setiap kegagalan dipetakan ke `Failure`; bilah `Mode offline` muncul dengan tombol `Coba lagi`; fitur pengumuman tetap berjalan | tidak ada antrean otomatis; pengguna harus menekan `Coba lagi` |
| Respons tidak relevan | Prompt sistem membatasi topik kampus dan panjang jawaban | tidak ada penyaring keluaran otomatis |
| Batas waktu habis | Batas 60 detik, diukur dari permintaan nyata 30.11 detik | jaringan lambat tetap dapat melewati batas |

## Cara menjalankan

```bash
cd campus_notify
flutter pub get
flutter run
```

Atur kunci lewat ikon kunci di halaman Asisten AI. Kunci tidak disertakan di
repository; isi manual di perangkat.

Build dan pasang ke perangkat:

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Bukti perangkat

| Keadaan | Berkas | Isi |
|---|---|---|
| halaman kosong, kunci belum diatur | `screenshots/10-01-asisten-kosong.png` | status `Kunci: (belum diatur)`, penghitung `0/20` |
| jawaban dari API nyata | `screenshots/10-02-asisten-jawaban.png` | pertanyaan jam layanan, jawaban 3 kalimat, penghitung `1/20` |
| gagal koneksi | `screenshots/10-03-asisten-fallback.png` | bilah `Tidak ada koneksi internet. Mode offline`, tombol `Coba lagi` |

Isi ketiga gambar dibaca ulang dengan OCR dan disimpan di
`docs/screenshots-ocr.txt`, bukan disimpulkan dari nama berkas.

## Hasil verifikasi mesin

```text
$ flutter analyze
No issues found! (ran in 84.5s)

$ flutter test
00:26 +37: All tests passed!
```

Suite 37 test: 23 warisan Minggu 7 sampai 9, 3 test use case
(`test/ask_assistant_test.dart`), 7 test repository dengan klien HTTP tiruan
(`test/inferhub_assistant_test.dart`), dan 4 widget test halaman asisten
(`test/assistant_page_test.dart`).

## Struktur folder

| Isi | Lokasi |
|---|---|
| Project Flutter dengan fitur asisten | `campus_notify/` |
| Prompt, keluaran awal AI, tabel keputusan | `docs/ai-log.md` |
| Keluaran mentah API dan badan permintaan | `docs/output-awal-ai.txt`, `docs/permintaan-ai.json` |
| Bukti OCR screenshot | `docs/screenshots-ocr.txt` |
| Screenshot perangkat (Infinix X6851, 1080x2436) | `screenshots/` |
| Laporan jobsheet | `Laporan Jobsheet Minggu 10 - Adam Bahy Maulana.docx` + `.pdf` |
| Pembangun laporan (WordCraft) | `gen_wc10.py` + `job-laporan10.json` |

Salinan web codelab (`#10 _ Integrasi Fitur AI.html` dan folder `_files`) tidak
dilacak git; pengaturannya ada di `.gitignore` folder ini.

## Keterbatasan yang disadari

Kunci API berada di aplikasi klien karena proyek ini tidak memiliki backend
kampus. Untuk pemakaian nyata, permintaan harus lewat backend yang memegang
kunci, dan aplikasi hanya menerima jawaban. Konsekuensi ini juga dicatat di
`docs/ai-log.md` sebagai usulan AI yang ditolak pada tahap verifikasi.