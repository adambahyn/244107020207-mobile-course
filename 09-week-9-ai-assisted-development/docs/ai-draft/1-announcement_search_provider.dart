import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/announcement.dart';

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(SearchQuery.new);

// Turunan murni dari announcementsProvider — widget tak pernah sentuh repository.
final filteredAnnouncementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final items = await ref.watch(announcementsProvider.future);
  final q = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (q.isEmpty) return items;
  return items.where((a) => a.title.toLowerCase().contains(q)).toList();
});
