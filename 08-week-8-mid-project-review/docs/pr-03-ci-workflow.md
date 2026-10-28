# PR: chore(ci) — workflow verify untuk PR

Cabang: `chore/ci-workflow` → `develop` · Berkas: 1 · +20 / −0

## Masalah

Tidak ada penjaga otomatis. Review manual sempat meloloskan dua bug nyata di
Minggu 7 (`RangeError` token pendek, teks "belum tersedia" saat loading) karena
mata manusia membaca diff, bukan menjalankannya. Komentar review juga cenderung
berhenti di urusan spasi karena tidak ada formatter yang menegakkan aturan.

## Solusi

`.github/workflows/ci.yml`:

```yaml
on: [pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    defaults: { run: { working-directory: 08-week-8-mid-project-review/campus_notify } }
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed lib test
      - run: flutter analyze
      - run: flutter test
```

Urutan sengaja: format → analyze → test. Gagal cepat di hal termurah.

## Cara uji

Lokal, sebelum menunggu GitHub:

```bash
cd campus_notify
dart format --output=none --set-exit-if-changed lib test   # 0 changed
flutter analyze                                            # No issues found!
flutter test                                               # +14 All tests passed!
```

Ketiga langkah dijalankan dan lulus pada commit ini, jadi workflow tidak akan
merah pada PR pertamanya.

## Komentar review

> **reviewer (saran)** — urutan job
> Format lebih murah dari analyze, analyze lebih murah dari test. Urutkan begitu
> supaya PR kotor gagal dalam hitungan detik.

> **reviewer (saran)** — `working-directory`
> Repo ini berisi banyak folder minggu. Tanpa `working-directory` yang eksplisit,
> `flutter pub get` akan jalan di akar repo dan gagal.

> **penulis (resolved)**
> Urutan dan `working-directory` diterapkan; workflow diverifikasi lokal dengan
> perintah yang sama persis.

## Status

Approve, merge ke `develop`.