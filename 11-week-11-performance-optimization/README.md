# Minggu 11 - Optimasi Performa

Optimasi performa `campus_notify` (project Minggu 10): baseline profiling di
perangkat fisik dengan build `--profile`, identifikasi masalah, terapkan 6
teknik optimasi, ukur ulang dengan skenario yang identik.

## Ringkasan hasil

| Metrik | Sebelum | Sesudah | Δ |
|---|---:|---:|---|
| Cold start (`am start -W`, TotalTime) | 1687 ms | 1474 ms | **−12,6%** |
| Frame terburuk sesi | 80,1 ms | 56,2 ms | **−30%** |
| TOTAL PSS | 233 292 KB | 222 407 KB | **−4,7%** |
| Jank (>16,67 ms) | 8 (2,0%) | 10 (2,4%) | tanpa perubahan berarti |
| Kartu dibangun saat load | 400 | 20 | −95% |

Laporan lengkap (metode, temuan, analisis per teknik):
[`docs/performance-report.md`](docs/performance-report.md) ·
temuan profiling: [`docs/performance-findings.md`](docs/performance-findings.md) ·
angka mentah: [`docs/metrics-before.txt`](docs/metrics-before.txt),
[`docs/metrics-after.txt`](docs/metrics-after.txt),
[`docs/memori.txt`](docs/memori.txt).

## Teknik yang diterapkan

1. **`ListView.builder`** — sebelumnya `ListView(children:)` membangun 400 kartu
   pada frame pertama.
2. **Pagination** — 20 pengumuman per halaman (`readPage` di data source,
   `AsyncNotifier` di presentation), halaman berikut dimuat 400 px sebelum dasar
   daftar; screenshot memperlihatkan item 33–39 terbuka setelah hanya dua
   layar scroll.
3. **Repository cache** (stale-while-revalidate, TTL 30 s, `forceRefresh` untuk
   pull-to-refresh) — dibuktikan test `sourceReads`, bukan klaim.
4. **Widget baris terpisah + `RepaintBoundary`** (`AnnouncementTile`) — parent
   rebuild tidak membangun ulang isi daftar.
5. **Pecah `_DeviceStatusSection`** — `setState` status perangkat tidak lagi
   menyapu daftar.
6. **`Provider.family` per id** — halaman detail hanya memantau satu item, bukan
   seluruh daftar.

Dilewati dengan alasan: `CachedNetworkImage` (tidak ada gambar jaringan),
Dio retry interceptor (endpoint kampus nyata belum ada).

## Cara ukur

Instrumen: `campus_notify/lib/core/perf/perf_probe.dart` —
`SchedulerBinding.addTimingsCallback` (`FrameTiming`, sumber data yang sama
dengan tab Performance DevTools), agregat jank/avg/p90/worst ditampilkan di
overlay layar dan dicetak ke logcat `PERF|<label>|...`. Skenario identik
before/after: `campus_notify/tool/ukur.sh`; uji leak memori:
`campus_notify/tool/memori.sh`.

Label binary lewat dart-define:
`flutter build apk --profile --dart-define=PERF_LABEL=before|after`.

## Bukti perangkat

| Screenshot | Isi |
|---|---|
| [`11-01-before-profile.png`](screenshots/11-01-before-profile.png) | Overlay `before`: frame=403 jank=8(2,0%) avg=5,5ms max=80,1ms |
| [`11-02-after-home.png`](screenshots/11-02-after-home.png) | Window 19 frame pertama sesudah launch (`avg=18,9ms`) — beban startup terpisah dari skenario |
| [`11-04-after-profile.png`](screenshots/11-04-after-profile.png) | Overlay `after`: frame=419 jank=10(2,4%) avg=5,6ms max=56,2ms; item 33–39 = halaman ke-2 terbukti lazily |

Semua dari perangkat fisik Infinix (`121512545B015596`), build profile.

## Hasil verifikasi mesin

