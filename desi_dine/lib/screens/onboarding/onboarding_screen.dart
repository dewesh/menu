import 'package:flutter/material.dart';
import '../../services/navigation_service.dart';
import '../../utils/constants.dart';
import 'welcome_screen.dart';
import 'cuisine_screen.dart';
import 'dietary_screen.dart';
import 'family_screen.dart';
import 'taste_screen.dart';
import 'ingredients_screen.dart';
import 'complete_screen.dart';

/// Onboarding screen to navigate through the onboarding process
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<Widget> _pages = [
    const WelcomeScreen(),
    const CuisineScreen(),
    const DietaryScreen(),
    const FamilyScreen(),
    const TasteScreen(),
    const IngredientsScreen(),
    const CompleteScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // On last page, complete onboarding
      _completeOnboarding();
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
    NavigationService.instance.navigateToAndRemoveUntil(Constants.routeHome);
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