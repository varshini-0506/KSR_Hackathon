import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _alertSensitivity = 'Normal';
  bool _offlineMode = false;
  String _selectedLanguage = 'English';
  bool _batteryOptimization = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Alert Sensitivity
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alert Sensitivity',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ...['Low', 'Normal', 'High', 'Elderly'].map((mode) {
                      return RadioListTile<String>(
                        title: Text(mode),
                        value: mode,
                        groupValue: _alertSensitivity,
                        onChanged: (value) {
                          setState(() {
                            _alertSensitivity = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // SOS Trigger Preferences
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.emergency, color: AppTheme.primaryColor),
                    title: const Text('SOS Trigger Preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('SOS Trigger Options'),
                          content: const Text(
                            '• Press & Hold SOS button\n'
                            '• Shake device 3 times\n'
                            '• Power button 5 times\n'
                            '• Voice command "Help"',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Offline Mode
            Card(
              child: SwitchListTile(
                title: const Text('Offline Mode'),
                subtitle: const Text('Work without internet connection'),
                value: _offlineMode,
                onChanged: (value) {
                  setState(() {
                    _offlineMode = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Language
            Card(
              child: ListTile(
                leading: Icon(Icons.language, color: AppTheme.primaryColor),
                title: const Text('Language'),
                subtitle: Text(_selectedLanguage),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Select Language',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ...['English', 'Hindi', 'Tamil', 'Telugu', 'Kannada', 'Malayalam']
                              .map((lang) {
                            return ListTile(
                              title: Text(lang),
                              trailing: _selectedLanguage == lang
                                  ? Icon(Icons.check, color: AppTheme.primaryColor)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedLanguage = lang;
                                });
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Battery Optimization
            Card(
              child: SwitchListTile(
                title: const Text('Battery Optimization Mode'),
                subtitle: const Text('Reduce background activity to save battery'),
                value: _batteryOptimization,
                onChanged: (value) {
                  setState(() {
                    _batteryOptimization = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Accessibility Options
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.accessibility_new, color: AppTheme.primaryColor),
                    title: const Text('Accessibility Options'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Accessibility'),
                          content: const Text(
                            '• Large text\n'
                            '• High contrast\n'
                            '• Voice announcements\n'
                            '• Haptic feedback',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Other Settings Links
            _buildSettingsTile(
              Icons.privacy_tip,
              'Privacy & Permissions',
              () => context.go('/privacy'),
            ),
            _buildSettingsTile(
              Icons.history,
              'Alert History',
              () => context.go('/alert-history'),
            ),
            _buildSettingsTile(
              Icons.help_outline,
              'Help & Support',
              () {},
            ),
            _buildSettingsTile(
              Icons.info_outline,
              'About',
              () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Vigil',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2026 Vigil. All rights reserved.',
                );
              },
            ),
          ],
        ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
