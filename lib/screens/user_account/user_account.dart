// lib/screens/user_account/user_account.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:io';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/media_service.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/posts_grid.dart';
import '../../widgets/settings_bottom_sheet.dart';
import '../../widgets/edit_profile_bottom_sheet.dart';
import '../../widgets/media_selection_bottom_sheet.dart';
import '../../widgets/post_creation_dialog.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';

class UserAccount extends StatefulWidget {
  const UserAccount({super.key});

  @override
  State<UserAccount> createState() => _UserAccountState();
}

class _UserAccountState extends State<UserAccount> {
  // Services
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final MediaService _mediaService = MediaService();
  
  // State variables
  UserModel? userData;
  List<PostModel> userPosts = [];
  bool isLoading = true;
  bool isUploading = false;
  
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserPosts();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = await _firestoreService.getUserData(user.uid);
        setState(() {
          userData = data;
          _bioController.text = userData?.bio ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final posts = await _firestoreService.getUserPosts(user.uid);
        print('Loaded ${posts.length} posts'); // Debug log
        setState(() {
          userPosts = posts;
        });
      }
    } catch (e) {
      print('Error loading user posts: $e');
    }
  }

  Future<void> _updateBio() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestoreService.updateUserBio(user.uid, _bioController.text);
        
        setState(() {
          userData = userData?.copyWith(bio: _bioController.text);
        });
        
        _showSuccessMessage('Bio updated successfully');
      }
    } catch (e) {
      print('Error updating bio: $e');
      _showErrorMessage('Failed to update bio');
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      print('Error signing out: $e');
      _showErrorMessage('Failed to sign out');
    }
  }

  void _showMediaTypeSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MediaSelectionBottomSheet(
        onPhotoSelected: () => _mediaService.showImageSourceSelection(
          context,
          onMediaSelected: _createPost,
        ),
        onVideoSelected: () => _mediaService.showVideoSourceSelection(
          context,
          onMediaSelected: _createPost,
        ),
      ),
    );
  }

  void _createPost(File mediaFile, {required bool isVideo}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PostCreationDialog(
        mediaFile: mediaFile,
        isVideo: isVideo,
        isUploading: isUploading,
        onPost: (caption) => _uploadPost(mediaFile, caption, isVideo: isVideo),
      ),
    );
  }

  Future<void> _uploadPost(File file, String caption, {required bool isVideo}) async {
    setState(() {
      isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create post with proper media type
        await _firestoreService.createPost(
          userId: user.uid,
          userName: userData?.name ?? 'User',
          mediaFile: file,
          caption: caption,
          isVideo: isVideo,
        );

        // Close dialog first
        Navigator.pop(context);
        
        // Then refresh data
        await _loadUserData();
        await _loadUserPosts();

        _showSuccessMessage('Post uploaded successfully!');
      }
    } catch (e) {
      print('Error uploading post: $e');
      _showErrorMessage('Failed to upload post: ${e.toString()}');
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  void _showEditProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditProfileBottomSheet(
        bioController: _bioController,
        onSave: () {
          _updateBio();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SettingsBottomSheet(
        onSignOut: () {
          Navigator.pop(context);
          _signOut();
        },
      ),
    );
  }

  void _shareProfile() {
    _showInfoMessage('Profile sharing feature coming soon');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          userData?.name ?? 'Profile',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showMediaTypeSelection,
            icon: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
          IconButton(
            onPressed: _showSettingsBottomSheet,
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeader(
              userData: userData,
              onEditProfile: _showEditProfileBottomSheet,
              onShareProfile: _shareProfile,
            ),
            Container(
              height: 1,
              color: Colors.grey.shade800,
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),
            // Debug info - remove in production
            if (userPosts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Posts: ${userPosts.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            PostsGrid(
              posts: userPosts,
              isEmpty: userPosts.isEmpty,
            ),
          ],
        ),
      ),
    );
  }
}