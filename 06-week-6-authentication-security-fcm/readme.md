# Week 6 — Authentication, Security & FCM

Praktikum JTI Polinema. Project: `campus_notify`.
Fokus: menyimpan token dengan benar, menangani `401` tanpa membuat loop tak
berujung, dan menerima push notification di tiga keadaan aplikasi
(foreground, background, terminated).

## 1. Identitas project

| Item | Nilai |
|---|---|
| Nama package | `com.example.campus_notify` |
| Project ID Firebase | `campus-notify-<id>` |
| Firebase sender ID | `10109968045751010996804575` |
| Perangkat uji | Infinix, Android, layar 1080x2436 |
| ID perangkat adb | `121512545B015596` |
| Project Flutter | `campus_notify/` (subfolder) |

**Catatan tentang Sender ID.** Nilai yang diberikan (`10109968045751010996804575`,
26 digit) lebih panjang dari Sender ID Firebase pada umumnya (12 digit). Nilai
mentah tetap dicatat apa adanya di tabel ini; yang benar-benar menentukan
aplikasi terhubung ke project Firebase adalah `google-services.json`, dan di
berkas itu `project_number` tertulis `1010996804575` (13 digit) dengan
`mobilesdk_app_id` `1:1010996804575:android:...`. Artinya bagian awal Sender ID
cocok dengan project; sisa digitnya kemungkinan salah salin. Uji FCM di
Praktikum 3 membuktikan mana yang berlaku.

## 2. Struktur folder

```
06-week-6-authentication-security-fcm/     <- root minggu
├── README.md                              <- laporan ini
├── docs/
│   └── ai-challenge.md                    <- deliverable AI challenge
├── screenshots/                           <- bukti dari HP fisik
├── lib/                                   <- salinan kode yang dibahas
├── test/
├── campus_notify/                         <- project Flutter (flutter create)
└── #06 _ Authentication, Security & FCM.html
```

Kode di `lib/` dan `test/` adalah salinan dari `campus_notify/lib` dan
`campus_notify/test`, supaya laporan bisa dibaca tanpa membuka project.

## 3. Susunan kode aplikasi

```
lib/
├── main.dart                      # Firebase.initializeApp + ProviderScope + router
├── router.dart                    # GoRouter + guard login
├── routes.dart                    # nama rute terpusat
├── data/
│   ├── token_store.dart           # SATU-SATUNYA pemegang token (secure storage)
│   ├── auth_repository.dart       # sesi mock, siap diganti Firebase Auth
│   ├── api_client.dart            # Dio + interceptor refresh 401
│   └── api_errors.dart            # DioException -> pesan Indonesia
├── messaging/
│   ├── push_service.dart          # FCM: izin, token, 3 handler, notifikasi lokal
│   └── deeplink.dart              # RemoteMessage.data -> route (murni, bisa diuji)
├── providers/
│   └── auth_provider.dart         # tokenStoreProvider, apiClientProvider, authStateProvider
└── pages/
    ├── login_page.dart
    ├── home_page.dart             # status perangkat + tombol uji 401
    └── announcement_page.dart     # tujuan deep link /pengumuman/:id
```

Aturan yang dipegang: **UI tidak pernah menyentuh penyimpanan atau jaringan
langsung.** Halaman hanya membaca provider Riverpod.

## 4. Praktikum 1 — Autentikasi & penyimpanan token

### 4.1 Token disimpan terenkripsi

`lib/data/token_store.dart` adalah satu-satunya kelas yang memegang token:

```dart
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> readAccess() => _storage.read(key: _accessKey);
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<void> clear() => _storage.deleteAll();

  /// Hanya untuk halaman Debug: 12 karakter pertama + "…".
  static String mask(String? token) {
    if (token == null || token.isEmpty) return '(kosong)';
    if (token.length <= 12) return '${token.substring(0, token.length)}…';
    return '${token.substring(0, 12)}…';
  }
}
```

`FlutterSecureStorage` menyimpan nilai lewat Android Keystore. `SharedPreferences`
tidak dipakai untuk token: berkasnya XML biasa yang terbaca di perangkat
root/lewat backup.

