# Laporan Optimasi Performa — Week 11

Project: `campus_notify` (dari Week 10). Perangkat ukur: Infinix fisik
(`121512545B015596`), build `flutter build apk --profile`.

## 1. Baseline metrics (sebelum)

Diukur dengan `SchedulerBinding.addTimingsCallback` (`FrameTiming` — sumber yang
sama dengan tab Performance DevTools), dibungkus `PerfProbe` yang menampilkan
angka di layar dan mencetak `PERF|<label>|...` ke logcat. Skenario sama untuk
before/after: cold start → 6x scroll cepat → buka detail → kembali →
pull-to-refresh (`tool/ukur.sh`).

| Metrik | Sebelum | Sesudah | Δ |
|---|---:|---:|---|
| Cold start `TotalTime` (`am start -W`) | 1687 ms | 1474 ms | **−213 ms (−12,6%)** |
| Frame terukur sesi | 403 | 419 | — |
| Jank (> 16,67 ms) | 8 (2,0%) | 10 (2,4%) | +0,4 pp (di dalam noise) |
| Rata-rata frame time | 5,5 ms | 5,6 ms | +0,1 ms |
| Frame terburuk | **80,1 ms** | **56,2 ms** | **−23,9 ms (−30%)** |
| TOTAL PSS | 233 292 KB | 222 407 KB | **−10 885 KB (−4,7%)** |
| Widget daftar dibangun saat load | 400 | 20 | −95% (kode) |

Screenshot overlay: [`11-01-before-profile.png`](../screenshots/11-01-before-profile.png),
[`11-04-after-profile.png`](../screenshots/11-04-after-profile.png). Angka mentah:
[`metrics-before.txt`](metrics-before.txt), [`metrics-after.txt`](metrics-after.txt),
[`memori.txt`](memori.txt).

### Kejujuran tentang angka

Jank persentase **tidak turun** (2,0% → 2,4%). Penyebabnya: skenario scroll
dirancang untuk mengukur scroll, dan scroll daftar teks memang sudah cepat di
kedua versi (rata-rata 5,5 vs 5,6 ms/frame) — jank pada sesi berasal dari
bukak aplikasi dan navigasi, bukan dari scroll. Yang benar-benar bergerak adalah
biaya startup (−12,6%), frame terburuk (−30%), dan memori (−4,7%). Dua teknik
penambahan (cache, halaman detail selektif) tidak memengaruhi angka-angka di
atas sama sekali — manfaatnya diukur lewat test, bukan frame timing, dan
dilaporkan apa adanya di §5.

## 2. Temuan profiling

Lengkap di [`performance-findings.md`](performance-findings.md). Ringkas:

1. `ListView(children:)` membangun 400 kartu sekaligus saat frame pertama.
2. Tidak ada pagination — seluruh 400 baris dibaca dan diparse tiap load.
3. Tidak ada cache — pull-to-refresh mengulang baca + parse penuh.
4. State status perangkat di `HomePage` membuat `setState` kecil membangun
   ulang seluruh daftar; baris dibuat via method (bukan widget terpisah), jadi
   tidak bisa `const`.
5. Halaman detail `ref.watch(announcementsProvider)` (seluruh daftar) padahal
   hanya butuh satu item.
6. Tidak ada `RepaintBoundary` per baris.
7. Bukan leak: navigasi bolak-balik 5x justru menurunkan PSS
   (217 287 → 205 227 KB) — tidak ada `dispose()` tambahan yang diperlukan.

## 3. Optimasi yang diterapkan (6 dari daftar jobsheet)

| # | Teknik | Lokasi | Alasan |
|---|---|---|---|
| 1 | `ListView.builder` | `home_page.dart` | Hanya baris terlihat yang dibangun: 400 → ±7 subtree. |
| 2 | Pagination (infinite scroll) | `announcement_local_source.readPage`, `AnnouncementFeed` (AsyncNotifier) | Muat 20/halaman; halaman berikut diminta 400 px sebelum dasar daftar. `hasMore` + `loadingMore` mencegah request dobel. |
| 3 | Repository cache (stale-while-revalidate, TTL 30 s) + `forceRefresh` | `announcement_repository_impl.dart` | Pull-to-refresh tetap segar; navigasi ulang dalam TTL tidak menyentuh sumber data. |
| 4 | Ekstrak widget + `RepaintBoundary` per baris | `announcement_tile.dart` | Subtree baris bisa di-skip saat parent rebuild; repaint terisolasi per baris. |
| 5 | Pecah `_DeviceStatusSection` | `home_page.dart` | `setState` status perangkat tidak lagi membangun ulang daftar. |
| 6 | `Provider.family` per id (`announcementByIdProvider`) | `announcement_page.dart`, providers | Halaman detail hanya ikut rebuild saat item yang dibuka berubah. |

Dilewati dengan alasan: `CachedNetworkImage` (tidak ada gambar jaringan di
project ini), Dio interceptor retry (endpoint nyata kampus belum ada — baca
data masih lokal).

## 4. Verifikasi

- `flutter analyze` → **No issues found!**
- `flutter test` → **40 test, All tests passed!**, termasuk
  `test/announcement_cache_test.dart` yang membuktikan:
  - baca berulang dalam TTL → `sourceReads == 1` (cache bekerja, bukan placebo),
  - `forceRefresh` → `sourceReads == 2`,
  - `fetchPage` membagi 400 baris → 20/halaman, halaman terakhir 10 baris +
    `hasMore == false`, halaman di luar rentang kosong.
- Di perangkat: screenshot `11-02-after-home.png` menangkap **window 19 frame
  pertama** setelah launch (`jank=6(31,6%) avg=18,9ms`) — beban startup kini
  terukur terpisah dari skenario scroll. Screenshot `11-04-after-profile.png`
  menampilkan item 33–39 setelah hanya dua layar scroll: halaman ke-2 (item
  21–40) terbukti dimuat lazily di perangkat, bukan hanya di test.
- Memori: 5x navigasi daftar → detail tidak menaikkan PSS (lihat `memori.txt`).

## 5. Hasil per teknik (jujur: mana yang terukur, mana yang tidak)

| Teknik | Dampak terukur | Cara verifikasi |
|---|---|---|
| `ListView.builder` + pagination | Cold start −213 ms, frame terburuk −30%, PSS −10,9 MB | `ukur.sh` before/after, `am start -W`, `dumpsys meminfo` |
| Cache repository | Tidak terlihat di frame timing (memang bukan beban frame) | Test `sourceReads` |
| `announcementByIdProvider` | Tidak terlihat di frame timing (halaman detail ringan di kedua versi) | Alasan struktural; rebuild detail tidak memengaruhi angka sesi |
| Tile terpisah + `RepaintBoundary` | avg/raster stabil (0,7/3,7 ms) | overlay sesudah |
| `_DeviceStatusSection` | Tidak terukur terpisah (refresh 401 jarang diketuk saat profiling) | Alasan struktural |

## 6. Artefak

- Project: `campus_notify/` (kode lengkap + test).
- Salinan kode yang dibahas: `lib/`, `test/` di root minggu ini.
- Versi lama (baseline) yang dipakai sebagai pembanding diff:
  `docs/before/home_page.dart`, `docs/before/announcement_page.dart`,
  `docs/before/announcement_repository_impl.dart`.
- Skrip ukur: `campus_notify/tool/ukur.sh` (skenario before/after identik),
  `campus_notify/tool/memori.sh` (uji leak memori).
- Instrumen ukur: `campus_notify/lib/core/perf/perf_probe.dart`.
