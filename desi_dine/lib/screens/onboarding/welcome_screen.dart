import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Welcome screen for onboarding
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App logo or image
          Icon(
            Icons.restaurant,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          
          // Welcome title
          Text(
            'Welcome to ${Constants.appName}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Description
          Text(
            'Your personal Indian cuisine meal planner for delicious and healthy homemade meals.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // Get started description
          const Text(
            'Let\'s set up your meal preferences to create personalized meal plans just for you!',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 