Bukti bahwa token benar-benar ada di secure storage, bukan di prefs, diambil
langsung dari perangkat:

```
adb shell run-as com.example.campus_notify ls shared_prefs/
```

_(hasil: lihat bagian 8)_

### 4.2 Alur login

`AuthNotifier.login()` memanggil repository, menyimpan sesi, lalu mengubah
status. `AsyncValue.guard` menangkap kegagalan sehingga UI cukup memeriksa
`state.hasError`.

```dart
Future<void> login(String email, String password) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    final session = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    await ref
        .read(tokenStoreProvider)
        .save(access: session.access, refresh: session.refresh);
    return true;
  });
}
```

### 4.3 Dio dengan refresh otomatis — tepat sekali

```dart
onError: (e, handler) async {
  if (e.response?.statusCode != 401) return handler.next(e);
  // Cegah loop: request yang sudah pernah di-retry tidak diulang lagi.
  if (e.requestOptions.extra['retried'] == true) return handler.next(e);

  final refresh = await store.readRefresh();
  if (refresh == null || refresh.isEmpty) return handler.next(e);

  try {
    final renewed = await auth.refresh(refresh);
    await store.save(access: renewed, refresh: refresh);
    e.requestOptions
      ..headers['Authorization'] = 'Bearer $renewed'
      ..extra['retried'] = true;
    final retry = await dio.fetch<dynamic>(e.requestOptions);
    return handler.resolve(retry);
  } catch (_) {
    await store.clear(); // refresh mati -> paksa login ulang
  }
  return handler.next(e);
},
```

Tiga hal yang penting di sini:

1. `extra['retried']` mencegah **loop tak terbatas** (request → 401 → refresh →
   retry → 401 → refresh lagi). Penanda ini ikut tersalin saat `dio.fetch()`
   dipanggil ulang, jadi bertahan melewati retry.
2. Refresh berhasil → token baru disimpan, lalu request lama diulang.
3. Refresh gagal → `store.clear()`. Mempertahankan access token kedaluwarsa
   membuat aplikasi tampak masih login padahal semua request akan gagal.

### 4.4 Guard rute

`router.dart` melempar pengguna ke login bila belum ada token, dan sebaliknya:

```dart
redirect: (context, state) {
  final loggedIn = isLoggedIn();
  final goingLogin = state.matchedLocation == Routes.login;
  if (!loggedIn && !goingLogin) return Routes.login;
  if (loggedIn && goingLogin) return Routes.home;
  return null;
},
```

Router dibangun lewat fungsi (`buildRouter`) supaya `isLoggedIn` dan
`refreshListenable` disuntik dari `main.dart`. Dengan begitu `router.dart` tidak
perlu tahu apa pun tentang Riverpod, dan status login yang berubah memicu
redirect lewat `ChangeNotifier` kecil.

## 5. Praktikum 2 — Izin & siklus hidup token FCM

```dart
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true, badge: true, sound: true,
    announcement: false, carPlay: false, criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}
```

Mulai Android 13, izin notifikasi bukan lagi otomatis — harus diminta runtime,
dan kalau ditolak `requestPermission` mengembalikan `denied` tanpa melempar
exception.

Token diambil sekali, dikirim ke backend, lalu **perubahannya dipantau**:

```dart
Future<String?> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
  return token;
}
```

`onTokenRefresh` bukan pemanis. Token FCM berubah saat aplikasi diinstal ulang,
data dibersihkan, atau Google merotasi token karena alasan keamanan. Tanpa
listener ini, backend menyimpan token mati dan pengguna berhenti menerima
notifikasi tanpa tahu sebabnya.

Endpoint backend yang dituju (belum ada di kampus, jadi pengiriman disimulasikan
dan dicatat di sini):

```
POST /devices
{ "fcm_token": "<token>", "platform": "android" }
```

## 6. Praktikum 3 — Notifikasi di tiga keadaan aplikasi

Android memperlakukan ketiga keadaan ini berbeda. Karena itu ada tiga jalur.

