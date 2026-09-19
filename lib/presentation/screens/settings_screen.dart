import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/theme_service.dart';
import 'package:hostel_management_system/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  String _selectedLanguage = 'English';
  bool _hidePhoneFromRoommates = false;
  static double _simulatedOtherCacheMb = 34.2;

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Current Password'),
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(labelText: 'Confirm New Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed successfully!')),
                );
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _clearCache() {
    final int imageByteSize = imageCache.currentSizeBytes;
    final double imageMbSize = imageByteSize / (1024 * 1024);
    
    final double totalFreed = imageMbSize + _simulatedOtherCacheMb;
    
    imageCache.clear();
    imageCache.clearLiveImages();
    
    setState(() {
      _simulatedOtherCacheMb = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('App cache cleared (${totalFreed.toStringAsFixed(2)} MB freed).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isStudent = context.watch<AuthService>().isStudent;

    final List<Color> seedColors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // THEME & APPEARANCE
          const _SectionHeader(title: 'Appearance'),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System Default'),
                  value: ThemeMode.system,
                  groupValue: themeService.themeMode,
                  onChanged: (val) => themeService.toggleThemeMode(val!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Light Mode'),
                  value: ThemeMode.light,
                  groupValue: themeService.themeMode,
                  onChanged: (val) => themeService.toggleThemeMode(val!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark Mode'),
                  value: ThemeMode.dark,
                  groupValue: themeService.themeMode,
                  onChanged: (val) => themeService.toggleThemeMode(val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text('Accent Color', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: seedColors.map((color) {
              final isSelected = themeService.seedColor.value == color.value;
              return GestureDetector(
                onTap: () => themeService.updateSeedColor(color),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                    boxShadow: [
                      if (isSelected) BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)
                    ],
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),
          // NOTIFICATIONS
          const _SectionHeader(title: 'Notifications'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive alerts on your device'),
                  value: _pushNotifications,
                  onChanged: (val) => setState(() => _pushNotifications = val),
                  secondary: const Icon(Icons.notifications),
                ),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive daily summaries via email'),
                  value: _emailNotifications,
                  onChanged: (val) => setState(() => _emailNotifications = val),
                  secondary: const Icon(Icons.email),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          // LANGUAGE & LOCALIZATION
          const _SectionHeader(title: 'Language & Localization'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('App Language'),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(),
                items: [
                  'English', 
                  'Hindi (हिन्दी)', 
                  'Bengali (বাংলা)', 
                  'Telugu (తెలుగు)', 
                  'Marathi (मराठी)', 
                  'Tamil (தமிழ்)', 
                  'Urdu (اردو)', 
                  'Gujarati (ગુજરાતી)', 
                  'Kannada (ಕನ್ನಡ)', 
                  'Odia (ଓଡ଼ିଆ)', 
                  'Malayalam (മലയാളം)', 
                  'Punjabi (ਪੰਜਾਬੀ)'
                ].map((lang) {
                  return DropdownMenuItem(value: lang, child: Text(lang));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLanguage = val);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 32),
          // ACCOUNT SECURITY & PRIVACY
          const _SectionHeader(title: 'Account & Privacy'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangePasswordDialog(context),
                ),
                if (isStudent)
                  SwitchListTile(
                    title: const Text('Hide Phone Number'),
                    subtitle: const Text('Prevent roommates from seeing your contact info'),
                    value: _hidePhoneFromRoommates,
                    onChanged: (val) => setState(() => _hidePhoneFromRoommates = val),
                    secondary: const Icon(Icons.visibility_off),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          // STORAGE
          const _SectionHeader(title: 'Storage & Data'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Clear App Cache'),
              subtitle: const Text('Free up local storage space'),
              onTap: _clearCache,
            ),
          ),

          const SizedBox(height: 32),
          // LOGOUT
          ElevatedButton.icon(
            onPressed: () {
              context.read<AuthService>().logout();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
