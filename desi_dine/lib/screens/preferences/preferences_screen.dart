import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/model_test.dart';

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
  
  void _runModelTests() {
    try {
      // Run tests and get results
      final testResults = ModelTest.testAllModels();
      
      // Show results in a dialog
      _showTestResultsDialog(testResults);
      
      // Also show a success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All model tests passed! See results in the dialog.')),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test failed: ${e.toString()}')),
        );
      }
    }
  }
  
  void _showTestResultsDialog(List<String> results) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.science, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Model Test Results'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                // Apply different styling based on result content
                if (result.contains('✅ SUCCESS')) {
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(result),
                    dense: true,
                  );
                } else if (result.contains('❌ FAILED')) {
                  return ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: Text(result),
                    dense: true,
                  );
                } else if (result.startsWith('Testing')) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                    child: Text(
                      result,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(result),
                  );
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
          ListTile(
            title: const Text('Test Data Models'),
            subtitle: const Text('Run tests to verify data models are working correctly'),
            trailing: const Icon(Icons.science),
            onTap: _runModelTests,
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