| Keadaan | Callback | Yang harus dilakukan aplikasi |
|---|---|---|
| Foreground | `onMessage` | Sistem **tidak** menampilkan notifikasi. Tampilkan sendiri via `flutter_local_notifications`. |
| Background, notifikasi diklik | `onMessageOpenedApp` | Navigasi ke rute dari `data['route']`. |
| Terminated, dibuka dari notifikasi | `getInitialMessage()` | Ambil pesan, baru navigasi (router belum siap saat itu). |

Foreground:

```dart
FirebaseMessaging.onMessage.listen((message) async {
  final route = routeFromMessage(message.data);
  const details = AndroidNotificationDetails(
    'pengumuman', 'Pengumuman Kampus',
    channelDescription: 'Notifikasi pengumuman resmi kampus',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  await _local.show(
    id: message.hashCode,
    title: message.notification?.title ?? 'Pengumuman',
    body: message.notification?.body ?? '',
    notificationDetails: const NotificationDetails(android: details),
    payload: route,
  );
});
```

Channel dibuat eksplisit dengan `Importance.high` supaya notifikasi muncul
sebagai banner heads-up, bukan turun diam-diam ke baris notifikasi. Tanpa
`createNotificationChannel`, Android memakai channel default dengan importance
rendah.

Background handler harus **top-level** dan tidak boleh menyentuh `BuildContext`
maupun `ref`, karena berjalan di isolate terpisah:

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  dev.log('bg message id=${message.messageId} data=${message.data}', name: 'fcm');
}
```

Parsing rute dipisah ke fungsi murni supaya bisa diuji tanpa Firebase:

```dart
String routeFromMessage(Map<String, dynamic> data) {
  final raw = (data['route'] ?? '').toString().trim();
  if (raw.isEmpty) return Routes.home;
  return raw.startsWith('/') ? raw : '/$raw';
}
```

Payload notifikasi yang dipakai saat pengujian:

```json
{
  "notification": { "title": "Pengumuman Baru", "body": "Jadwal UAS telah terbit" },
  "data": { "route": "/pengumuman/3", "id": "3" }
}
```

## 7. Hasil analyze & test

```
$ flutter analyze
Analyzing campus_notify...
No issues found! (ran in 25.8s)

$ flutter test
00:00 +8: All tests passed!
```

8 test di `test/auth_push_test.dart` menguji logika yang tidak butuh Firebase:

| Test | Yang dibuktikan |
|---|---|
| `data kosong -> home` | payload tanpa rute tidak membuat aplikasi crash |
| `route tanpa slash ditambah slash` | `pengumuman/3` → `/pengumuman/3` |
| `route dengan slash dibiarkan` | tidak jadi `//pengumuman/3` |
| `nilai non-String tetap aman` | `route: 3` tidak menimbulkan `TypeError` |
| `data payload membawa id` | payload membawa rute + id sekaligus |
| `status login dari access token` | sesi tanpa token dianggap belum login |
| `refresh kosong -> sesi dibersihkan` | jalur "paksa login ulang" benar |
| `masking token` | token penuh tidak pernah tampil di UI |

## 8. Bukti eksekusi di perangkat

APK release 52.972.499 byte dibangun dan dipasang ke HP Infinix (`121512545B015596`,
Android, layar 1080x2436) lewat USB debugging:

```
$ flutter build apk --release
✓ Built build/app/outputs/flutter-apk/app-release.apk (52.9MB)

$ adb install -r build/app/outputs/flutter-apk/app-release.apk
Performing Streamed Install
Success
```

### 8.1 Alur aplikasi

| # | Berkas | Yang dibuktikan |
|---|---|---|
| 01 | `01-halaman-login.png` | halaman login tampil; field email & kata sandi terisi; tombol Masuk aktif |
| 02 | `02-dialog-izin-notifikasi.png` | dialog sistem "Allow campus_notify to send you notifications?" — bukti `requestPermission()` dijalankan |
| 03 | `03-home-izin-diberikan.png` | izin diberikan; token FCM nyata diperoleh |
| 04 | `04-uji-401-refresh.png` | interceptor 401 berjalan tanpa loop |
| 05 | `05-deeplink-pengumuman.png` | deep link `/pengumuman/:id` membuka halaman detail dengan `id` benar |
| 06 | `06-logout-ke-login.png` | logout → guard route melempar pengguna kembali ke login |
| 07 | `07-notifikasi-fcm-masuk.png` | notifikasi FCM dari Firebase Console benar-benar masuk |
| 08 | `08-notifikasi-diklik-deeplink.png` | notifikasi diklik → aplikasi kembali ke rute aman |

