// lib/widgets/post_viewer.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post_model.dart';

class PostViewer extends StatefulWidget {
  final PostModel post;

  const PostViewer({
    super.key,
    required this.post,
  });

  @override
  State<PostViewer> createState() => _PostViewerState();
}

class _PostViewerState extends State<PostViewer> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.isVideo) {
      _initializeVideo();
    }
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.network(widget.post.mediaUrl)
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        // Auto-play the video
        _videoController!.play();
        _isPlaying = true;
      }).catchError((error) {
        print('Error initializing video: $error');
      });
    
    // Listen to video player events
    _videoController!.addListener(() {
      if (mounted) {
        setState(() {
          _isPlaying = _videoController!.value.isPlaying;
        });
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMedia(),
                    _buildInteractionBar(),
                    _buildLikesCount(),
                    if (widget.post.caption.isNotEmpty) _buildCaption(),
                    _buildComments(),
                    _buildTimeStamp(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 50, 15, 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.grey.shade800,
            child: Text(
              widget.post.userName.isNotEmpty
                  ? widget.post.userName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.post.userName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        width: double.infinity,
        child: widget.post.isVideo
            ? _buildVideoPlayer()
            : _buildImage(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_isVideoInitialized) {
      return Container(
        color: Colors.grey.shade900,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          // Play/Pause overlay
          AnimatedOpacity(
            opacity: _isPlaying ? 0.0 : 0.7,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_filled,
                  size: 70,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Video progress indicator
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              padding: const EdgeInsets.all(8),
              colors: const VideoProgressColors(
                playedColor: Colors.orange,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Image.network(
      widget.post.mediaUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade900,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade900,
          child: const Center(
            child: Icon(Icons.error, color: Colors.grey, size: 50),
          ),
        );
      },
    );
  }

  Widget _buildInteractionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // Handle like functionality
            },
            icon: const Icon(Icons.favorite_border, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 5),
          IconButton(
            onPressed: () {
              // Handle comment functionality
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 5),
          IconButton(
            onPressed: () {
              // Handle share functionality
            },
            icon: const Icon(Icons.send_outlined, color: Colors.white, size: 26),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Handle bookmark functionality
            },
            icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesCount() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      child: const Text(
        '1,234 likes',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCaption() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: widget.post.userName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: widget.post.caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'View all 42 comments',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildComment('john_doe', 'Amazing shot! 🔥'),
          const SizedBox(height: 4),
          _buildComment('jane_smith', 'Love this! Where was this taken?'),
        ],
      ),
    );
  }

  Widget _buildComment(String username, String comment) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: username,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: comment,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStamp() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: const Text(
        '2 hours ago',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 8, 15, 20),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade800,
            child: const Text(
              'Y',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: TextField(
              style: TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Handle post comment
            },
            child: const Text(
              'Post',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}