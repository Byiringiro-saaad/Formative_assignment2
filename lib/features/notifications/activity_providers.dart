import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/incident.dart';
import '../../data/models/status_change.dart';
import '../auth/auth_providers.dart';
import '../incidents/incident_providers.dart';

/// A status change made by someone else on one of my reports.
class ActivityItem {
  const ActivityItem({required this.incident, required this.change});

  final Incident incident;
  final StatusChange change;
}

/// Updates staff made to the signed-in student's reports, newest first.
/// For staff, it lists newly submitted reports across campus instead.
final activityProvider = Provider<List<ActivityItem>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return const [];

  final List<ActivityItem> items;
  if (user.isStaff) {
    final all = ref.watch(allIncidentsProvider).value ?? const <Incident>[];
    items = [
      for (final i in all)
        if (i.history.isNotEmpty)
          ActivityItem(incident: i, change: i.history.first),
    ];
  } else {
    final mine = ref.watch(myIncidentsProvider).value ?? const <Incident>[];
    items = [
      for (final i in mine)
        for (final h in i.history)
          if (h.changedBy != user.uid) ActivityItem(incident: i, change: h),
    ];
  }
  items.sort((a, b) => b.change.changedAt.compareTo(a.change.changedAt));
  return items.take(50).toList();
});

/// When the user last opened the activity screen in this session. Activity
/// newer than this shows the unread dot on the bell.
class LastSeenNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void markSeen([DateTime? at]) => state = at ?? DateTime.now();
}

final lastSeenActivityProvider = NotifierProvider<LastSeenNotifier, DateTime?>(
  LastSeenNotifier.new,
);

final unreadActivityCountProvider = Provider<int>((ref) {
  final seen = ref.watch(lastSeenActivityProvider);
  final items = ref.watch(activityProvider);
  if (seen == null) return items.length;
  return items.where((a) => a.change.changedAt.isAfter(seen)).length;
});
