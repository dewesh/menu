import 'package:flutter/material.dart';
import '../../models/meal_plan_model.dart';
import '../../models/user_model.dart';
import '../../services/meal_plan_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen for generating a new meal plan
class GenerateMealPlanScreen extends StatefulWidget {
  const GenerateMealPlanScreen({super.key});

  @override
  State<GenerateMealPlanScreen> createState() => _GenerateMealPlanScreenState();
}

class _GenerateMealPlanScreenState extends State<GenerateMealPlanScreen> {
  bool _isLoading = false;
  bool _isLoadingUserData = true;
  String _errorMessage = '';
  User? _user;
  
  // Form values
  int _numberOfDays = 7;
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUserData = true;
      _errorMessage = '';
    });
    
    try {
      // Get the current user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(Constants.prefUserId);
      
      if (userId == null) {
        setState(() {
          _isLoadingUserData = false;
          _errorMessage = 'User ID not found. Please complete onboarding first.';
        });
        return;
      }
      
      // Load user data
      final userService = UserService.instance;
      final user = await userService.getUserById(userId);
      
      if (user == null) {
        setState(() {
          _isLoadingUserData = false;
          _errorMessage = 'User not found. Please complete onboarding first.';
        });
        return;
      }
      
      // Generate a default title
      _titleController.text = 'Meal Plan for ${_numberOfDays} days';
      
      setState(() {
        _user = user;
        _isLoadingUserData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUserData = false;
        _errorMessage = 'Error loading user data: ${e.toString()}';
      });
    }
  }
  
  Future<void> _generateMealPlan() async {
    // Validate form
    if (_titleController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a title for the meal plan';
      });
      return;
    }
    
    if (_user == null) {
      setState(() {
        _errorMessage = 'User data not loaded. Please try again.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Get preferences from user
      final familySize = _user!.systemPreferences.familySize;
      final dietaryPreferences = _user!.systemPreferences.dietaryPreferences;
      final cuisinePreferences = _user!.systemPreferences.cuisinePreferences;
      
      // Additional preferences (could be expanded in the future)
      final additionalPreferences = {
        'healthConditions': _user!.systemPreferences.healthConditions.map((c) => c.condition).toList(),
        'tastePreferences': _user!.systemPreferences.tastePreferences.toMap(),
      };
      
      // Generate the meal plan
      final mealPlanService = MealPlanService.instance;
      final mealPlan = await mealPlanService.generateMealPlan(
        userId: _user!.userId,
        cuisinePreferences: cuisinePreferences,
        dietaryPreferences: dietaryPreferences,
        familySize: familySize,
        numberOfDays: _numberOfDays,
        title: _titleController.text,
        additionalPreferences: additionalPreferences,
      );
      
      // Navigate to the meal plan screen with the generated plan
      if (mounted) {
        Navigator.of(context).pop(mealPlan);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error generating meal plan: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Meal Plan'),
      ),
      body: _isLoadingUserData 
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }
  
  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Meal Plan Title',
              hintText: 'Enter a title for your meal plan',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Number of days
          const Text(
            'Number of Days',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Slider(
            value: _numberOfDays.toDouble(),
            min: 1,
            max: 14,
            divisions: 13,
            label: _numberOfDays.toString(),
            onChanged: (value) {
              setState(() {
                _numberOfDays = value.round();
                // Update the title
                if (_titleController.text.startsWith('Meal Plan for ')) {
                  _titleController.text = 'Meal Plan for $_numberOfDays days';
                }
              });
            },
          ),
          Text(
            '$_numberOfDays ${_numberOfDays == 1 ? 'day' : 'days'}',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // User preferences summary
          if (_user != null) ...[
            const Text(
              'Your Preferences',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Family Size: ${_user!.systemPreferences.familySize}'),
                    const SizedBox(height: 8.0),
                    Text(
                      'Dietary Preferences: ${_user!.systemPreferences.dietaryPreferences.isEmpty ? 'None' : _user!.systemPreferences.dietaryPreferences.join(", ")}',
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Cuisine Preferences: ${_user!.systemPreferences.cuisinePreferences.isEmpty ? 'None' : _user!.systemPreferences.cuisinePreferences.map((p) => "${p.cuisineType} (${p.frequencyPreference})").join(", ")}',
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const Spacer(),
          
          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _generateMealPlan,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                        SizedBox(width: 8.0),
                        Text('Generating...'),
                      ],
                    )
                  : const Text('Generate Meal Plan'),
            ),
          ),
          
          if (_isLoading) ...[
            const SizedBox(height: 16.0),
            const Text(
              'This may take a few moments. The AI is creating personalized meals based on your preferences.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
} 