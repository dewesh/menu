import 'package:flutter/material.dart';

/// Dietary preferences screen for onboarding
class DietaryScreen extends StatelessWidget {
  const DietaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: Text('Dietary Screen - Select your dietary preferences and restrictions'),
      ),
    );
  }
} 