# AI Prompt Challenge — Minggu 5

## Prompt yang dipakai

```
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.
```

## Output awal AI (ringkas, apa adanya)

> Untuk preferensi tema, SharedPreferences sudah cukup: data 1 key-value kecil,
> tidak butuh query, membaca < 1 ms. Kalau pakai SQLite untuk ini, Anda menambah
> dependensi tanpa manfaat.
>
> Untuk catatan, sqflite. Alasannya: 1000+ baris butuh `ORDER BY updated_at`,
> `WHERE dirty = 1`, dan `COUNT(*)` — SharedPreferences tidak punya query,
> jadi setiap filter berarti memuat seluruh koleksi ke memori lalu menyaring di
> Dart. SharedPreferences juga tidak punya transaksi, jadi dua penulisan
> bersamaan bisa saling menimpa.
>
> Hive: cepat dan ringan, tapi tanpa query relasional; filter dirty tetap manual.
> Drift: type-safe dan reaktif (`watch()` mengembalikan stream), tapi menambah
> build_runner + generator, jadi boilerplate dan waktu build naik.
>
> Skema sqflite untuk 1000+ catatan:
> ```sql
> CREATE TABLE notes (
>   id         INTEGER PRIMARY KEY AUTOINCREMENT,
>   title      TEXT    NOT NULL,
>   body       TEXT    NOT NULL DEFAULT '',
>   updated_at TEXT    NOT NULL,        -- ISO-8601 UTC, dipakai LWW
>   dirty      INTEGER NOT NULL DEFAULT 1
> );
> CREATE INDEX idx_notes_dirty      ON notes(dirty);
> CREATE INDEX idx_notes_updated_at ON notes(updated_at);
> ```
> Indeks pada `dirty` penting: tanpa itu, `countDirty()` dan `markAllSynced()`
> jadi full table scan saat catatan bertambah.
>
> Rekomendasi: SharedPreferences untuk preferensi, sqflite untuk catatan.

## Verifikasi checklist codelab

| Pertanyaan verifikasi | Temuan |
|---|---|
| AI menaruh daftar catatan di SharedPreferences? | Tidak. AI menolaknya dengan argumen query + ukuran koleksi. Klaim didukung tabel skema, bukan afirmasi kosong. |
| Skema mendukung antrean sync (`dirty` / `updated_at`)? | Ya. Kedua kolom ada, plus indeks `idx_notes_dirty` — detail yang saya tidak minta tapi memang dibutuhkan. |
| Klaim "real-time" didukung stream? | AI tidak mengklaim real-time untuk sqflite. Ia menyebut Drift `watch()` sebagai satu-satunya opsi stream. Klaim itu benar per dokumentasi Drift. |
| Estimasi boilerplate masuk akal setelah dicoba? | Ya — `flutter pub add sqflite path` selesai tanpa konfigurasi apa pun; Drift butuh `build_runner` + `part` file, yang saya konfirmasi sendiri dari [drift.simonbinder.eu/setup](https://drift.simonbinder.eu/setup/). |
| Keputusan final | Sama dengan AI, tapi saya tambah satu hal yang AI lewatkan (lihat bawah). |

## Yang AI lewatkan

**`openDb` harus bisa di-inject.** Output awal AI menaruh `openDatabase(...)`
langsung di dalam method repository. Akibatnya `NoteRepository` tidak bisa diuji
tanpa plugin sqflite sungguhan — dan sqflite tidak jalan di `flutter test` di
mesin desktop (missing plugin channel). Perbaikan: constructor menerima
`Future<Database> Function() openDb`, dengan default tetap membuka DB asli.

**`fromMap` harus tahan tipe salah.** AI menulis `map['id'] as num?`. Cast
nullable hanya menoleransi `null` — kalau nilainya `List` (kolom korup, migrasi
gagal), `TypeError` dilempar dan seluruh daftar catatan gagal render, bukan cuma
satu baris rusak. Perbaikannya `is`-check, bukan cast.

## Keputusan final

| Kebutuhan | Pilihan | Alasan teknis |
|---|---|---|
| Preferensi tema (1 nilai bool) | SharedPreferences | Key-value, baca tulis < 1 ms, tanpa query. SQLite di sini = dependensi tanpa manfaat. |
| Catatan (1000+ baris, CRUD + antrean sync) | sqflite | `ORDER BY updated_at`, `WHERE dirty = 1`, `COUNT(*)` — semua jadi SQL, bukan loop Dart. Transaksi tersedia. |
| Hive | Ditolak | Cepat, tapi tanpa query; filter `dirty` manual seperti SharedPreferences. |
| Drift | Ditolak untuk tugas ini | Type-safe + stream reaktif, tapi menambah generator + waktu build. Migrasi bisa ditunda ke minggu lain. |