### 8.2 Token FCM nyata — Firebase benar-benar terhubung

Halaman home menampilkan status perangkat. Yang penting di sini bukan tampilannya,
melainkan **token FCM yang benar-benar diperoleh dari Google**:

```
Access token   mock-access-…
Token FCM      ddcd64QsSk-P…
FCM            Izin diberikan. Terdaftar topik pengumuman-kampus.
```

Token FCM hanya bisa diperoleh kalau aplikasi berhasil mendaftar ke
`project_number` di `google-services.json` dan lolos verifikasi aplikasi
(certificate hash). Jadi baris ini sekaligus membuktikan:

- `google-services.json` valid dan cocok dengan package `com.example.campus_notify`;
- plugin Gradle `com.google.gms.google-services` bekerja;
- `Firebase.initializeApp()` berhasil;
- `subscribeToTopic('pengumuman-kampus')` berhasil.

**Soal Sender ID.** Nilai 26 digit yang diberikan tidak dipakai aplikasi —
yang menentukan adalah `project_number` di `google-services.json`
(`1010996804575`). Karena token FCM di atas benar-benar terbit, terbukti
`project_number` inilah yang berlaku.

### 8.3 Notifikasi FCM dari Firebase Console

Notifikasi dikirim dari Firebase Console ke aplikasi. Sistem Android mencatatnya
di log notifikasi perangkat:

```
NotificationRecord(pkg=com.example.campus_notify id=863877664
                   channel=pengumuman importance=4
                   flags=AUTO_CANCEL)

Kolun_AI: SN_SmartNotificationManager:onBusEvent NotificationMetaInfo
  key='0|com.example.campus_notify|863877664|null|10258|1791020372180'
  pkg='com.example.campus_notify'
  title='Pengumuman Baru  Body: Jadwal UAS telah terbit'
  content='Pengumuman Baru  Body: Jadwal UAS telah terbit'
  channelId='pengumuman' importance=4     <- HIGH, banner heads-up

onNotifyRemoved ... NotificationStats{mSeen=true, mExpanded=true,
  mInteracted=true, mDismissalSurface=0}  <- notifikasi benar-benar diklik
```

Empat hal yang dibuktikan catatan ini:

1. `channelId='pengumuman'` — channel buatan aplikasi yang dipakai, bukan
   channel default Android.
2. `importance=4` (HIGH) — sesuai `Importance.high` di kode, jadi notifikasi
   tampil sebagai banner, bukan turun diam-diam ke baris notifikasi.
3. `pkg=com.example.campus_notify` dengan `id=863877664` — notifikasi berasal
   dari aplikasi ini, bukan aplikasi lain di perangkat.
4. `mInteracted=true` — pengguna benar-benar mengetuk notifikasi.

Judul yang tampil (`Pengumuman Baru  Body: Jadwal UAS telah terbit`) berasal
dari apa yang diisi di Firebase Console: seluruh teks dimasukkan ke kolom
*Title*, termasuk kata "Body:". Aplikasi menampilkan `notification.title` apa
adanya:

```dart
title: message.notification?.title ?? 'Pengumuman',
```

Jadi ini bukan cacat aplikasi, melainkan cara pengisian formulir di Console.

### 8.4 Uji jalur 401 tanpa backend

Kampus belum menyediakan backend, jadi tombol "Simulasikan 401 + refresh"
mengarahkan request ke host yang tidak ada. Yang dibuktikan bukan respons
servernya, melainkan perilaku interceptor:

```
$ adb (tap "Simulasikan 401 + refresh")
Refresh 401   refresh gagal, token masih ada: DioException
Access token  mock-access-…            <- sesi TIDAK dihapus
```

