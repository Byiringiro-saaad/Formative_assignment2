import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../data/models/app_user.dart';
import '../../data/models/incident.dart';
import '../../data/models/incident_category.dart';
import '../../data/models/incident_status.dart';
import '../auth/auth_providers.dart';

/// Every incident on campus, newest first, kept live from Firestore.
///
/// Rebuilt when the signed-in user changes, so a listener that failed with
/// "permission denied" after sign-out is replaced on the next sign-in.
final allIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.watch(incidentRepositoryProvider).watchAll();
});

/// Incidents reported by the signed-in user.
final myIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u.value?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.watch(incidentRepositoryProvider).watchByReporter(uid);
});

/// One incident by id, live.
final incidentProvider = StreamProvider.autoDispose.family<Incident?, String>((
  ref,
  id,
) {
  final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  if (uid == null) return Stream.value(null);
  return ref.watch(incidentRepositoryProvider).watchById(id);
});

/// A reporter's profile, used by staff to see who filed an anonymous report.
/// The security rules only let staff read other users' profiles.
final reporterProfileProvider = StreamProvider.autoDispose
    .family<AppUser?, String>(
      (ref, uid) => ref.watch(userRepositoryProvider).watchUser(uid),
    );

/// Counts shown on the summary tiles.
class IncidentSummary {
  const IncidentSummary({
    required this.total,
    required this.submitted,
    required this.inProgress,
    required this.resolved,
  });

  factory IncidentSummary.of(List<Incident> incidents) {
    int count(IncidentStatus s) => incidents.where((i) => i.status == s).length;
    return IncidentSummary(
      total: incidents.length,
      submitted: count(IncidentStatus.submitted),
      inProgress: count(IncidentStatus.inProgress),
      resolved: count(IncidentStatus.resolved),
    );
  }

  static const empty = IncidentSummary(
    total: 0,
    submitted: 0,
    inProgress: 0,
    resolved: 0,
  );

  final int total;
  final int submitted;
  final int inProgress;
  final int resolved;
}

final mySummaryProvider = Provider<IncidentSummary>(
  (ref) =>
      ref.watch(myIncidentsProvider).whenOrNull(data: IncidentSummary.of) ??
      IncidentSummary.empty,
);

final campusSummaryProvider = Provider<IncidentSummary>(
  (ref) =>
      ref.watch(allIncidentsProvider).whenOrNull(data: IncidentSummary.of) ??
      IncidentSummary.empty,
);

/// Search text and filters for the reports list.
class IncidentFilter {
  const IncidentFilter({
    this.query = '',
    this.status,
    this.category,
    this.mineOnly = false,
  });

  final String query;
  final IncidentStatus? status;
  final IncidentCategory? category;
  final bool mineOnly;

  bool get isActive =>
      query.trim().isNotEmpty || status != null || category != null;

  bool accepts(Incident i, {String? uid}) =>
      (status == null || i.status == status) &&
      (category == null || i.category == category) &&
      (!mineOnly || i.reporterId == uid) &&
      i.matches(query);

  IncidentFilter copyWith({
    String? query,
    IncidentStatus? Function()? status,
    IncidentCategory? Function()? category,
    bool? mineOnly,
  }) => IncidentFilter(
    query: query ?? this.query,
    status: status == null ? this.status : status(),
    category: category == null ? this.category : category(),
    mineOnly: mineOnly ?? this.mineOnly,
  );
}

class IncidentFilterNotifier extends Notifier<IncidentFilter> {
  @override
  IncidentFilter build() => const IncidentFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setStatus(IncidentStatus? status) =>
      state = state.copyWith(status: () => status);

  void setCategory(IncidentCategory? category) =>
      state = state.copyWith(category: () => category);

  void setMineOnly(bool mineOnly) => state = state.copyWith(mineOnly: mineOnly);

  void clear() => state = IncidentFilter(mineOnly: state.mineOnly);
}

final incidentFilterProvider =
    NotifierProvider<IncidentFilterNotifier, IncidentFilter>(
      IncidentFilterNotifier.new,
    );

/// The reports list after search and filters are applied.
final filteredIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final filter = ref.watch(incidentFilterProvider);
  final uid = ref.watch(currentUserProvider.select((u) => u.value?.uid));
  return ref
      .watch(allIncidentsProvider)
      .whenData(
        (all) => all.where((i) => filter.accepts(i, uid: uid)).toList(),
      );
});
