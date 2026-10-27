# PEMMOB — Instruksi Kerja Agent

Repo praktikum Flutter JTI Polinema. Satu folder per minggu:

```
NN-week-N-<slug>/            # root minggu = laporan + docs + screenshots
├── README.md               # LAPORAN (wajib)
├── docs/                   # dokumen pendukung (AI challenge, dll)
├── screenshots/            # bukti dari device asli
├── lib/  test/             # salinan kode yang dibahas di laporan
└── <nama_project>/         # project Flutter (flutter create + android/)
```

Referensi codelab: `codelab_flutter_jti_polinema.md`
Standar mutu laporan: `04-week-4-networking-rest-api/README.md`.

---

## 1. Aturan wajib (jangan dilanggar)

1. **Laporan di root minggu, bukan di dalam project.** `README.md`, `docs/`,
   `screenshots/` selalu di `NN-week-N-<slug>/`. Project Flutter di subfolder.
2. **Screenshot dari device fisik via USB debugging.** Bukan emulator, bukan
   web, bukan golden test.
3. **Bahasa output: Indonesia.** Kode & penjelasan ringkas, tanpa reasoning
   bertele-tele.
4. **Jangan pernah `rm` file bernama `readme`/`README`/`Readme`** tanpa cek dulu
   — Windows case-insensitive, satu `rm` bisa menghapus dua file berbeda.
5. **Commit setelah tiap milestone** (kode jalan → test lulus → screenshot →
   laporan). Jangan biarkan kerja panjang hanya di working tree.
6. **Repository = satu-satunya pintu data.** Widget tidak memanggil SQLite /
   SharedPreferences / HTTP langsung.

## 2. Alur kerja per minggu (urutan tetap)

Ikuti urutan ini; tiap langkah selesai sebelum lanjut. Jangan ulang langkah
yang sudah selesai.

1. **Baca codelab** — ambil HTML minggu dari folder minggu (sudah tersimpan),
   atau `curl -sL` versi web. Baca sekali, rangkum step + deliverable.
2. **Cek repo dulu** — `ls` folder minggu + `git status`. Project mungkin sudah
   di-scaffold. Jangan buat ulang.
3. **Scaffold + dependency** sekali jalan:
   `flutter create <project> && flutter pub add <deps>` (cek versi API dulu).
4. **Tulis kode** per praktikum. Commit tiap praktikum selesai.
5. **Test + analyze**: `dart format lib test && flutter analyze && flutter test`.
   Perbaiki sampai bersih sebelum build.
6. **Build + install** sekali: `flutter build apk --release` lalu `adb install -r`.
   Jangan ulang build kalau tidak ada perubahan kode.
7. **Screenshot** satu alur penuh dalam script (lihat §4). Sekali jalan, jangan
   ulang-ulang.
8. **Tulis laporan** di root minggu. Commit.
9. **Verifikasi**: link laporan resolve, semua screenshot ada, test hijau.

## 3. Cek versi API sebelum memakai (hemat rebuild)

Riverpod/Dio/dll bisa berubah API antar versi. Cek dulu, baru tulis:

```bash
grep -rn "class StateProvider" ~/AppData/Local/Pub/Cache/hosted/pub.dev/riverpod-*/lib | head
```

Contoh nyata: Riverpod 3 **menghapus `StateProvider`** → pakai
`Notifier`/`NotifierProvider`. Salah tebak API = analyze gagal = rebuild mahal.

## 4. Device & adb (Windows)

- **adb TIDAK di PATH.** Export sekali per shell session, lalu pakai terus:
  ```bash
  export PATH="$PATH:/c/Users/adamb/AppData/Local/Android/Sdk/platform-tools"
  adb devices -l
  ```
- Device saat ini: HP Infinix, id `121512545B015596`, layar **1080x2436**,
  package `com.example.<nama_project>`.
- **Kumpulkan semua langkah adb dalam SATU script**, bukan satu panggilan per
  aksi. Template:
  ```bash
  export PATH="$PATH:/c/Users/adamb/AppData/Local/Android/Sdk/platform-tools"
  P=com.example.<nama_project>
  D="NN-week-N-<slug>/screenshots"
  adb shell am force-stop $P; sleep 1
  adb shell monkey -p $P -c android.intent.category.LAUNCHER 1 >/dev/null; sleep 6
  adb shell input tap <x> <y>; sleep 2
  adb exec-out screencap -p > "$D/01-nama.png"
  ```
