import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Meal Plan screen showing weekly meal plan
class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meal Plan'),
      ),
      body: const Center(
        child: Text('Meal Plan Screen - Weekly meal plan will appear here'),
      ),
    );
  }
} 