import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';

/// Cuisine selection screen for onboarding
class CuisineScreen extends StatefulWidget {
  final void Function(List<CuisinePreference>)? onPreferencesChanged;
  
  const CuisineScreen({
    super.key,
    this.onPreferencesChanged,
  });
  
  @override
  State<CuisineScreen> createState() => _CuisineScreenState();
}

class _CuisineScreenState extends State<CuisineScreen> {
  // List to store cuisine preferences
  final List<CuisinePreference> _cuisinePreferences = [];
  
  // Map to track slider values (0.0 to 1.0)
  final Map<String, double> _sliderValues = {};
  
  // Define major cuisine types
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
    // Initialize slider values to 0.5 (middle position)
    for (var cuisine in _cuisineTypes) {
      _sliderValues[cuisine['type']] = 0.5;
    }
    
    // Send initial preferences with default values
    if (widget.onPreferencesChanged != null) {
      widget.onPreferencesChanged!(_getPreferences());
    }
  }
  
  // Frequency text based on slider value
  String _getFrequencyText(double value) {
    if (value < 0.2) return 'Rarely';
    if (value < 0.4) return 'Sometimes';
    if (value < 0.6) return 'Occasionally';
    if (value < 0.8) return 'Often';
    return 'Frequently';
  }
  
  // Get CuisinePreference objects from slider values
  List<CuisinePreference> _getPreferences() {
    List<CuisinePreference> preferences = [];
    _sliderValues.forEach((type, value) {
      // Include all cuisines with preference levels
      String frequency;
      if (value < 0.2) frequency = 'rarely';
      else if (value < 0.4) frequency = 'rarely';
      else if (value < 0.6) frequency = 'occasionally'; 
      else if (value < 0.8) frequency = 'weekly';
      else frequency = 'daily';
      
      preferences.add(CuisinePreference(
        cuisineType: type,
        frequencyPreference: frequency,
      ));
    });
    return preferences;
  }
  
  // Notify parent when preferences change
  void _updatePreferences() {
    if (widget.onPreferencesChanged != null) {
      widget.onPreferencesChanged!(_getPreferences());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and description
          Text(
            'Cuisine Preferences',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How often would you like to cook these cuisines?',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          
          // Cuisine sliders
          Expanded(
            child: ListView.builder(
              itemCount: _cuisineTypes.length,
              itemBuilder: (context, index) {
                final cuisine = _cuisineTypes[index];
                final type = cuisine['type'];
                final value = _sliderValues[type] ?? 0.5;
                
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
                              style: theme.textTheme.titleMedium?.copyWith(
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
                            style: theme.textTheme.bodyMedium?.copyWith(
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
                                    // Notify parent when preferences change
                                    _updatePreferences();
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
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getFrequencyText(value),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryColor,
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
    );
  }
} 