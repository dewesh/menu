import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Home screen showing today's meals
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Meals'),
      ),
      body: const Center(
        child: Text('Home Screen - Today\'s Meals will appear here'),
      ),
    );
  }
} 