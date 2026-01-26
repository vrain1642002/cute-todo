import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();

  // Cloudinary Configuration
  final String _cloudName = 'dxcqkslgi';
  final String _uploadPreset = 'j6m693gj';

  /// Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages() async {
    try {
      return await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  /// Pick single image from gallery (Legacy support)
  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick video from gallery
  Future<XFile?> pickVideoFromGallery() async {
    try {
      return await _picker.pickVideo(
        source: ImageSource.gallery,
      );
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  /// Pick from camera
  Future<XFile?> pickFromCamera({bool isVideo = false}) async {
    try {
      if (isVideo) {
        return await _picker.pickVideo(source: ImageSource.camera);
      }
      return await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      return null;
    }
  }

  /// Legacy support for pickImageFromCamera
  Future<XFile?> pickImageFromCamera() => pickFromCamera(isVideo: false);

  /// Upload file to Cloudinary (Detects image vs video)
  Future<String?> uploadFile(XFile file, String userId) async {
    try {
      debugPrint('Starting Cloudinary upload for: ${file.name}');

      // Detect resource type
      final String extension = file.path.split('.').last.toLowerCase();
      final bool isVideo =
          ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
      final String resourceType = isVideo ? 'video' : 'image';

      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload');

      final bytes = await file.readAsBytes();

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'tasks/$userId'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
          contentType:
              isVideo ? MediaType('video', 'mp4') : MediaType('image', 'jpeg'),
        ));

      // Use longer timeout for videos
      final streamedResponse =
          await request.send().timeout(Duration(seconds: isVideo ? 300 : 45));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String secureUrl = data['secure_url'];
        debugPrint(
            'File uploaded successfully to Cloudinary ($resourceType): $secureUrl');
        return secureUrl;
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['error']?['message'] ?? 'Unknown error';
        debugPrint(
            'Cloudinary Upload Failed (${response.statusCode}): $message');
        return null;
      }
    } catch (e) {
      debugPrint('🚨 CRITICAL Error uploading to Cloudinary: $e');
      rethrow;
    }
  }

  /// Legacy alias
  Future<String?> uploadImage(XFile image, String userId) =>
      uploadFile(image, userId);

  /// Upload multiple files
  Future<List<String>> uploadFiles(List<XFile> files, String userId) async {
    final List<String> urls = [];
    for (final file in files) {
      final url = await uploadFile(file, userId);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }

  /// Legacy alias
  Future<List<String>> uploadImages(List<XFile> images, String userId) =>
      uploadFiles(images, userId);

  Future<void> deleteFile(String fileUrl) async {
    // Note: Deleting from Cloudinary requires signed requests with API Secret.
    // Since we only have the Upload Preset (client-side), we cannot securely delete.
    // This method is a placeholder. In a real app, you'd call a backend API.
    debugPrint('Pseudo-deleting file: $fileUrl');
    // We could try an unsigned delete token if configured, but it's risky.
    // For now, we just acknowledge the request so the UI can remove the link.
    return;
  }
}
