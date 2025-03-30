import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Completion screen for onboarding
class CompleteScreen extends StatelessWidget {
  const CompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          
          Text(
            'All Set!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Thank you for providing your preferences. We\'re ready to create personalized meal plans for you!',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          const Text(
            'Press "Finish" to start your journey with DesiDine!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
} 