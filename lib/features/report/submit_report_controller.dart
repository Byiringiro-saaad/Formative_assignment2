import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../data/models/incident.dart';
import '../../data/models/incident_category.dart';
import '../../data/repositories/photo_repository.dart';
import '../auth/auth_providers.dart';

/// A photo picked on the device, ready to upload.
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}

/// What the student filled in on the report form.
class ReportDraft {
  const ReportDraft({
    required this.category,
    required this.title,
    required this.description,
    required this.location,
    this.photo,
    this.anonymous = false,
  });

  final IncidentCategory category;
  final String title;
  final String description;
  final String location;
  final PickedPhoto? photo;

  /// Hide the reporter's name from other students.
  final bool anonymous;
}

/// Uploads the photo (if any) and saves the report.
///
/// The photo goes first so the saved report always points at a photo that
/// exists. If saving the report then fails, the photo is removed again.
class SubmitReportController extends AsyncNotifier<Incident?> {
  @override
  FutureOr<Incident?> build() => null;

  Future<Incident?> submit(ReportDraft draft) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      state = AsyncError(
        StateError('You need to be signed in to report.'),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final incidents = ref.read(incidentRepositoryProvider);
      final photos = ref.read(photoRepositoryProvider);
      final id = incidents.newId();

      UploadedPhoto? uploaded;
      if (draft.photo != null) {
        uploaded = await photos.upload(
          uid: user.uid,
          incidentId: id,
          bytes: draft.photo!.bytes,
          extension: draft.photo!.extension,
        );
      }

      try {
        return await incidents.create(
          id: id,
          reporter: user,
          title: draft.title,
          description: draft.description,
          category: draft.category,
          location: draft.location,
          photoUrl: uploaded?.publicUrl,
          photoPath: uploaded?.path,
          anonymous: draft.anonymous,
        );
      } catch (_) {
        if (uploaded != null) {
          unawaited(photos.delete(uploaded.path).catchError((_) {}));
        }
        rethrow;
      }
    });
    // The form may have been closed while uploading; the report is saved
    // either way, there is just no screen left to update.
    if (!ref.mounted) return result.value;
    state = result;
    return result.value;
  }

  void reset() => state = const AsyncData(null);
}

final submitReportControllerProvider =
    AsyncNotifierProvider.autoDispose<SubmitReportController, Incident?>(
      SubmitReportController.new,
    );
