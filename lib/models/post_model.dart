// lib/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String caption;
  final int likes;
  final int comments;
  final List<String> likedBy;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.mediaUrl,
    required this.mediaType,
    this.caption = '',
    this.likes = 0,
    this.comments = 0,
    this.likedBy = const [],
    this.createdAt,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    // Debug print
    print('Creating PostModel from map: $map');
    
    return PostModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'User',
      mediaUrl: map['mediaUrl'] ?? map['imageUrl'] ?? '',
      mediaType: map['mediaType'] ?? (map['isVideo'] == true ? 'video' : 'image'), // Handle both formats
      caption: map['caption'] ?? '',
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'isVideo': isVideo, // Keep for backward compatibility
      'caption': caption,
      'likes': likes,
      'comments': comments,
      'likedBy': likedBy,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? mediaUrl,
    String? mediaType,
    String? caption,
    int? likes,
    int? comments,
    List<String>? likedBy,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isVideo => mediaType.toLowerCase() == 'video';
  bool get isImage => mediaType.toLowerCase() == 'image';

  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }
}