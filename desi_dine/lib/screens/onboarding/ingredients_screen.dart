import 'package:flutter/material.dart';

/// Ingredients selection screen for onboarding
class IngredientsScreen extends StatelessWidget {
  const IngredientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: Text('Ingredients Screen - Select ingredients you prefer to use or avoid'),
      ),
    );
  }
} 