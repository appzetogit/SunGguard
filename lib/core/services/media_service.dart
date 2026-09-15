import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

class MediaService {
  final ImagePicker _picker;

  MediaService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Uploads a file and returns the hosted URL.
  ///
  /// `POST /media/upload` responds `{ url, secureUrl }`. Picking an image was
  /// already supported; nothing ever sent it anywhere, so a chosen avatar
  /// lived only in memory and was lost on the next navigation.
  Future<String?> uploadFile(File file) async {
    try {
      final client = ApiClient.createDefault();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });
      final res = await client.post(ApiEndpoints.mediaUpload, data: formData);
      if (res is Map) {
        final url = res['secureUrl'] ?? res['url'];
        final str = url?.toString() ?? '';
        return str.isNotEmpty ? str : null;
      }
    } catch (_) {}
    return null;
  }

  /// Pick an image from device gallery
  Future<File?> pickImageFromGallery({int imageQuality = 85}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (_) {}
    return null;
  }

  /// Take a photo using device camera
  Future<File?> pickImageFromCamera({int imageQuality = 85}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (_) {}
    return null;
  }
}
