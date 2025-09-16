// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'cloudinary_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new post
  Future<void> createPost({
    required String userId,
    required String userName,
    required File mediaFile,
    required String caption,
    required bool isVideo,
  }) async {
    try {
      print('Creating post for user: $userId');
      
      // First upload media to Cloudinary (you need to implement this)
      final mediaUrl = await _uploadToCloudinary(mediaFile, isVideo);
      print('Media uploaded to: $mediaUrl');
      
      // Create post data
      final postData = {
        'userId': userId,
        'userName': userName,
        'mediaUrl': mediaUrl,
        'mediaType': isVideo ? 'video' : 'image',
        'isVideo': isVideo, // Keep for backward compatibility
        'caption': caption,
        'likes': 0,
        'comments': 0,
        'likedBy': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      print('Post data to save: $postData');
      
      // Save to Firestore
      final docRef = await _firestore.collection('posts').add(postData);
      print('Post saved with ID: ${docRef.id}');
      
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  // Get user's posts
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      print('Getting posts for user: $userId');
      
      final querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      print('Found ${querySnapshot.docs.length} posts in Firestore');
      
      final posts = <PostModel>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print('Processing post ${doc.id}: $data');
          
          final post = PostModel.fromMap(data, doc.id);
          posts.add(post);
          print('Successfully created PostModel: ${post.id}, mediaUrl: ${post.mediaUrl}, mediaType: ${post.mediaType}');
        } catch (e) {
          print('Error processing post ${doc.id}: $e');
          continue; // Skip this post but continue with others
        }
      }
      
      print('Returning ${posts.length} posts');
      return posts;
      
    } catch (e) {
      print('Error getting user posts: $e');
      // If orderBy fails (no index), try without ordering
      try {
        print('Retrying without orderBy...');
        final querySnapshot = await _firestore
            .collection('posts')
            .where('userId', isEqualTo: userId)
            .get();
        
        print('Found ${querySnapshot.docs.length} posts without ordering');
        
        final posts = <PostModel>[];
        
        for (var doc in querySnapshot.docs) {
          try {
            final data = doc.data();
            print('Processing post ${doc.id}: $data');
            
            final post = PostModel.fromMap(data, doc.id);
            posts.add(post);
          } catch (e) {
            print('Error processing post ${doc.id}: $e');
            continue;
          }
        }
        
        // Sort manually by createdAt if available
        posts.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        
        return posts;
        
      } catch (e2) {
        print('Error in fallback query: $e2');
        return [];
      }
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      print('Getting user data for: $userId');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data();
        print('User data found: $data');
        return UserModel.fromMap(data!, userId);
      } else {
        print('User document does not exist');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user bio
  Future<void> updateUserBio(String userId, String bio) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Bio updated successfully');
    } catch (e) {
      print('Error updating bio: $e');
      rethrow;
    }
  }

  // Check if posts collection exists and has data
  Future<void> debugPostsCollection() async {
    try {
      print('=== DEBUG: Checking posts collection ===');
      
      final snapshot = await _firestore.collection('posts').limit(10).get();
      print('Total posts in collection: ${snapshot.docs.length}');
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('Post ${doc.id}: userId=${data['userId']}, mediaUrl=${data['mediaUrl']}, mediaType=${data['mediaType']}');
      }
      
      // Check current user's posts specifically
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('=== Checking current user posts: ${currentUser.uid} ===');
        final userPosts = await _firestore
            .collection('posts')
            .where('userId', isEqualTo: currentUser.uid)
            .get();
        print('Current user has ${userPosts.docs.length} posts');
      }
      
    } catch (e) {
      print('Error in debug: $e');
    }
  }

  // Placeholder for Cloudinary upload - you need to implement this
Future<String> _uploadToCloudinary(File file, bool isVideo) async {
  final cloudinaryService = CloudinaryService();
  return await cloudinaryService.uploadMedia(file, isVideo: isVideo);
}

// End of FirestoreService class
}