```
flutter analyze
No issues found! (ran in 12.3s)

flutter test
00:40 +40: All tests passed!
```

Termasuk test baru `test/announcement_cache_test.dart`: cache TTL (`sourceReads
== 1`), `forceRefresh` (`sourceReads == 2`), dan pembagian halaman
`fetchPage` (20/halaman, halaman terakhir 10 + `hasMore=false`).

## Refleksi

**Optimasi mana yang berdampak terbesar?** `ListView.builder` + pagination.
Sebelumnya frame pertama harus membangun 400 subtree kartu — itu yang
menjadikan cold start 1687 ms dan frame terburuk 80,1 ms. Setelah hanya 20
subtree dibangun, beban yang tersisa jelas turun. Teknik lain (cache, select
per id) menghemat kerja CPU tapi bukan kerja frame, sehingga tidak terlihat di
frame timing — dampaknya diukur dengan alat yang tepat (test jumlah baca
sumber data).

**Bagaimana memverifikasi bukan placebo?** Dengan mengukur ulang semua metrik
dengan skrip identik dan menerima hasil yang tidak menguntungkan: jank scroll
tidak turun (2,0% → 2,4%) dan saya tidak mengklaim sebaliknya. Klaim hanya
dibuat untuk angka yang benar-benar bergerak (cold start, frame terburuk,
PSS) atau yang bisa dibuktikan lewat test (`sourceReads`). Screenshot overlay
menunjukkan angka yang sama dengan yang saya tulis.

**Trade-off?** Pagination menambah satu state machine (`FeedState`: items,
hasMore, loadingMore) dan dua race condition kecil yang harus dijaga (request
beruntun, refresh saat loadMore berjalan) — kompleksitas nyata, dibayar dengan
test. Cache TTL menambah pertanyaan baru ("seberapa basi data yang masih
boleh tampil?") yang dijawab dengan 30 detik + `forceRefresh` eksplisit.
Layout footer di dalam daftar (`itemCount = items.length + 1`) juga lebih
sulit dibaca daripada `Column` sederhana.

**Kapan optimasi premature dihindari?** Ketika belum ada angka baseline.
Contoh nyata dari minggu ini: saya hampir menambah `RepaintBoundary` dan
memoization di mana-mana, padahal pengukuran menunjukkan raster hanya 3,6 ms
dan avg 5,5 ms — scroll daftar teks tidak pernah jadi bottleneck. Optimasi
yang benar adalah yang menyasar frame terburuk (startup), dan itu hanya
terlihat setelah diukur.

## Struktur folder

```
11-week-11-performance-optimization/
├── README.md                  # laporan ini
├── docs/
│   ├── performance-findings.md    # temuan profiling + metode ukur
│   ├── performance-report.md      # laporan lengkap before/after
│   ├── metrics-before.txt         # angka mentah sebelum
│   ├── metrics-after.txt          # angka mentah sesudah
│   ├── memori.txt                 # uji leak (5x navigasi)
│   └── before/                    # snapshot kode baseline (pembanding diff)
├── screenshots/               # bukti perangkat
├── lib/ test/                 # salinan kode yang dibahas
└── campus_notify/             # project Flutter
    ├── lib/core/perf/perf_probe.dart          # instrumen ukur
    ├── tool/ukur.sh, tool/memori.sh           # skrip ukur
    └── test/announcement_cache_test.dart      # bukti cache/pagination
```

## Keterbatasan yang disadari

- Angka jank sesi didominasi fase startup dan navigasi, bukan scroll murni —
  pemisahan fase per-frame (mis. reset probe saat scroll mulai) akan memberi
  perbandingan scroll yang lebih tajam; tidak dilakukan karena butuh rebuild
  baseline dan perbedaannya sudah tercakup oleh metrik startup.
- Data masih lokal (400 baris contoh), jadi cache dan payload jaringan diuji
  lewat unit test, bukan HTTP nyata.
- `CachedNetworkImage` tidak relevan untuk project ini (belum ada gambar
  jaringan).
