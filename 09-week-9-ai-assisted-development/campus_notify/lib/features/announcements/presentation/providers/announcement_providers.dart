import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/announcement_local_source.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcements.dart';

/// Wiring fitur announcements: data -> domain -> presentation.
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => const AnnouncementRepositoryImpl(source: AnnouncementLocalSource()),
);

final getAnnouncementsProvider = Provider<GetAnnouncements>(
  (ref) => GetAnnouncements(ref.watch(announcementRepositoryProvider)),
);

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(getAnnouncementsProvider).call();
  final failure = result.failure;
  if (failure != null) throw Exception(failure.message);
  return result.items;
});
