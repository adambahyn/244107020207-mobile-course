import 'dart:developer' as dev;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'deeplink.dart';

/// Route tujuan dari notifikasi yang diklik SEBELUM router siap.
/// Dipakai untuk kasus foreground (banner lokal) dan terminated.
String? pendingDeepLink;

final _local = FlutterLocalNotificationsPlugin();

/// WAJIB top-level + @pragma('vm:entry-point'): berjalan di isolate terpisah,
/// jadi TIDAK boleh menyentuh BuildContext / Riverpod.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  dev.log(
    'bg message id=${message.messageId} data=${message.data}',
    name: 'fcm',
  );
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

/// Android 13+ / iOS wajib minta izin runtime.
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      // Klik banner lokal (state foreground) -> simpan route, router yang urus.
      pendingDeepLink = response.payload;
    },
  );

  // Channel eksplisit supaya importance tinggi (banner heads-up) tidak
  // didowngrade oleh default channel.
  const channel = AndroidNotificationChannel(
    'pengumuman',
    'Pengumuman Kampus',
    description: 'Notifikasi pengumuman resmi kampus',
    importance: Importance.high,
  );
  await _local
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

/// Ambil token, kirim ke backend, lalu pantau perubahan.
/// Listener onTokenRefresh WAJIB: tanpa itu backend menyimpan token basi
/// setelah reinstall / clear data / rotasi keamanan.
Future<String?> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
  return token;
}

Future<void> unsubscribeTopic() =>
    FirebaseMessaging.instance.unsubscribeFromTopic('pengumuman-kampus');

/// Foreground: sistem TIDAK menampilkan banner otomatis -> tampilkan manual.
/// Background diklik -> langsung navigasi.
void listenForeground(void Function(String route) go) {
  FirebaseMessaging.onMessage.listen((message) async {
    final route = routeFromMessage(message.data);
    const details = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
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

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(routeFromMessage(message.data));
  });
}

/// Terminated: aplikasi dimatikan lalu dibuka dari notifikasi.
Future<void> handleTerminated(void Function(String route) go) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) go(routeFromMessage(initial.data));
  if (pendingDeepLink != null) go(pendingDeepLink!);
}
