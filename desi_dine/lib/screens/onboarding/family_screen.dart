import 'package:flutter/material.dart';

/// Family size screen for onboarding
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: Text('Family Screen - Enter information about your family size'),
      ),
    );
  }
} 