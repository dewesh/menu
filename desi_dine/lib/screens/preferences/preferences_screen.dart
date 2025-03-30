import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Preferences screen for user settings
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
      ),
      body: const Center(
        child: Text('Preferences Screen - User settings will appear here'),
      ),
    );
  }
} 