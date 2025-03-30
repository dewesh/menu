import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Grocery screen showing shopping list
class GroceryScreen extends StatelessWidget {
  const GroceryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
      ),
      body: const Center(
        child: Text('Grocery Screen - Shopping list will appear here'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add grocery item functionality
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
} 