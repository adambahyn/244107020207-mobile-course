# Temuan Profiling (Sebelum Optimasi)

Week 11 — PEMMOB JTI Polinema. Diukur di perangkat fisik (Infinix,
`121512545B015596`) dengan build `--profile`, bukan emulator.

## Cara mengukur

`flutter run --profile` + DevTools berbasis browser tidak dipakai untuk angka
utama, karena angkanya harus terbaca di screenshot. Sebagai gantinya dipakai
`lib/core/perf/perf_probe.dart`:

- `SchedulerBinding.instance.addTimingsCallback` menerima `FrameTiming` dari
  engine — **sumber data yang sama** dengan tab Performance DevTools
  (build span, raster span, total span per frame).
- Agregat (frame, jank > 16,67 ms, avg, p90, worst) ditampilkan sebagai overlay
  di layar **dan** dicetak ke logcat dengan prefiks `PERF|<label>|`.
- Skenario (cold start → scroll 6x → buka detail → kembali → pull-to-refresh)
  dibungkus satu skrip `campus_notify/tool/ukur.sh`, dijalankan identik untuk
  label `before` dan `after`, sehingga selisih angka murni karena kode.

Angka mentah: `metrics-before.txt`, `metrics-after.txt`, `memori.txt`.

## Konteks pengukuran

Data contoh dinaikkan dari 120 → **400 baris**
(`announcement_local_source.dart`, `_total = 400`) supaya ada daftar panjang
yang nyata untuk di-scroll dan supaya pagination punya halaman untuk dimuat.
Sebelumnya daftar terlalu pendek sehingga masalahnya tidak terlihat.

## 1. List tidak memakai builder (temuan utama)

`docs/before/home_page.dart` memakai `ListView(children: [...])` dengan 400
`Card` hasil `_announcementCard(item)`. Semuanya dibangun pada frame pertama,
termasuk yang tidak pernah dilihat pengguna.

Bukti:

| | nilai |
|---|---|
| Cold start (`am start -W`, TotalTime) | 1687 ms |
| Frame terburuk pada sesi | **80,1 ms** (≈5x budget 16,7 ms) |
| PSS proses setelah skenario | 233 292 KB |

## 2. Tidak ada pagination: seluruh tabel dibaca dan diparse tiap load

`AnnouncementLocalSource.readAll()` mengembalikan 400 baris, lalu repository
memetakan semuanya ke `AnnouncementModel` → `Announcement`. Tidak ada jalur
"ambil satu halaman". Baris biaya baca dan parse tumbuh linear dengan jumlah data,
padahal yang terlihat ~7 baris.

## 3. Tidak ada cache: request/parse berulang saat pull-to-refresh

Versi lama `fetchAnnouncements()` tidak punya parameter apa pun — setiap
`ref.invalidate(announcementsProvider)` (termasuk setiap kali pengguna menarik
layar, dan setiap halaman yang ikut watch provider itu) mengulang baca 400
baris + parse 400 objek. Di aplikasi nyata ini berarti 400 baris HTTP/SQLite
ulang untuk data yang jarang berubah.

## 4. Widget rebuild berlebih karena state digabung di satu halaman

`HomePage` memegang state status perangkat (`_accessMask`, `_tokenMask`,
`_fcmStatus`, `_refreshResult`) **bersama** daftar pengumuman. Setiap
`setState()` kecil (mis. hasil refresh 401) membangun ulang seluruh subtree
termasuk 400 kartu.

Selain itu baris daftar dibuat lewat method `_announcementCard(item)` di dalam
halaman — tidak ada widget terpisah, jadi tidak ada kesempatan `const` dan
Flutter tidak bisa melewati (skip) subtree yang tidak berubah.

## 5. Halaman detail memantau seluruh daftar

`docs/before/announcement_page.dart` melakukan `ref.watch(announcementsProvider)`
lalu mencari `id` di dalam daftar. Akibatnya halaman satu pengumuman ikut
dibangun ulang setiap kali daftar berubah — padahal hanya satu item yang
dibutuhkannya.

## 6. Tidak ada `RepaintBoundary` per baris

Scroll panjang membuat setiap kartu ikut di-repaint dalam layer yang sama
dengan overlay dan footer. Tidak ada pemisahan layer repaint untuk item yang
statis.

## Bukan temuan (sudah benar sejak awal)

- `ScrollController` dan listener: di versi lama tidak ada controller sama
  sekali, jadi tidak ada risiko listener bocor — tetapi juga tidak ada
  pagination. Setelah tambah controller, `dispose()` dan `removeListener()`
  harus eksplisit (diterapkan di `home_page.dart` baru).
- Memory leak saat navigasi: diuji di `memori.txt` — PSS **turun** dari
  217 287 KB ke 205 227 KB setelah 5x daftar → detail → kembali. Tidak ada
  objek yang menumpuk, jadi tidak ada perbaikan `dispose` tambahan yang
  diperlukan.
- Gambar jaringan: aplikasi ini belum memakai `Image.network`, jadi
  `CachedNetworkImage` / `memCacheWidth` tidak relevan (teknik pada jobsheet
  ini dilewati dengan alasan, bukan lupa).
