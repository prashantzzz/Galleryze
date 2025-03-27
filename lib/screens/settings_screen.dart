import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Appearance'),
          _buildSettingTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            description: 'Switch between light and dark theme',
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // Implement dark mode toggle
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.grid_view,
            title: 'Grid Size',
            description: 'Adjust the photo grid appearance',
            onTap: () {
              _showGridSizeDialog(context);
            },
          ),
          const Divider(),
          _buildSectionHeader('Storage'),
          _buildSettingTile(
            icon: Icons.storage,
            title: 'Storage Usage',
            description: 'View and manage app storage',
            onTap: () {
              // Implement storage management
            },
          ),
          _buildSettingTile(
            icon: Icons.cloud_upload,
            title: 'Backup & Sync',
            description: 'Manage cloud backups (PRO)',
            trailing: const Icon(Icons.lock, color: Colors.grey),
            onTap: () {
              _showProFeatureDialog(context);
            },
          ),
          const Divider(),
          _buildSectionHeader('About'),
          _buildSettingTile(
            icon: Icons.info,
            title: 'About Galleryze',
            description: 'Version 1.0.0',
            onTap: () {
              // Show about dialog
            },
          ),
          _buildSettingTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            description: 'Read our privacy policy',
            onTap: () {
              // Show privacy policy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String description,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(description),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showGridSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grid Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGridSizeOption(context, 'Compact', 3),
            const Divider(),
            _buildGridSizeOption(context, 'Standard', 2),
            const Divider(),
            _buildGridSizeOption(context, 'Large', 1),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildGridSizeOption(BuildContext context, String label, int columns) {
    return ListTile(
      title: Text(label),
      trailing: Radio<int>(
        value: columns,
        groupValue: 2, // Default value
        onChanged: (value) {
          // Implement grid size change
          Navigator.pop(context);
        },
      ),
      onTap: () {
        // Implement grid size change
        Navigator.pop(context);
      },
    );
  }

  void _showProFeatureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PRO Feature'),
        content: const Text(
          'This feature is available only in the PRO version of Galleryze.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Show purchase dialog
            },
            child: const Text('Upgrade to PRO'),
          ),
        ],
      ),
    );
  }
}