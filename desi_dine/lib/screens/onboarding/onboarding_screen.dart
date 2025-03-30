import 'package:flutter/material.dart';
import '../../services/navigation_service.dart';
import '../../utils/constants.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';
import 'cuisine_screen.dart';
import 'dietary_screen.dart';
import 'family_screen.dart';
import 'taste_screen.dart';
import 'ingredients_screen.dart';
import 'complete_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';

/// Onboarding screen to navigate through the onboarding process
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Store onboarding data
  final String _userId = ''; // Will be set on first save
  String? _name;
  String? _email;
  List<CuisinePreference> _cuisinePreferences = [];
  
  // List of screen widgets
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize pages with callback for CuisineScreen
    _pages = [
      const WelcomeScreen(),
      CuisineScreen(
        onPreferencesChanged: (preferences) {
          _cuisinePreferences = preferences;
        },
      ),
      const DietaryScreen(),
      const FamilyScreen(),
      const TasteScreen(),
      const IngredientsScreen(),
      const CompleteScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  // Save user data to Firebase
  Future<void> _saveUserData() async {
    try {
      // Create or update user
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString(Constants.prefUserId) ?? '';
      
      // Create system preferences with cuisine preferences
      final systemPreferences = SystemPreferences(
        themeMode: 'light',
        cuisinePreferences: _cuisinePreferences,
      );
      
      // Create or update user
      if (userId.isEmpty) {
        // Create new user
        final user = User(
          userId: userId,
          name: _name,
          email: _email,
          createdAt: now,
          lastModified: now,
          systemPreferences: systemPreferences,
        );
        
        final createdUser = await UserService.instance.createUser(user);
        
        // Save user ID to shared preferences
        await prefs.setString(Constants.prefUserId, createdUser.userId);
        
        // Save full cuisine preferences separately
        await _saveFullCuisinePreferences(createdUser.userId);
      } else {
        // Update existing user's preferences
        await UserService.instance.updateUserPreferences(userId, systemPreferences);
        
        // Save full cuisine preferences separately
        await _saveFullCuisinePreferences(userId);
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
      // Show error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    }
  }
  
  // Save full cuisine preferences with frequency
  Future<void> _saveFullCuisinePreferences(String userId) async {
    try {
      // Convert CuisinePreference objects to maps
      final preferenceMaps = _cuisinePreferences.map((pref) => pref.toMap()).toList();
      
      // Update the user document with full cuisine preferences
      await FirebaseService.instance.updateDocument(
        '${Constants.usersCollection}/$userId',
        {
          'fullCuisinePreferences': preferenceMaps,
          'lastModified': Timestamp.fromDate(DateTime.now()),
        },
      );
    } catch (e) {
      debugPrint('Error saving full cuisine preferences: $e');
    }
  }

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // On last page, save final data and complete onboarding
      await _saveUserData();
      await _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await NavigationService.instance.setOnboardingComplete();
    if (context.mounted) {
      NavigationService.instance.navigateToAndRemoveUntil(Constants.routeHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / _pages.length,
              backgroundColor: Colors.grey[300],
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swiping
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: _pages,
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (hide on first page)
                  _currentPage > 0
                      ? ElevatedButton(
                          onPressed: _previousPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Back'),
                        )
                      : const SizedBox(width: 80), // Placeholder for spacing
                  
                  // Next/Finish button
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage < _pages.length - 1 ? 'Next' : 'Finish',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 