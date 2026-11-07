import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';

/// Where an uploaded photo ended up.
class UploadedPhoto {
  const UploadedPhoto({required this.path, required this.publicUrl});

  /// Object path inside the bucket, e.g. `<uid>/<incidentId>/<uuid>.jpg`.
  final String path;
  final String publicUrl;
}

/// Stores incident photos. Implemented with Supabase Storage; kept behind an
/// interface so screens and tests don't depend on Supabase directly.
abstract class PhotoRepository {
  Future<UploadedPhoto> upload({
    required String uid,
    required String incidentId,
    required Uint8List bytes,
    required String extension,
  });

  Future<void> delete(String path);
}

class SupabasePhotoRepository implements PhotoRepository {
  SupabasePhotoRepository(this._client, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final SupabaseClient _client;
  final Uuid _uuid;

  StorageFileApi get _bucket => _client.storage.from(AppConfig.photoBucket);

  static const _mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
  };

  @override
  Future<UploadedPhoto> upload({
    required String uid,
    required String incidentId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final ext = extension.toLowerCase().replaceFirst('.', '');
    final contentType = _mimeTypes[ext];
    if (contentType == null) {
      throw const PhotoUploadFailure(
        'Only JPG, PNG, WebP or HEIC photos are supported.',
      );
    }
    if (bytes.lengthInBytes > AppConfig.maxPhotoBytes) {
      throw const PhotoUploadFailure('That photo is too large (max 5 MB).');
    }

    // The first folder must be the user's id: the storage policy checks it.
    final path = '$uid/$incidentId/${_uuid.v4()}.$ext';
    try {
      await _bucket.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );
    } on StorageException catch (e) {
      throw PhotoUploadFailure('Photo upload failed: ${e.message}');
    }
    return UploadedPhoto(path: path, publicUrl: _bucket.getPublicUrl(path));
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _bucket.remove([path]);
    } on StorageException catch (e) {
      throw PhotoUploadFailure('Could not delete photo: ${e.message}');
    }
  }
}

class PhotoUploadFailure implements Exception {
  const PhotoUploadFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
