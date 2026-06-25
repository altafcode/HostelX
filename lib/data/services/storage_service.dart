import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
 import '../../core/constants/cloudinary_config.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();

  // ── Pick image from gallery ─────────────────────────────────
  Future<File?> pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // ── Pick image from camera ──────────────────────────────────
  Future<File?> pickImageFromCamera() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // ── Upload single image to Cloudinary ───────────────────────
  // Returns the secure URL string, throws on failure
  Future<String> uploadImage(File imageFile, {String? folder}) async {
    final uri = Uri.parse(CloudinaryConfig.uploadUrl);

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = folder ?? 'hostelx';

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String;
    } else {
      final error = json.decode(response.body);
      throw Exception('Cloudinary upload failed: ${error['error']['message']}');
    }
  }

  // ── Pick and upload in one call ─────────────────────────────
  // Returns URL or null if user cancelled picker
  Future<String?> pickAndUpload({String? folder}) async {
    final file = await pickImage();
    if (file == null) return null;
    return await uploadImage(file, folder: folder);
  }

  // ── Upload multiple images (for hostel listings) ─────────────
  // Returns list of URLs. Uploads in parallel for speed.
  Future<List<String>> uploadMultipleImages(
      List<File> imageFiles, {
        String? folder,
      }) async {
    final futures = imageFiles.map(
          (file) => uploadImage(file, folder: folder ?? 'hostelx/hostels'),
    );
    return await Future.wait(futures);
  }

  // ── Pick multiple images at once ────────────────────────────
  Future<List<File>> pickMultipleImages({int maxCount = 5}) async {
    final List<XFile> picked = await _picker.pickMultiImage(
      imageQuality: 75,
      limit: maxCount,
    );
    return picked.map((x) => File(x.path)).toList();
  }

  // ── Convenience: profile photo upload ───────────────────────
  Future<String?> uploadProfilePhoto({required String userId}) async {
    return await pickAndUpload(folder: 'hostelx/profiles/$userId');
  }

  // ── Convenience: hostel images upload ───────────────────────
  Future<List<String>> uploadHostelImages({
    required List<File> imageFiles,
    required String hostelId,
  }) async {
    return await uploadMultipleImages(
      imageFiles,
      folder: 'hostelx/hostels/$hostelId',
    );
  }
}