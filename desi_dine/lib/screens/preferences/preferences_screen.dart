import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferences screen for user settings
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _isDarkMode = false;
  final NavigationService _navigationService = NavigationService.instance;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getString(Constants.prefThemeMode) == 'dark';
    });
  }

  Future<void> _toggleThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.prefThemeMode, isDark ? 'dark' : 'light');
    setState(() {
      _isDarkMode = isDark;
    });
    // Note: App restart needed to see theme change in some cases
  }

  Future<void> _resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.prefIsOnboardingComplete, false);
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onboarding reset successful. Restart the app to see changes.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
      ),
      body: ListView(
        children: [
          // App Theme Section
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
            child: Text(
              'App Theme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme throughout the app'),
            value: _isDarkMode,
            onChanged: _toggleThemeMode,
          ),
          const Divider(),
          
          // User Preferences Section
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0),
            child: Text(
              'User Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Dietary Preferences'),
            subtitle: const Text('Update your dietary restrictions and preferences'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to dietary preferences screen
            },
          ),
          ListTile(
            title: const Text('Cuisine Preferences'),
            subtitle: const Text('Update your regional cuisine preferences'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to cuisine preferences screen
            },
          ),
          ListTile(
            title: const Text('Family Size'),
            subtitle: const Text('Update your family size for meal planning'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to family size screen
            },
          ),
          const Divider(),
          
          // Developer Settings Section
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0),
            child: Text(
              'Developer Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Reset Onboarding'),
            subtitle: const Text('Clear onboarding completion status for testing'),
            trailing: const Icon(Icons.refresh),
            onTap: _resetOnboarding,
          ),
          // App version info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version: ${Constants.appVersion}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
} 