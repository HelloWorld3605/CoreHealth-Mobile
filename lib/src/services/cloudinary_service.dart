import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cloudinary image upload service.
///
/// Provides signed image uploads to Cloudinary CDN.
/// Build with: --dart-define=CLOUDINARY_CLOUD_NAME=xxx
///             --dart-define=CLOUDINARY_API_KEY=xxx
///             --dart-define=CLOUDINARY_API_SECRET=xxx
class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  static const _cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const _apiKey = String.fromEnvironment('CLOUDINARY_API_KEY');
  static const _apiSecret = String.fromEnvironment('CLOUDINARY_API_SECRET');
  static const _rootFolder = 'corehealth/mobile';

  bool get isConfigured =>
      _cloudName.isNotEmpty && _apiKey.isNotEmpty && _apiSecret.isNotEmpty;

  /// Upload image bytes to Cloudinary.
  ///
  /// [bytes] — raw image data (JPEG, PNG, etc.)
  /// [folder] — subfolder under corehealth/mobile (e.g. 'profile', 'food', 'product')
  /// [filename] — optional custom public_id (without extension)
  ///
  /// Returns the secure URL of the uploaded image, or null on failure.
  Future<String?> uploadImage(
    Uint8List bytes, {
    String folder = 'image',
    String? filename,
  }) async {
    if (!isConfigured) {
      debugPrint('[Cloudinary] Not configured — missing env vars');
      return null;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final publicId = filename ?? 'img_${DateTime.now().millisecondsSinceEpoch}';
      final fullFolder = '$_rootFolder/$folder';

      // Generate signature: SHA-1 of sorted params + api_secret
      final signatureBase =
          'folder=$fullFolder&public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(signatureBase)).toString();

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..fields['folder'] = fullFolder
        ..fields['public_id'] = publicId
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '$publicId.jpg',
        ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        debugPrint('[Cloudinary] Upload failed: ${response.statusCode} ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String?;
    } catch (e) {
      debugPrint('[Cloudinary] Upload error: $e');
      return null;
    }
  }

  /// Upload result with metadata.
  Future<CloudinaryUploadResult?> uploadImageWithMeta(
    Uint8List bytes, {
    String folder = 'image',
    String? filename,
  }) async {
    if (!isConfigured) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final publicId = filename ?? 'img_${DateTime.now().millisecondsSinceEpoch}';
      final fullFolder = '$_rootFolder/$folder';

      final signatureBase =
          'folder=$fullFolder&public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(signatureBase)).toString();

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..fields['folder'] = fullFolder
        ..fields['public_id'] = publicId
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '$publicId.jpg',
        ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        debugPrint('[Cloudinary] Upload failed: ${response.statusCode} ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CloudinaryUploadResult(
        url: data['secure_url'] as String? ?? '',
        publicId: data['public_id'] as String? ?? '',
        format: data['format'] as String? ?? '',
        bytes: (data['bytes'] as num?)?.toInt() ?? 0,
        originalFilename: data['original_filename'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('[Cloudinary] Upload error: $e');
      return null;
    }
  }
}

/// Result of a Cloudinary upload.
class CloudinaryUploadResult {
  final String url;
  final String publicId;
  final String format;
  final int bytes;
  final String originalFilename;

  const CloudinaryUploadResult({
    required this.url,
    required this.publicId,
    required this.format,
    required this.bytes,
    required this.originalFilename,
  });
}
