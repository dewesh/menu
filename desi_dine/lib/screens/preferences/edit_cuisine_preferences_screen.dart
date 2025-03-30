import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

/// Screen for editing cuisine preferences
class EditCuisinePreferencesScreen extends StatefulWidget {
  const EditCuisinePreferencesScreen({super.key});

  @override
  State<EditCuisinePreferencesScreen> createState() => _EditCuisinePreferencesScreenState();
}

class _EditCuisinePreferencesScreenState extends State<EditCuisinePreferencesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  String? _userId;
  User? _user;
  
  // Map to track slider values (0.0 to 1.0)
  final Map<String, double> _sliderValues = {};
  
  // Define major cuisine types - same as onboarding
  final List<Map<String, dynamic>> _cuisineTypes = [
    {
      'type': 'North Indian',
      'description': 'Punjabi, Delhi style curries, naan, roti',
      'icon': Icons.soup_kitchen,
    },
    {
      'type': 'South Indian',
      'description': 'Dosa, idli, sambhar, rasam',
      'icon': Icons.breakfast_dining,
    },
    {
      'type': 'Bengali',
      'description': 'Fish curries, sweets, mustard flavors',
      'icon': Icons.set_meal,
    },
    {
      'type': 'Gujarati',
      'description': 'Thepla, dhokla, vegetarian thali',
      'icon': Icons.lunch_dining,
    },
    {
      'type': 'Maharashtrian',
      'description': 'Vada pav, misal pav, puran poli',
      'icon': Icons.fastfood,
    },
    {
      'type': 'Indo-Chinese',
      'description': 'Manchurian, hakka noodles, fried rice',
      'icon': Icons.restaurant,
    },
    {
      'type': 'Mughlai',
      'description': 'Biryani, kebabs, rich gravies',
      'icon': Icons.dinner_dining,
    },
    {
      'type': 'Kerala',
      'description': 'Appam, stew, coconut-based curries',
      'icon': Icons.agriculture,
    },
    {
      'type': 'Street Food',
      'description': 'Chaat, pani puri, bhel puri',
      'icon': Icons.storefront,
    },
    {
      'type': 'Healthy Modern',
      'description': 'Fusion, diet-friendly Indian dishes',
      'icon': Icons.spa,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get the user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(Constants.prefUserId);
      
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User ID not found. Please complete onboarding first.';
        });
        return;
      }
      
      _userId = userId;
      
      // Initialize slider values to default (middle position)
      for (var cuisine in _cuisineTypes) {
        _sliderValues[cuisine['type']] = 0.5;
      }
      
      // Load user data to get current preferences
      final userService = UserService.instance;
      final user = await userService.getUserById(userId);
      
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not found. Please complete onboarding first.';
        });
        return;
      }
      
      _user = user;
      
      // Update sliders with current preferences
      for (var pref in user.systemPreferences.cuisinePreferences) {
        // Convert frequency to slider value
        double sliderValue;
        switch (pref.frequencyPreference) {
          case 'daily':
            sliderValue = 0.9;
            break;
          case 'weekly':
            sliderValue = 0.7;
            break;
          case 'occasionally':
            sliderValue = 0.5;
            break;
          case 'rarely':
            sliderValue = 0.3;
            break;
          default:
            sliderValue = 0.5;
        }
        
        _sliderValues[pref.cuisineType] = sliderValue;
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading user data: ${e.toString()}';
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_user == null || _userId == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final userService = UserService.instance;
      
      // Create updated preferences
      final updatedPreferences = _user!.systemPreferences;
      final updatedCuisinePreferences = _getPreferencesFromSliders();
      
      // Create updated user object
      final updatedSystemPreferences = SystemPreferences(
        themeMode: updatedPreferences.themeMode,
        notificationsEnabled: updatedPreferences.notificationsEnabled,
        isDarkMode: updatedPreferences.isDarkMode,
        familySize: updatedPreferences.familySize,
        dietaryPreferences: updatedPreferences.dietaryPreferences,
        cuisinePreferences: updatedCuisinePreferences,
        familyMembers: updatedPreferences.familyMembers,
        healthConditions: updatedPreferences.healthConditions,
        tastePreferences: updatedPreferences.tastePreferences,
      );
      
      // Update the user
      await userService.updateUserPreferences(_userId!, updatedSystemPreferences);
      
      setState(() {
        _isSaving = false;
      });
      
      // Show success message and return to previous screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuisine preferences updated successfully! Your meal plan will refresh automatically.'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Error saving preferences: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Frequency text based on slider value
  String _getFrequencyText(double value) {
    if (value < 0.25) return 'Rarely';
    if (value < 0.5) return 'Occasionally';
    if (value < 0.75) return 'Weekly';
    return 'Daily';
  }
  
  // Frequency color based on slider value
  Color _getFrequencyColor(double value) {
    if (value < 0.25) return Colors.red;
    if (value < 0.5) return Colors.orange;
    if (value < 0.75) return Colors.blue;
    return Colors.green;
  }
  
  // Get CuisinePreference objects from slider values
  List<CuisinePreference> _getPreferencesFromSliders() {
    List<CuisinePreference> preferences = [];
    _sliderValues.forEach((type, value) {
      String frequency;
      if (value < 0.25) frequency = 'rarely';
      else if (value < 0.5) frequency = 'occasionally'; 
      else if (value < 0.75) frequency = 'weekly';
      else frequency = 'daily';
      
      preferences.add(CuisinePreference(
        cuisineType: type,
        frequencyPreference: frequency,
      ));
    });
    return preferences;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Cuisine Preferences'),
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton.icon(
              onPressed: _savePreferences,
              icon: const Icon(Icons.check),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade300,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade300),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How often would you like to cook these cuisines?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your meal plan will automatically update based on these preferences.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              
              // List of cuisine sliders
              Expanded(
                child: ListView.builder(
                  itemCount: _cuisineTypes.length,
                  itemBuilder: (context, index) {
                    final cuisine = _cuisineTypes[index];
                    final type = cuisine['type'];
                    final value = _sliderValues[type] ?? 0.5;
                    final frequencyText = _getFrequencyText(value);
                    final frequencyColor = _getFrequencyColor(value);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cuisine name and icon
                            Row(
                              children: [
                                Icon(
                                  cuisine['icon'],
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  type,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Description
                            Padding(
                              padding: const EdgeInsets.only(left: 36, top: 4),
                              child: Text(
                                cuisine['description'],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Slider and value label
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: value,
                                    onChanged: (newValue) {
                                      setState(() {
                                        _sliderValues[type] = newValue;
                                      });
                                    },
                                    activeColor: AppTheme.primaryColor,
                                    inactiveColor: AppTheme.primaryColorLight.withOpacity(0.3),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: frequencyColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    frequencyText,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: frequencyColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Saving indicator
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Saving preferences...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 