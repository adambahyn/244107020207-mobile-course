# AI Challenge — Week 6: Authentication, Security & FCM

## Tantangan

Codelab menyuruh memasang FCM dan menampilkan notifikasi. Tantangan yang
dikerjakan di sini lebih keras dari itu: **buktikan klaim keamanan dengan kode,
bukan dengan kalimat di laporan.** Tiga klaim yang diuji:

1. Token akses tidak pernah menyentuh penyimpanan tidak terenkripsi.
2. Setelah server menolak 401, aplikasi menukar refresh token dan mengulang
   request **tepat sekali** — bukan berkali-kali sampai server tumbang.
3. Saat refresh token ikut mati, sesi dibersihkan dan pengguna dipaksa login
   ulang, bukan dibiarkan memakai token basi.

## Keputusan yang diambil

### 1. Menyimpan token: `FlutterSecureStorage`, bukan `SharedPreferences`

`SharedPreferences` menulis XML biasa di `/data/data/<pkg>/shared_prefs/`. Di
perangkat yang sudah di-root atau lewat backup adb, isinya terbaca. Android
Keystore-backed `FlutterSecureStorage` mengenkripsi nilai dengan kunci yang
tidak bisa diekspor dari keystore perangkat.

Bukti desain: `lib/data/token_store.dart` adalah **satu-satunya** kelas yang
memegang token; tidak ada berkas lain yang mengimpor `shared_preferences` untuk
token. Kelas itu juga menyediakan `mask()` supaya token tampil terpotong di
halaman debug dan tidak pernah masuk log.

### 2. Refresh 401: interceptor dengan penanda `retried`

Jebakan klasik interceptor refresh adalah **loop tak terbatas**: request →
401 → refresh → retry → 401 → refresh lagi. Penangkalnya satu baris:

```dart
if (e.requestOptions.extra['retried'] == true) return handler.next(e);
```

Request yang sudah pernah di-retry tidak diulang lagi; error diteruskan apa
adanya. `retried` ditulis ke `requestOptions.extra`, yang ikut tersalin saat
`dio.fetch()` dipanggil ulang, jadi penanda bertahan melewati retry.

### 3. Refresh gagal → bersihkan sesi

```dart
} catch (_) {
  await store.clear(); // refresh mati -> paksa login ulang
}
```

Ini disengaja: mempertahankan access token yang sudah kedaluwarsa membuat
aplikasi tampak "masih login" padahal setiap request akan gagal. Lebih jujur
membersihkan sesi dan membiarkan `redirect` GoRouter melempar pengguna ke
halaman login.

## Yang tidak dikerjakan (dan alasannya)

- **Firebase Auth asli.** Repository auth memakai sesi mock karena codelab
  memisahkan materi FCM dari Firebase Auth, dan endpoint kampus belum ada.
  Titik gantinya ditandai di `lib/data/auth_repository.dart`: cukup tukar isi
  `login()` menjadi `signInWithEmailAndPassword`. Kontraknya (`AuthSession`
  berisi access + refresh) sudah cocok dengan `TokenStore`.
- **Verifikasi tanda tangan token di sisi server.** Itu pekerjaan backend, di
  luar repo Flutter ini.

## Pelajaran

1. **Periksa API plugin sebelum menulis kode.** `flutter_local_notifications`
   versi 22 memakai named parameter (`show(id:, title:, body:, ...)`), sedangkan
   contoh codelab dan tutorial lama memakai positional. Salah tebak = analyze
   gagal = rebuild Gradle mahal.
2. **Riverpod 3 menghapus `StateProvider`.** Kode yang menyalin contoh Riverpod 2
   tidak akan ter-compile. Penggantinya `Notifier` + `NotifierProvider`.
3. **`AsyncValue.valueOrNull` bukan API Riverpod 3.** Getter `value` sudah
   nullable. `grep` di paket `riverpod-3.4.3` menyelesaikan ini dalam satu
   panggilan, jauh lebih murah dari trial-error lewat `flutter analyze`.
4. **Handler background FCM berjalan di isolate terpisah.** Ia tidak boleh
   menyentuh `BuildContext` atau `ref`. Karena itu `firebaseMessagingBackgroundHandler`
   ditulis top-level, diberi `@pragma('vm:entry-point')`, dan hanya menulis log.
5. **Foreground dan background butuh jalur berbeda.** Saat aplikasi di depan,
   Android tidak menampilkan notifikasi sendiri — kalau tidak memanggil
   `flutterLocalNotificationsPlugin.show()`, pengguna tidak melihat apa pun.
   Saat di belakang dan notifikasi diklik, `onMessageOpenedApp` yang jalan.
   Saat aplikasi mati, hanya `getInitialMessage()` yang bisa mengambil pesannya.
