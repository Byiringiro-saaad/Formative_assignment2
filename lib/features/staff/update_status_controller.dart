import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../data/models/incident.dart';
import '../../data/models/incident_status.dart';
import '../auth/auth_providers.dart';

/// Lets a staff member move an incident to its next status.
class UpdateStatusController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> change(
    Incident incident,
    IncidentStatus status, {
    String note = '',
  }) async {
    final staff = ref.read(currentUserProvider).value;
    if (staff == null || !staff.isStaff) {
      state = AsyncError(
        StateError('Only staff can update a report\'s status.'),
        StackTrace.current,
      );
      return false;
    }
    if (!incident.status.nextOptions.contains(status)) {
      state = AsyncError(
        StateError(
          'A ${incident.status.label} report cannot be moved to ${status.label}.',
        ),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(incidentRepositoryProvider)
          .updateStatus(
            incident: incident,
            status: status,
            staff: staff,
            note: note,
          ),
    );
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

final updateStatusControllerProvider =
    AsyncNotifierProvider.autoDispose<UpdateStatusController, void>(
      UpdateStatusController.new,
    );
