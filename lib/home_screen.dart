import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'searched_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String studentName = "Student";
  List<Map<String, dynamic>> followRequests = [];
  Set<String> likedPosts = {}; // Track liked posts

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadFollowRequests();
  }

  Future<void> _loadUserName() async {
    if (user == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          studentName = userDoc.data()!["name"] ?? "Student";
        });
      }
    } catch (e) {
      print("Error loading user name: $e");
    }
  }

  Future<void> _loadFollowRequests() async {
    if (user == null) return;
    try {
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('followRequests')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        followRequests = requestsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      print("Error loading follow requests: $e");
    }
  }

  Future<void> _acceptFollowRequest(
    String requesterId,
    String requesterName,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Add to followers
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('followers')
            .doc(requesterId),
        {
          'userId': requesterId,
          'name': requesterName,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      // Add to requester's following
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(requesterId)
            .collection('following')
            .doc(user!.uid),
        {
          'userId': user!.uid,
          'name': studentName,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      // Update counters
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(user!.uid),
        {'followers': FieldValue.increment(1)},
      );

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(requesterId),
        {'following': FieldValue.increment(1)},
      );

      // Delete the follow request
      batch.delete(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('followRequests')
            .doc(requesterId),
      );

      await batch.commit();

      // Remove from local list
      setState(() {
        followRequests.removeWhere((request) => request['id'] == requesterId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Accepted follow request from $requesterName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error accepting follow request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error accepting follow request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _declineFollowRequest(
    String requesterId,
    String requesterName,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('followRequests')
          .doc(requesterId)
          .delete();

      setState(() {
        followRequests.removeWhere((request) => request['id'] == requesterId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Declined follow request from $requesterName'),
          backgroundColor: Colors.grey,
        ),
      );
    } catch (e) {
      print('Error declining follow request: $e');
    }
  }

  Widget _buildFollowRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade400.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[800],
            child: Text(
              (request['name'] as String? ?? 'U').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['name'] ?? 'Unknown User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'wants to follow you',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _acceptFollowRequest(
                  request['id'],
                  request['name'] ?? 'Unknown User',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade400,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _declineFollowRequest(
                  request['id'],
                  request['name'] ?? 'Unknown User',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Decline',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleLike(String postId) {
    setState(() {
      if (likedPosts.contains(postId)) {
        likedPosts.remove(postId);
      } else {
        likedPosts.add(postId);
      }
    });
  }

  void _navigateToProfile(String userName, String displayName) {
    // For demo purposes, we'll use a mock user ID
    // In a real app, you'd fetch the actual user ID from Firestore
    String mockUserId = userName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('.', '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchedProfile(
          userId: mockUserId,
          userName: userName,
          userBio: "This is a sample bio for $userName",
          profileImageUrl: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Instagram-style app bar
          SliverAppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            floating: true,
            snap: true,
            title: Row(
              children: [
                const Text(
                  "Kniwmate",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cursive',
                  ),
                ),
                const Spacer(),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Show follow requests in a modal
                        _showFollowRequestsModal();
                      },
                    ),
                    if (followRequests.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            followRequests.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Follow Requests Section (if any)
                if (followRequests.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Follow Requests (${followRequests.length})",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: _showFollowRequestsModal,
                          child: Text(
                            "See All",
                            style: TextStyle(
                              color: Colors.orange.shade400,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Show first 2 follow requests
                  ...followRequests
                      .take(2)
                      .map((request) => _buildFollowRequestCard(request)),
                  const Divider(color: Colors.grey, height: 0.5),
                ],

                // Stories Section
                Container(
                  height: 110, // Increased height to accommodate text
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildMyStory();
                      }
                      return _buildStoryItem("Class $index", "active");
                    },
                  ),
                ),

                const Divider(color: Colors.grey, height: 0.5),

                // Feed Section
               
              ],
            ),
          ),

          // Posts Feed
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildFeedPost(index);
              },
              childCount: 5, // Number of posts
            ),
          ),
        ],
      ),
    );
  }

  void _showFollowRequestsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Follow Requests (${followRequests.length})",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (followRequests.isEmpty) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      "No follow requests",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
              ] else ...[
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: followRequests.length,
                    itemBuilder: (context, index) {
                      return _buildFollowRequestCard(followRequests[index]);
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyStory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            "Your story",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(String name, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: status == "active" ? Colors.red : Colors.grey,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[800],
              child: Text(
                name.substring(0, 1),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedPost(int index) {
    final posts = [
      {
        "user": "Dr. Smith",
        "subject": "Mathematics",
        "content": "New assignment posted: Calculus Problem Set #3",
        "time": "2 hours ago",
        "likes": "24",
        "comments": "8",
        "id": "post_1",
      },
      {
        "user": "Prof. Johnson",
        "subject": "Physics",
        "content": "Lab results are now available. Great work everyone!",
        "time": "4 hours ago",
        "likes": "31",
        "comments": "12",
        "id": "post_2",
      },
      {
        "user": "Ms. Davis",
        "subject": "Literature",
        "content": "Don't forget: Book report due tomorrow!",
        "time": "6 hours ago",
        "likes": "18",
        "comments": "5",
        "id": "post_3",
      },
      {
        "user": "Dr. Wilson",
        "subject": "Chemistry",
        "content": "Midterm exam results posted. Check your grades!",
        "time": "1 day ago",
        "likes": "45",
        "comments": "23",
        "id": "post_4",
      },
      {
        "user": "Prof. Brown",
        "subject": "History",
        "content": "Field trip forms available at the office",
        "time": "2 days ago",
        "likes": "12",
        "comments": "3",
        "id": "post_5",
      },
    ];

    final post = posts[index % posts.length];
    final postId = post["id"]!;
    final isLiked = likedPosts.contains(postId);

    // Parse likes count and adjust for like/unlike
    int baseLikes = int.parse(post["likes"]!);
    int currentLikes = baseLikes + (isLiked ? 1 : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _navigateToProfile(post["user"]!, post["user"]!),
                  borderRadius: BorderRadius.circular(18),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[800],
                    child: Text(
                      post["user"]!.substring(0, 1),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post["user"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        post["subject"]!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Post Content
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              post["content"]!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(postId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(
                    Icons.mode_comment_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined, color: Colors.white),
                  onPressed: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Likes and Comments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$currentLikes likes",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "View all ${post['comments']} comments",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  post["time"]!,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
