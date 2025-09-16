import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchedProfile extends StatefulWidget {
  final String userId;
  final String userName;
  final String userBio;
  final String? profileImageUrl;

  const SearchedProfile({
    super.key,
    required this.userId,
    required this.userName,
    required this.userBio,
    this.profileImageUrl,
  });

  @override
  State<SearchedProfile> createState() => _SearchedProfileState();
}

class _SearchedProfileState extends State<SearchedProfile> {
  final user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  bool isFollowing = false;
  bool isFollowingBack = false;
  int posts = 0;
  int followers = 0;
  int following = 0;
  List<Map<String, dynamic>> userPosts = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkFollowStatus();
  }

  Future<void> _loadUserData() async {
    try {
      // Load user stats
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        setState(() {
          posts = userData['posts'] ?? 0;
          followers = userData['followers'] ?? 0;
          following = userData['following'] ?? 0;
        });
      }

      // Load user posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .limit(12)
          .get();

      setState(() {
        userPosts = postsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkFollowStatus() async {
    if (user == null || user!.uid == widget.userId) return;

    try {
      final followDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('following')
          .doc(widget.userId)
          .get();

      setState(() {
        isFollowing = followDoc.exists;
      });
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _followUser() async {
    if (user == null || user!.uid == widget.userId) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Add to current user's following
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('following')
            .doc(widget.userId),
        {
          'userId': widget.userId,
          'name': widget.userName,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      // Add to target user's followers
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('followers')
            .doc(user!.uid),
        {
          'userId': user!.uid,
          'name': user!.displayName ?? 'User',
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      // Update counters
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(user!.uid),
        {'following': FieldValue.increment(1)},
      );

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(widget.userId),
        {'followers': FieldValue.increment(1)},
      );

      await batch.commit();

      setState(() {
        isFollowing = true;
        followers++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Now following ${widget.userName}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error following user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error following user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unfollowUser() async {
    if (user == null || user!.uid == widget.userId) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Remove from current user's following
      batch.delete(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('following')
            .doc(widget.userId),
      );

      // Remove from target user's followers
      batch.delete(
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('followers')
            .doc(user!.uid),
      );

      // Update counters
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(user!.uid),
        {'following': FieldValue.increment(-1)},
      );

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(widget.userId),
        {'followers': FieldValue.increment(-1)},
      );

      await batch.commit();

      setState(() {
        isFollowing = false;
        followers--;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unfollowed ${widget.userName}'),
          backgroundColor: Colors.grey,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error unfollowing user: $e');
    }
  }

  void _showFollowersModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Followers',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$followers followers',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFollowingModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Following',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$following following',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
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
            title: Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _showOptionsModal(),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Profile Header (Instagram style)
                        Row(
                          children: [
                            // Profile Picture
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.grey[800],
                                backgroundImage: widget.profileImageUrl != null
                                    ? NetworkImage(widget.profileImageUrl!)
                                    : null,
                                child: widget.profileImageUrl == null
                                    ? Text(
                                        widget.userName.isNotEmpty
                                            ? widget.userName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),

                            const SizedBox(width: 30),

                            // Stats
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatColumn(
                                    posts.toString(),
                                    "Posts",
                                  ),
                                  GestureDetector(
                                    onTap: _showFollowersModal,
                                    child: _buildStatColumn(
                                      followers.toString(),
                                      "Followers",
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _showFollowingModal,
                                    child: _buildStatColumn(
                                      following.toString(),
                                      "Following",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // Name and Bio
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                widget.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            // Bio
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                widget.userBio.isEmpty ? "No bio yet" : widget.userBio,
                                style: TextStyle(
                                  color: widget.userBio.isEmpty
                                      ? Colors.grey
                                      : Colors.white,
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            if (user != null && user!.uid != widget.userId) ...[
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isFollowing ? _unfollowUser : _followUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFollowing
                                        ? Colors.grey[800]
                                        : Colors.blue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(isFollowing ? "Following" : "Follow"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[800],
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Message"),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[800],
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Edit Profile"),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Posts Grid
                        DefaultTabController(
                          length: 3,
                          child: Column(
                            children: [
                              // Tab Bar
                              TabBar(
                                indicatorColor: Colors.white,
                                indicatorWeight: 2,
                                tabs: [
                                  Tab(
                                    icon: Icon(
                                      Icons.grid_on,
                                      color: Colors.white,
                                    ),
                                    text: "Posts",
                                  ),
                                  Tab(
                                    icon: Icon(
                                      Icons.play_circle_outline,
                                      color: Colors.white,
                                    ),
                                    text: "Reels",
                                  ),
                                  Tab(
                                    icon: Icon(
                                      Icons.bookmark_border,
                                      color: Colors.white,
                                    ),
                                    text: "Saved",
                                  ),
                                ],
                              ),

                              // Tab Bar View
                              SizedBox(
                                height: 300,
                                child: TabBarView(
                                  children: [
                                    // Posts Grid
                                    GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 2,
                                        mainAxisSpacing: 2,
                                      ),
                                      itemCount: posts,
                                      itemBuilder: (context, index) =>
                                          Container(
                                        color: Colors.grey[900],
                                        child: const Center(
                                          child: Icon(
                                            Icons.image,
                                            color: Colors.grey,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Reels Grid
                                    GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 2,
                                        mainAxisSpacing: 2,
                                      ),
                                      itemCount: 0,
                                      itemBuilder: (context, index) =>
                                          Container(
                                        color: Colors.grey[900],
                                        child: const Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Icon(
                                              Icons.play_circle_outline,
                                              color: Colors.grey,
                                              size: 30,
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Icon(
                                                Icons.video_collection,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Saved Grid
                                    GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 2,
                                        mainAxisSpacing: 2,
                                      ),
                                      itemCount: 0,
                                      itemBuilder: (context, index) =>
                                          Container(
                                        color: Colors.grey[900],
                                        child: const Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Icon(
                                              Icons.bookmark,
                                              color: Colors.grey,
                                              size: 30,
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Icon(
                                                Icons.bookmark_border,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  void _showOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text(
                "Report",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                // Add report functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text(
                "Block",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                // Add block functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text(
                "Copy Profile URL",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Add copy URL functionality
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
