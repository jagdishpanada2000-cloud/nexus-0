// lib/widgets/post_creation_dialog.dart
import 'package:flutter/material.dart';
import 'dart:io';

class PostCreationDialog extends StatefulWidget {
  final File mediaFile;
  final bool isVideo;
  final bool isUploading;
  final Function(String caption) onPost;

  const PostCreationDialog({
    super.key,
    required this.mediaFile,
    required this.isVideo,
    required this.isUploading,
    required this.onPost,
  });

  @override
  State<PostCreationDialog> createState() => _PostCreationDialogState();
}

class _PostCreationDialogState extends State<PostCreationDialog> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text(
        'Create Post',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMediaPreview(),
          const SizedBox(height: 15),
          _buildCaptionInput(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.isUploading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: widget.isUploading 
              ? null 
              : () => widget.onPost(_captionController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: widget.isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Post'),
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: widget.isVideo
            ? _buildVideoPreview()
            : _buildImagePreview(),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      color: Colors.grey.shade800,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam, size: 60, color: Colors.white54),
          SizedBox(height: 10),
          Text(
            'Video Selected',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Image.file(
      widget.mediaFile,
      fit: BoxFit.cover,
    );
  }

  Widget _buildCaptionInput() {
    return TextField(
      controller: _captionController,
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
      maxLength: 500,
      decoration: InputDecoration(
        hintText: 'Write a caption...',
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.orange),
        ),
        filled: true,
        fillColor: Colors.grey.shade800,
      ),
    );
  }
}