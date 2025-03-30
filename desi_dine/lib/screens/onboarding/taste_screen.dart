import 'package:flutter/material.dart';

/// Taste preferences screen for onboarding
class TasteScreen extends StatelessWidget {
  const TasteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: Text('Taste Screen - Select your taste preferences (spicy, mild, etc.)'),
      ),
    );
  }
} 