import 'dart:typed_data';

import 'package:campus_incidents/data/repositories/photo_repository.dart';
import 'package:image_picker/image_picker.dart';

/// In-memory photo store that records uploads instead of calling Supabase.
class FakePhotoRepository implements PhotoRepository {
  final uploads = <String, Uint8List>{};
  final deleted = <String>[];
  bool failNextUpload = false;

  @override
  Future<UploadedPhoto> upload({
    required String uid,
    required String incidentId,
    required Uint8List bytes,
    required String extension,
  }) async {
    if (failNextUpload) {
      failNextUpload = false;
      throw const PhotoUploadFailure('Photo upload failed: network down');
    }
    final path = '$uid/$incidentId/photo.$extension';
    uploads[path] = bytes;
    return UploadedPhoto(path: path, publicUrl: 'https://photos.test/$path');
  }

  @override
  Future<void> delete(String path) async {
    uploads.remove(path);
    deleted.add(path);
  }
}

/// Image picker that returns a tiny PNG instead of opening the camera.
class FakeImagePicker extends ImagePicker {
  static final png = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x63, 0xFC, 0xCF, 0xC0, 0x50,
    0x0F, 0x00, 0x04, 0x85, 0x01, 0x80, 0x84, 0xA9, 0x8C, 0x21, 0x00, 0x00,
    0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => XFile.fromData(png, name: 'photo.png', mimeType: 'image/png');
}
