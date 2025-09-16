import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'searched_profile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentSearches = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    if (user == null) return;
    
    try {
      final recentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('recentSearches')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      setState(() {
        _recentSearches = recentSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      // Search for users by name (case insensitive)
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .limit(20)
          .get();

      setState(() {
        _searchResults = usersSnapshot.docs
            .where((doc) => doc.id != user!.uid) // Exclude current user
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _addToRecentSearches(Map<String, dynamic> userData) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('recentSearches')
          .doc(userData['id'])
          .set({
        'userId': userData['id'],
        'name': userData['name'],
        'profileImageUrl': userData['profileImageUrl'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Reload recent searches
      _loadRecentSearches();
    } catch (e) {
      print('Error adding to recent searches: $e');
    }
  }

  Future<void> _clearRecentSearches() async {
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final recentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('recentSearches')
          .get();

      for (var doc in recentSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _loadRecentSearches();
    } catch (e) {
      print('Error clearing recent searches: $e');
    }
  }

  Widget _buildUserCard(Map<String, dynamic> userData, {bool isRecent = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[800],
          backgroundImage: userData['profileImageUrl'] != null
              ? NetworkImage(userData['profileImageUrl'])
              : null,
          child: userData['profileImageUrl'] == null
              ? Text(
                  (userData['name'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        title: Text(
          userData['name'] ?? 'Unknown User',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          userData['description']?.isNotEmpty == true
              ? userData['description']
              : 'No bio available',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isRecent
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .collection('recentSearches')
                        .doc(userData['id'])
                        .delete();
                    _loadRecentSearches();
                  } catch (e) {
                    print('Error removing recent search: $e');
                  }
                },
              )
            : null,
        onTap: () {
          _addToRecentSearches(userData);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchedProfile(
                userId: userData['id'],
                userName: userData['name'] ?? 'Unknown User',
                userBio: userData['description'] ?? '',
                profileImageUrl: userData['profileImageUrl'],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Search App Bar
          SliverAppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            floating: true,
            snap: true,
            title: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                ),
                onChanged: _searchUsers,
                onSubmitted: _searchUsers,
              ),
            ),
            actions: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    _searchUsers('');
                  },
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: _searchQuery.isEmpty
                ? _buildRecentSearches()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._recentSearches.map((search) => _buildUserCard(search, isRecent: true)),
        ] else ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(50.0),
              child: Column(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Search for users',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Find and connect with other users',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: Column(
            children: [
              Icon(
                Icons.person_search,
                color: Colors.grey,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(
            'Search Results (${_searchResults.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ..._searchResults.map((user) => _buildUserCard(user)),
      ],
    );
  }
}
