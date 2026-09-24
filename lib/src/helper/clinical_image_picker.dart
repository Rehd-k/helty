import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Image selected via [pickClinicalImage] for clinical multipart uploads.
class PickedClinicalImage {
  const PickedClinicalImage({
    required this.name,
    this.path,
    this.bytes,
  });

  final String name;
  final String? path;
  final Uint8List? bytes;

  /// Multipart part for wound assessment upload (`FileInterceptor('file')`).
  Future<MultipartFile> toMultipartFile() async {
    final filename = name.isNotEmpty ? name : 'image.jpg';
    final data = bytes;
    if (data != null && data.isNotEmpty) {
      return MultipartFile.fromBytes(data, filename: filename);
    }
    if (kIsWeb) {
      throw StateError('No image bytes available for upload');
    }
    final filePath = path;
    if (filePath == null || filePath.isEmpty) {
      throw StateError('No image path available for upload');
    }
    return MultipartFile.fromFile(filePath, filename: filename);
  }
}

/// Opens the system picker for any image type (jpg, png, heic, etc.).
Future<PickedClinicalImage?> pickClinicalImage() async {
  final picked = await FilePicker.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (picked == null || picked.files.isEmpty) return null;
  final file = picked.files.single;
  return PickedClinicalImage(
    name: file.name,
    path: file.path,
    bytes: file.bytes,
  );
}
