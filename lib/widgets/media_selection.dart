// lib/widgets/media_selection_bottom_sheet.dart
import 'package:flutter/material.dart';

class MediaSelectionBottomSheet extends StatelessWidget {
  final VoidCallback onPhotoSelected;
  final VoidCallback onVideoSelected;

  const MediaSelectionBottomSheet({
    super.key,
    required this.onPhotoSelected,
    required this.onVideoSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHandle(),
          const SizedBox(height: 20),
          const Text(
            'Create New Post',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.photo, color: Colors.white),
            title: const Text(
              'Photo',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Share a photo from camera or gallery',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              Navigator.pop(context);
              onPhotoSelected();
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.white),
            title: const Text(
              'Video',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Share a video from camera or gallery',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              Navigator.pop(context);
              onVideoSelected();
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
    );
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
}