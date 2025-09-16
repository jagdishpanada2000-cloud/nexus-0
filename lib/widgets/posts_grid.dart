// lib/widgets/posts_grid.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'post_viewer.dart';

class PostsGrid extends StatelessWidget {
  final List<PostModel> posts;
  final bool isEmpty;

  const PostsGrid({
    super.key,
    required this.posts,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildPostThumbnail(context, post);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Column(
        children: [
          Icon(
            Icons.grid_on_outlined,
            color: Colors.grey,
            size: 60,
          ),
          SizedBox(height: 20),
          Text(
            'No posts yet',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'When you share photos and videos, they\'ll appear on your profile.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPostThumbnail(BuildContext context, PostModel post) {
    return GestureDetector(
      onTap: () => _viewPost(context, post),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                post.mediaUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade800,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.orange,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade800,
                    child: const Icon(
                      Icons.error,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
              if (post.isVideo)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewPost(BuildContext context, PostModel post) {
    showDialog(
      context: context,
      builder: (context) => PostViewer(post: post),
    );
  }
}