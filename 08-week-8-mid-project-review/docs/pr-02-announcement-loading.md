# PR: fix(announcements) — deep link tampilkan loader, bukan "belum tersedia"

Cabang: `fix/announcement-loading-state` → `develop` · Berkas: 2 · +95 / −30

## Masalah

`AnnouncementPage` membaca data lewat `state.value ?? []`:

```dart
final list = state.value ?? const <Announcement>[];
final item = index >= 0 ? list[index] : null;
final body = item?.body ?? 'Detail pengumuman #$id belum tersedia di data contoh.';
```

`FutureProvider` mengembalikan `AsyncLoading` pada frame pertama, dan `value`
masih `null`. Hasilnya: setiap deep link FCM yang dibuka menampilkan kalimat
"belum tersedia" selama beberapa ratus milidetik — persis pada momen pengguna
paling butuh isi pengumuman. Kegagalan jaringan juga tidak bisa dibedakan dari
"data tidak ada".

## Solusi

`state.when(loading:…, error:…, data:…)`:

- loading → `CircularProgressIndicator` ber-key `announcement-loading`;
- error → `messageOf(e)`, konsisten dengan `HomePage`;
- data → perilaku lama (isi body, tanggal, teks cadangan untuk id asing).

## Cara uji

1. `flutter analyze` → `No issues found!`
2. `flutter test` → `+14 All tests passed!` (11 lama + 2 baru; total 3 widget test baru di berkas ini)
3. Manual: kirim notifikasi uji FCM `/pengumuman/3`, halaman terbuka dengan isi
   pengumuman, bukan teks cadangan.

## Komentar review (reviewer → penulis)

> **reviewer (request changes)** — `presentation/pages/announcement_page.dart:17`
> Blocker: `state.value ?? []` menyamakan "sedang memuat" dengan "tidak ada".
> Tiga keadaan (`loading`/`error`/`data`) harus punya tampilan sendiri. Tolong
> tunjukkan test yang gagal pada kode lama, bukan hanya test yang lulus.

> **reviewer (saran)** — penyusunan widget
> `messageOf` sudah ada di `core/format.dart` dan dipakai `HomePage`; jangan
> menulis format pesan error baru di sini. Konsisten satu pintu.

> **reviewer (saran)** — test
> Tambahkan kasus id yang **ada** (bukan hanya id asing), supaya penataan ulang
> tidak diam-diam merusak jalur bahagia.

> **reviewer (saran arsitektur)** — `presentation/pages/announcement_page.dart:16`
> Halaman detail membaca daftar penuh lalu mencari id. Kontrak yang benar adalah
> use case `GetAnnouncementById` di `domain/usecases/`, supaya presentation tidak
> bergantung pada bentuk provider dan tidak mengunduh seluruh daftar hanya untuk
> satu pengumuman. Tidak diminta di PR ini karena mengubah kontrak domain;
> dicatat sebagai issue paruh kedua.

> **penulis (resolved)**
> `state.when` dipakai; error memakai `messageOf`; tiga widget test ditulis
> (loading, id asing, id ada + tanggal 27 September 2026). Test loading gagal
> pada kode lama, lulus setelah perubahan. `flutter analyze` bersih. Temuan
> arsitektur dicatat di `docs/review-checklist.md` sebagai utang teknis.

## Catatan desain

Import `domain/entities/announcement.dart` dihapus karena `list` kini
diinferensi dari `data:`; `flutter analyze` menandai import tak terpakai itu.

## Status

Approve, merge squash ke `develop`.