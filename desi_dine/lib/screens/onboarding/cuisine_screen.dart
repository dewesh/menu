import 'package:flutter/material.dart';

/// Cuisine selection screen for onboarding
class CuisineScreen extends StatelessWidget {
  const CuisineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: Text('Cuisine Selection Screen - Select your preferred regional cuisines'),
      ),
    );
  }
} 