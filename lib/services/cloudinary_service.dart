// Add these dependencies to pubspec.yaml:
// dependencies:
//   http: ^1.1.0
//   crypto: ^3.0.3

// lib/services/cloudinary_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class CloudinaryService {
  // Replace these with your actual Cloudinary credentials
  static const String cloudName = 'mediaflows_bba34b45-e2cf-4dfe-853e-a0a3d2964370';
  static const String apiKey = '186944996926238';
  static const String apiSecret = 'CC6qjwr6nvP4_XO_hTRTVMV-UGU';
  static const String uploadPreset = 'knowmate_post'; // Optional
  
  Future<String> uploadMedia(File file, {bool isVideo = false}) async {
    try {
      print('Starting Cloudinary upload...');
      
      // Create upload URL
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/${isVideo ? 'video' : 'image'}/upload';
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add file
      final fileBytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'jpg'}',
      );
      request.files.add(multipartFile);
      
      // Add upload parameters
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      // If using upload preset (unsigned upload)
      if (uploadPreset.isNotEmpty) {
        request.fields['upload_preset'] = uploadPreset;
        request.fields['timestamp'] = timestamp;
      } else {
        // Signed upload
        request.fields['api_key'] = apiKey;
        request.fields['timestamp'] = timestamp;
        
        // Create signature
        final signature = _generateSignature({
          'timestamp': timestamp,
        });
        request.fields['signature'] = signature;
      }
      
      // Add additional parameters
      request.fields['folder'] = 'social_app_posts'; // Optional: organize uploads
      
      print('Sending request to Cloudinary...');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Cloudinary response status: ${response.statusCode}');
      print('Cloudinary response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final secureUrl = responseData['secure_url'] as String;
        print('Upload successful: $secureUrl');
        return secureUrl;
      } else {
        print('Upload failed: ${response.statusCode}');
        print('Error response: ${response.body}');
        throw Exception('Failed to upload to Cloudinary: ${response.statusCode}');
      }
      
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }
  
  String _generateSignature(Map<String, String> params) {
    // Sort parameters
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    // Create string to sign
    final stringToSign = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&') + apiSecret;
    
    // Generate SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }
}

// Update your FirestoreService to use CloudinaryService:
// In firestore_service.dart, replace the _uploadToCloudinary method:

