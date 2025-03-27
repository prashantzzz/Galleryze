import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Settings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            // Settings sections
            _buildSettingsSection(
              context: context,
              title: 'Appearance',
              icon: Icons.color_lens,
              children: [
                _buildSettingItem(
                  title: 'Dark Mode',
                  description: 'Enable dark mode',
                  child: Switch(
                    value: false, // Placeholder - not implemented
                    onChanged: (value) {
                      // Implement dark mode toggle
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dark mode coming soon!'),
                        ),
                      );
                    },
                  ),
                ),
                _buildSettingItem(
                  title: 'Grid Size',
                  description: 'Adjust photo grid density',
                  child: DropdownButton<String>(
                    value: 'Medium',
                    underline: Container(),
                    items: ['Small', 'Medium', 'Large']
                        .map((size) => DropdownMenuItem(
                              value: size,
                              child: Text(size),
                            ))
                        .toList(),
                    onChanged: (value) {
                      // Implement grid size change
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Grid size adjustment coming soon!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            _buildSettingsSection(
              context: context,
              title: 'Storage',
              icon: Icons.storage,
              children: [
                _buildSettingItem(
                  title: 'Cache Size',
                  description: 'Manage app cache',
                  child: TextButton(
                    child: const Text('Clear Cache'),
                    onPressed: () {
                      // Implement cache clearing
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cache cleared!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            _buildSettingsSection(
              context: context,
              title: 'Privacy',
              icon: Icons.lock,
              children: [
                _buildSettingItem(
                  title: 'App Lock',
                  description: 'Secure your photos with a PIN',
                  child: Switch(
                    value: false, // Placeholder - not implemented
                    onChanged: (value) {
                      // Implement app lock toggle
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('App lock coming soon!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            _buildSettingsSection(
              context: context,
              title: 'About',
              icon: Icons.info,
              children: [
                _buildSettingItem(
                  title: 'Version',
                  description: 'Current app version',
                  child: const Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildSettingItem(
                  title: 'Feedback',
                  description: 'Send feedback to developers',
                  child: TextButton(
                    child: const Text('Send'),
                    onPressed: () {
                      // Implement feedback mechanism
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Feedback option coming soon!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Upgrade to PRO section at the bottom
            _buildProUpgradeCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildProUpgradeCard(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Text('PRO', style: TextStyle(color: Colors.blue)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upgrade to PRO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Get unlimited categories, cloud sync and more',
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  _showProUpgradeDialog(context);
                },
                child: const Text('Upgrade Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to PRO'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unlock premium features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _FeatureItem(icon: Icons.category, text: 'Unlimited categories'),
            _FeatureItem(icon: Icons.sort, text: 'Advanced sorting options'),
            _FeatureItem(icon: Icons.cloud_upload, text: 'Cloud backup'),
            _FeatureItem(icon: Icons.block, text: 'No ads'),
            SizedBox(height: 16),
            Text(
              '\$4.99/month or \$49.99/year',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PRO features coming soon!'),
                ),
              );
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}