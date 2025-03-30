import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/model_test.dart';
import '../../services/service_test.dart';
import '../../services/firebase_service.dart';

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

  Future<void> _viewCuisinePreferences() async {
    // Show a loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Row(
            children: [
              SizedBox(height: 24, width: 24, child: CircularProgressIndicator()),
              SizedBox(width: 16),
              Text('Loading Preferences'),
            ],
          ),
          content: Text('Fetching your cuisine preferences from Firebase...'),
        );
      },
    );
    
    try {
      // Get the user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(Constants.prefUserId);
      
      if (userId == null || userId.isEmpty) {
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found. Complete onboarding first.'))
        );
        return;
      }
      
      // Fetch the user document from Firestore
      final userDoc = await FirebaseService.instance.getDocument('${Constants.usersCollection}/$userId');
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User document not found in Firestore.'))
        );
        return;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Check if fullCuisinePreferences exists
      if (!userData.containsKey('fullCuisinePreferences') || 
          userData['fullCuisinePreferences'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cuisine preferences found with frequency levels.'))
        );
        return;
      }
      
      // Extract the cuisine preferences with their frequency
      final prefList = List<Map<String, dynamic>>.from(userData['fullCuisinePreferences']);
      
      // Show dialog with preferences
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.restaurant),
                  SizedBox(width: 8),
                  Text('Cuisine Preferences'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: prefList.isEmpty 
                  ? const Text('No cuisine preferences saved yet.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: prefList.length,
                      itemBuilder: (context, index) {
                        final pref = prefList[index];
                        final cuisineType = pref['cuisineType'] as String? ?? 'Unknown';
                        final frequency = pref['frequencyPreference'] as String? ?? 'Unknown';
                        
                        String frequencyText;
                        Color frequencyColor;
                        
                        // Set color and text based on frequency
                        switch (frequency) {
                          case 'daily':
                            frequencyText = 'Daily';
                            frequencyColor = Colors.green;
                            break;
                          case 'weekly':
                            frequencyText = 'Weekly';
                            frequencyColor = Colors.blue;
                            break;
                          case 'occasionally':
                            frequencyText = 'Occasionally';
                            frequencyColor = Colors.orange;
                            break;
                          case 'rarely':
                            frequencyText = 'Rarely';
                            frequencyColor = Colors.red;
                            break;
                          default:
                            frequencyText = frequency;
                            frequencyColor = Colors.grey;
                        }
                        
                        return ListTile(
                          title: Text(cuisineType),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 6
                            ),
                            decoration: BoxDecoration(
                              color: frequencyColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              frequencyText,
                              style: TextStyle(
                                color: frequencyColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit functionality will be implemented soon!'))
                    );
                    // TODO: Navigate to a screen for editing cuisine preferences
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 4),
                      Text('Edit'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted) Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching preferences: ${e.toString()}'))
      );
    }
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
      _showTestResultsDialog(testResults, 'Model Test Results');
      
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
  
  Future<void> _runFirebaseTests() async {
    // Show a loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              const Text('Running Firebase Tests'),
            ],
          ),
          content: const Text('Testing CRUD operations for all services. This may take a moment...'),
        );
      },
    );
    
    try {
      // Run the tests
      final testResults = await ServiceTest.testAllServices();
      
      // Close the loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show results in a dialog
      if (mounted) {
        _showTestResultsDialog(testResults, 'Firebase Service Test Results');
      }
      
      // Also show a success snackbar
      if (mounted && testResults.any((result) => result.contains('❌'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Some Firebase tests failed. Check the dialog for details.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All Firebase service tests passed! See results in the dialog.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase tests failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showTestResultsDialog(List<String> results, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                title.contains('Firebase') ? Icons.storage : Icons.science,
                color: Theme.of(context).colorScheme.primary
              ),
              const SizedBox(width: 8),
              Text(title),
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
                if (result.contains('✅ SUCCESS') || result.contains('✅ SERVICE TEST')) {
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(result),
                    dense: true,
                  );
                } else if (result.contains('❌ FAILED') || result.contains('❌ SERVICE TEST')) {
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
            subtitle: const Text('View and update your cuisine preferences with frequency levels'),
            leading: const Icon(Icons.restaurant),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _viewCuisinePreferences,
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
          ListTile(
            title: const Text('Test Firebase Services'),
            subtitle: const Text('Run tests to verify Firebase service operations'),
            trailing: const Icon(Icons.storage),
            onTap: _runFirebaseTests,
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