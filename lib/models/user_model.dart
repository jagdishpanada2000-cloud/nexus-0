// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String bio;
  final int posts;
  final int followers;
  final int following;
  final Map<String, dynamic>? location;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.bio = '',
    this.posts = 0,
    this.followers = 0,
    this.following = 0,
    this.location,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? 'User',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      posts: map['posts'] ?? 0,
      followers: map['followers'] ?? 0,
      following: map['following'] ?? 0,
      location: map['location'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'bio': bio,
      'posts': posts,
      'followers': followers,
      'following': following,
      'location': location,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? bio,
    int? posts,
    int? followers,
    int? following,
    Map<String, dynamic>? location,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      posts: posts ?? this.posts,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get initials {
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String get locationString {
    if (location != null && 
        location!.containsKey('city') && 
        location!.containsKey('state')) {
      return '${location!['city']}, ${location!['state']}';
    }
    return '';
  }
}