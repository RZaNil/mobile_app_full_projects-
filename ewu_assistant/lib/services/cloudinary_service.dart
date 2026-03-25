import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService();

  static const String cloudName = 'dgqysd9yq';
  static const String uploadPreset = 'ewuAssistant';

  bool get isConfigured => cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  Future<String> uploadImage(File file) async {
    if (!isConfigured) {
      throw Exception(
        'Cloudinary is not configured yet. Add your cloud name and upload preset in cloudinary_service.dart.',
      );
    }
    if (!await file.exists()) {
      throw Exception(
        'The selected image could not be found. Please choose the image again.',
      );
    }

    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final http.Response response;
    try {
      final http.StreamedResponse streamedResponse = await request
          .send()
          .timeout(const Duration(seconds: 30));
      response = await http.Response.fromStream(streamedResponse);
    } on TimeoutException {
      throw Exception(
        'Cloudinary took too long to respond. Please try the upload again.',
      );
    } on SocketException {
      throw Exception(
        'No internet connection was detected. Please check your connection and try again.',
      );
    } catch (_) {
      throw Exception(
        'Image upload could not be completed right now. Please try again.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Cloudinary upload failed. Please try again.';
      try {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final Object? error = body['error'];
        if (error is Map<String, dynamic>) {
          final String? cloudinaryMessage = error['message']?.toString();
          if (cloudinaryMessage != null && cloudinaryMessage.isNotEmpty) {
            message = cloudinaryMessage;
          }
        }
      } catch (_) {
        // Fall back to the default user-friendly error.
      }
      throw Exception(message);
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String? secureUrl = body['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary did not return a usable image URL.');
    }
    return secureUrl;
  }
}
