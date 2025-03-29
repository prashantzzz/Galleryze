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
      body: SingleChildScrollView(
        child: Padding(
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
                icon: Icons.security,
                children: [
                  _buildSettingItem(
                    title: 'Photo Access',
                    description: 'Manage photo permissions',
                    child: TextButton(
                      child: const Text('Manage'),
                      onPressed: () {
                        // Implement permission management
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Permission management coming soon!'),
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
                    description: 'App version information',
                    child: const Text('1.0.0'),
                  ),
                  _buildSettingItem(
                    title: 'Terms of Service',
                    description: 'Read our terms of service',
                    child: TextButton(
                      child: const Text('View'),
                      onPressed: () {
                        // Implement terms view
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Terms of service coming soon!'),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildSettingItem(
                    title: 'Privacy Policy',
                    description: 'Read our privacy policy',
                    child: TextButton(
                      child: const Text('View'),
                      onPressed: () {
                        // Implement privacy policy view
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Privacy policy coming soon!'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey),
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
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          child,
        ],
      ),
    );
  }
}