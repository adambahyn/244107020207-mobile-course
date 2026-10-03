// Rute terpusat. Dipakai GoRouter DAN deep link FCM supaya tidak ada string liar.
class Routes {
  const Routes._();

  static const login = '/login';
  static const home = '/';
  static const announcement = '/pengumuman/:id';

  static String announcementById(String id) => '/pengumuman/$id';
}
