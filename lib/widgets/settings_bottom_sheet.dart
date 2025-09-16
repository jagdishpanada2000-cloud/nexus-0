// lib/widgets/settings_bottom_sheet.dart
import 'package:flutter/material.dart';

class SettingsBottomSheet extends StatelessWidget {
  final VoidCallback onSignOut;

  const SettingsBottomSheet({
    super.key,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHandle(),
          const SizedBox(height: 20),
          _buildSettingsItem(
            Icons.settings_outlined,
            'Settings',
            () => Navigator.pop(context),
          ),
          _buildSettingsItem(
            Icons.bookmark_outline,
            'Saved',
            () => Navigator.pop(context),
          ),
          _buildSettingsItem(
            Icons.qr_code,
            'QR Code',
            () => Navigator.pop(context),
          ),
          const Divider(color: Colors.grey),
          _buildSettingsItem(
            Icons.logout,
            'Sign Out',
            onSignOut,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}