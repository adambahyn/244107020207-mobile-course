# Audit kebersihan commit & cabang

## Sebelum (Minggu 1–7)

```
3046045 | p
c08db37 | Hapus gitignore dan AGENTS.md
492c6d1 | chore: snapshot sebelum refactor Clean Architecture (week 7)
2363cd4 | Week 7: refactor campus_notify ke feature-first Clean Architecture (analyze bersih, 10 test, 3 grep nol) + docs AI challenge + builder laporan
e1a149f | Week 7: laporan jobsheet dibangun ulang lewat WordCraft (...), cek_laporan 0 gagal; screenshot after-* dari APK refactor
046e317 | Week 7: isi laporan jadi model murni (isi_laporan7.py), README cara bangun laporan
```

Masalah yang terlihat: satu commit berisi beberapa keputusan sekaligus
(refactor + docs + builder laporan), subjek panjang tanpa tipe, dan commit
`p` yang tidak menjelaskan apa pun.

## Sesudah (Minggu 8, Conventional Commits)

```
chore(week8): salin proyek Minggu 7 sebagai baseline review paruh semester
fix(core): maskToken tidak lagi RangeError untuk token < 12 karakter
fix(announcements): deep link tampilkan loader, bukan teks 'belum tersedia'
chore(ci): workflow verify untuk PR (format, analyze, test)
```

Aturan yang dipakai sekarang:

- `tipe(lingkup): kalimat perintah` — `fix`, `feat`, `chore`, `test`, `docs`.
- Satu commit = satu alasan berubah. Refactor + fitur + dokumen tidak digabung.
- Baris isi menjelaskan **kenapa**, bukan mengulang diff.
- Commit yang mereferensikan issue menulis `Refs: issue #n`.

## Ukuran PR

| PR | Berkas | Baris (+/−) | Waktu review wajar |
|----|--------|-------------|--------------------|
| `fix/mask-token-range` | 2 | +8 / −2 | < 5 menit |
| `fix/announcement-loading-state` | 2 | +95 / −30 | < 15 menit |
| `chore/ci-workflow` | 1 | +20 / −0 | < 5 menit |

Tidak ada PR di atas 300 baris, sesuai batas pada modul.

## Kebiasaan cabang

- `main` = rilis mingguan (hanya menerima merge dari `develop`).
- `develop` = integrasi; baseline Minggu 8 dibuat di sini.
- `feature/*` dan `fix/*` = umur < 3 hari, di-rebase ke `develop` sebelum PR.

## Kesalahan yang sempat terjadi (dan dibetulkan)

`git add -A <folder>` ikut men-stage penghapusan berkas codelab Minggu 6 yang
sedang tidak ada di disk, sehingga commit "fix(core)" berisi 1.539 baris
penghapusan yang tidak berhubungan. Commit di-`reset`, berkas dipulihkan dengan
`git checkout -- 06-week-6-...`, lalu commit diulang dengan dua path eksplisit.
Pelajaran: `git add -A` dilarang untuk commit kecil; sebut berkasnya.