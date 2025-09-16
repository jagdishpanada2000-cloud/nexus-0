// lib/services/media_service.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:io';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final ImagePicker _picker = ImagePicker();

  // Permission handling methods
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> _requestPhotosPermission() async {
    Permission permission;
    
    if (Platform.isIOS) {
      permission = Permission.photos;
    } else {
      permission = Permission.photos;
    }
    
    final status = await permission.request();
    
    if (status == PermissionStatus.granted) {
      return true;
    } else if (status == PermissionStatus.denied) {
      return false; // Handle this in UI
    } else if (status == PermissionStatus.permanentlyDenied) {
      return false; // Handle this in UI
    }
    
    return false;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo < 33) {
        final status = await Permission.storage.request();
        if (status == PermissionStatus.granted) {
          return true;
        } else if (status == PermissionStatus.permanentlyDenied) {
          return false; // Handle this in UI
        }
      }
    }
    return true;
  }

  Future<int> _getAndroidVersion() async {
    return 33; // This should be implemented properly in a real app
  }

  void showImageSourceSelection(
    BuildContext context, {
    required Function(File, {required bool isVideo}) onMediaSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBottomSheetHandle(),
            const SizedBox(height: 20),
            const Text(
              'Select Image Source',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _openCamera(context, isVideo: false, onMediaSelected: onMediaSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _openGallery(context, isVideo: false, onMediaSelected: onMediaSelected);
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showVideoSourceSelection(
    BuildContext context, {
    required Function(File, {required bool isVideo}) onMediaSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBottomSheetHandle(),
            const SizedBox(height: 20),
            const Text(
              'Select Video Source',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.white),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _openCamera(context, isVideo: true, onMediaSelected: onMediaSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.white),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _openGallery(context, isVideo: true, onMediaSelected: onMediaSelected);
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCamera(
    BuildContext context, {
    required bool isVideo,
    required Function(File, {required bool isVideo}) onMediaSelected,
  }) async {
    try {
      final hasCameraPermission = await _requestCameraPermission();
      if (!hasCameraPermission) {
        _showPermissionDialog(
          context,
          'Camera Permission Required',
          'This app needs camera permission to take photos and videos.',
        );
        return;
      }

      final hasStoragePermission = await _requestStoragePermission();
      if (!hasStoragePermission) {
        _showPermissionDialog(
          context,
          'Storage Permission Required',
          'This app needs storage permission to save media files.',
        );
        return;
      }

      final XFile? media = isVideo
          ? await _picker.pickVideo(source: ImageSource.camera)
          : await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      
      if (media != null) {
        onMediaSelected(File(media.path), isVideo: isVideo);
      }
    } catch (e) {
      _showErrorDialog(context, 'Failed to open camera: $e');
    }
  }

  Future<void> _openGallery(
    BuildContext context, {
    required bool isVideo,
    required Function(File, {required bool isVideo}) onMediaSelected,
  }) async {
    try {
      final hasPhotosPermission = await _requestPhotosPermission();
      if (!hasPhotosPermission) {
        _showPermissionDialog(
          context,
          'Photo Library Permission Required',
          'This app needs photo library access to select images and videos.',
        );
        return;
      }

      final hasStoragePermission = await _requestStoragePermission();
      if (!hasStoragePermission) {
        _showPermissionDialog(
          context,
          'Storage Permission Required',
          'This app needs storage permission to access media files.',
        );
        return;
      }

      final XFile? media = isVideo
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      
      if (media != null) {
        onMediaSelected(File(media.path), isVideo: isVideo);
      }
    } catch (e) {
      _showErrorDialog(context, 'Failed to open gallery: $e');
    }
  }

  Widget _buildBottomSheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  void _showPermissionDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}