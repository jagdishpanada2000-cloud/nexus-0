// lib/widgets/profile_header.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel? userData;
  final VoidCallback onEditProfile;
  final VoidCallback onShareProfile;

  const ProfileHeader({
    super.key,
    required this.userData,
    required this.onEditProfile,
    required this.onShareProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _buildProfileAvatar(),
              const SizedBox(width: 30),
              Expanded(
                child: _buildStatsRow(),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildUserInfo(),
          const SizedBox(height: 15),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey.shade800,
        child: Text(
          userData?.initials ?? 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn(
          (userData?.posts ?? 0).toString(),
          'Posts',
        ),
        _buildStatColumn(
          (userData?.followers ?? 0).toString(),
          'Followers',
        ),
        _buildStatColumn(
          (userData?.following ?? 0).toString(),
          'Following',
        ),
      ],
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
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userData?.name ?? 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (userData?.bio.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              userData!.bio,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
          if (userData?.locationString.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  userData!.locationString,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Edit profile',
            onEditProfile,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            'Share profile',
            onShareProfile,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 35,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
} 