- **Koordinat tap jangan dikira-kira.** Ambil dulu:
  ```bash
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null
  adb shell cat /sdcard/ui.xml | tr '>' '\n' | grep -o 'text="[^"]*"[^>]*bounds="[^"]*"'
  ```
  Koordinat biasa di layar 1080x2436: navigasi bawah y≈2270, FAB ≈(855,2184),
  app bar kanan ≈(1008,192).
- **`adb shell input text` TIDAK mendukung spasi** → ganti spasi dengan `%s`.
- **Jangan kirim `keyevent 111` (ESC)** untuk menutup dialog sebelum screenshot —
  dialog tertutup dan data hilang.
- **Aplikasi lain bisa mencuri foreground** → `am force-stop` app lain dulu, atau
  pastikan `dumpsys window | grep mCurrentFocus` menunjuk package kita.
- Verifikasi screenshot dengan `vision_analyze` — jangan asumsikan tampilannya
  benar.

## 5. Windows / git-bash quirk yang bikin kerja boros

1. **Line ending CRLF mematahkan `patch` multi-baris.** Sebelum edit file
   Dart/generated, normalisasi dulu:
   ```bash
   sed -i 's/\r$//' path/ke/file.dart
   ```
   Kalau `patch` gagal 2x pada region yang sama: **berhenti patch, pakai
   `write_file`** (baca file penuh dulu), atau edit presisi via python heredoc.
   Jangan ulangi patch yang sama berkali-kali.
2. **Path native vs MSYS.** Native tool (git, node, python) tidak menerima
   `/c/Users/...`. Pakai `C:/Users/...` untuk argumen mereka. `cd /c/...` (bash
   builtin) tetap boleh.
3. **File bernama `~`** ganda: jangan campur `read_file` relatif setelah `cd`.
   Setelah `cd`, pakai **absolute path** untuk read_file/write_file/patch.
4. **`rm -rf` butuh approval**; jalankan sekali untuk pekerjaan lengkap, jangan
   berulang.

## 6. Aturan anti-boros token (WAJIB)

Terapkan ini untuk menghemat ribuan panggilan:

1. **Batch panggilan independen** dalam satu turn. Baca 5 file sekaligus, bukan
   5 turn.
2. **Hindari re-read.** File yang sudah dibaca pakai offset/limit kecil saja,
   bukan baca ulang penuh.
3. **`grep`/`search_files` sebelum baca** untuk melokalisasi baris, bukan baca
   file 500 baris untuk satu fungsi.
4. **Build APK sekali per batch perubahan**, bukan tiap edit kecil.
5. **Screenshot sekali per alur**; kalau build berubah, ambil ulang hanya yang
   terpengaruh, bukan semua.
6. **Jangan ulang test yang sama.** Jalankan `flutter test` sekali setelah
   kumpulan perubahan selesai.
7. **Satu kali baca codelab**, simpan rangkumannya; jangan fetch ulang.
8. **Commit tiap milestone** supaya kesalahan bisa di-rollback tanpa rework.
9. **Delegasi tugas terisolasi** ke subagent (mis. menyusun ringkasan codelab,
   menulis draf laporan, menyiapkan script screenshot) agar konteks utama tetap
   ringan.
10. **Jangan pernah simpan/tulis kredensial** ke repo.

## 7. Checklist akhir tiap minggu

- [ ] `flutter analyze` bersih
- [ ] `flutter test` semua lulus
- [ ] APK terinstal & dijalankan di device fisik
- [ ] Semua screenshot ada di `NN-week-N-<slug>/screenshots/`
- [ ] `README.md` di root minggu, link ke screenshot/docs resolve
- [ ] `docs/` berisi deliverable tambahan (mis. ai-challenge)
- [ ] `git status` bersih / ter-commit
- [ ] Tidak ada `build/`, `.dart_tool/`, `.gradle/` yang ikut ter-commit