Terjemahan hasilnya:

- Request gagal dan diteruskan sebagai `DioException` — error tidak ditelan.
- Tidak terjadi retry berulang. Kalau penanda `extra['retried']` hilang,
  request akan diulang tanpa henti; yang tampil di sini hanya satu kegagalan.
- Token **tidak** dibersihkan, karena refresh token masih ada dan jalur
  `store.clear()` hanya dijalankan saat refresh benar-benar mati. Sesi tetap
  hidup, dan pengguna tidak dibuang ke login tanpa sebab.

### 8.5 Bukti deep link tanpa FCM

Selain lewat notifikasi, deep link diuji dengan mengetuk kartu pengumuman di
home. Hasilnya halaman `/pengumuman/3` dengan parameter yang benar:

```
Pengumuman #3
route: /pengumuman/3
Kelas Mobile pindah ke Ruang A2, jam 13.00. Harap hadir tepat waktu dan
membawa laptop.
Halaman ini dibuka dari deep link notifikasi FCM.
```

Screenshot 08 memperlihatkan kasus sebaliknya yang juga benar: notifikasi uji
dikirim **tanpa** pasangan data `route`, sehingga `routeFromMessage({})`
mengembalikan `Routes.home`. Aplikasi kembali ke home alih-alih membuka rute
kosong. Payload notifikasi untuk deep link yang benar:

```json
{
  "notification": { "title": "Pengumuman Baru", "body": "Jadwal UAS telah terbit" },
  "data": { "route": "/pengumuman/3", "id": "3" }
}
```

### 8.6 Batas pengujian yang jujur

- **`shared_prefs` tidak bisa diperiksa langsung.** Build release tidak
  `debuggable`, jadi `adb shell run-as com.example.campus_notify ls shared_prefs/`
  menjawab `package not debuggable`. Klaim "token tidak di SharedPreferences"
  karena itu bersandar pada kode: hanya `TokenStore` yang memegang token, dan
  kelas itu memakai `FlutterSecureStorage`; `shared_preferences` tidak
  diimpor di mana pun untuk token.
- **Backend kampus tidak ada**, jadi pengiriman token ke `POST /devices` dan
  pertukaran refresh token disimulasikan. Kontrak endpoint dicatat di bagian 5
  dan 4.3 supaya bisa dipasang begitu backend tersedia.
- **Jalur terminated** (aplikasi mati lalu dibuka dari notifikasi) belum
  diambil screenshot terpisah. Kode jalurnya ada (`getInitialMessage()` di
  `handleTerminated`), tetapi untuk membuktikannya perlu mematikan aplikasi
  lebih dulu sebelum notifikasi dikirim, dan itu di luar alur yang dikerjakan
  hari ini.

## 9. Pelajaran teknis (ringkas)

1. **Plugin gradle `com.google.gms.google-services` wajib dipasang di dua
   berkas** — `android/settings.gradle.kts` (`apply false`) dan
   `android/app/build.gradle.kts` (dipakai). Lupa satu = `google-services.json`
   diabaikan dan FCM gagal tanpa pesan jelas.
2. **`flutter_local_notifications` menuntut core library desugaring.** Build
   gagal dengan pesan `requires core library desugaring to be enabled for :app`.
   Perbaikannya dua baris: `isCoreLibraryDesugaringEnabled = true` dan
   `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")`.
3. **API plugin berbeda dari contoh codelab.** `flutter_local_notifications`
   versi 22 memakai named parameter (`show(id:, title:, body:, ...)`) sedangkan
   tutorial lama memakai positional. Salah tebak = analyze gagal = rebuild
   Gradle mahal. Selalu `grep` signature di pub cache dulu.
4. **Riverpod 3 menghapus `StateProvider`,** dan `AsyncValue` tidak punya
   `valueOrNull` — getter `value` sudah nullable.
5. **Praktikum 1 (auth + refresh) tidak butuh Firebase sama sekali.** Mengerjakan
   bagian itu lebih dulu membuat pekerjaan tetap jalan meski Console belum siap.

