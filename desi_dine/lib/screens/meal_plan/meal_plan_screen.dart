import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/meal_plan_model.dart';
import '../../services/meal_plan_service.dart';
import '../../utils/constants.dart';
import 'generate_meal_plan_screen.dart';

/// Meal Plan screen showing weekly meal plan
class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<MealPlan> _mealPlans = [];
  MealPlan? _selectedMealPlan;

  @override
  void initState() {
    super.initState();
    _loadMealPlans();
  }

  Future<void> _loadMealPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get the current user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(Constants.prefUserId);
      
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User ID not found. Please complete onboarding first.';
        });
        return;
      }
      
      // Load meal plans
      final mealPlanService = MealPlanService.instance;
      final mealPlans = await mealPlanService.getMealPlansForUser(userId);
      
      setState(() {
        _mealPlans = mealPlans;
        _selectedMealPlan = mealPlans.isNotEmpty ? mealPlans.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading meal plans: ${e.toString()}';
      });
    }
  }

  Future<void> _navigateToGenerateMealPlan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GenerateMealPlanScreen()),
    );
    
    if (result != null && result is MealPlan) {
      setState(() {
        _mealPlans = [result, ..._mealPlans];
        _selectedMealPlan = result;
      });
    }
  }

  Future<void> _toggleFavorite(MealPlan mealPlan) async {
    try {
      final mealPlanService = MealPlanService.instance;
      final updatedMealPlan = await mealPlanService.toggleMealPlanFavorite(mealPlan);
      
      setState(() {
        // Update the meal plan in the list
        final index = _mealPlans.indexWhere((plan) => plan.mealPlanId == mealPlan.mealPlanId);
        if (index >= 0) {
          _mealPlans[index] = updatedMealPlan;
        }
        
        // Update selected meal plan if it's the one toggled
        if (_selectedMealPlan?.mealPlanId == mealPlan.mealPlanId) {
          _selectedMealPlan = updatedMealPlan;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorite status: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMealPlans,
            tooltip: 'Refresh meal plans',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade300,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade300),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadMealPlans,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _mealPlans.isEmpty
                  ? _buildEmptyState()
                  : _buildMealPlanView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToGenerateMealPlan,
        label: const Text('New Plan'),
        icon: const Icon(Icons.add),
        tooltip: 'Generate new meal plan',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              color: Colors.grey.shade400,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Meal Plans Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create your first meal plan to get personalized recipes based on your preferences.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToGenerateMealPlan,
              icon: const Icon(Icons.add),
              label: const Text('Create Meal Plan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealPlanView() {
    return Column(
      children: [
        // Meal plan selector
        Container(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedMealPlan?.mealPlanId,
                  hint: const Text('Select a meal plan'),
                  onChanged: (String? mealPlanId) {
                    if (mealPlanId != null) {
                      final selectedPlan = _mealPlans.firstWhere(
                        (plan) => plan.mealPlanId == mealPlanId,
                      );
                      setState(() {
                        _selectedMealPlan = selectedPlan;
                      });
                    }
                  },
                  items: _mealPlans.map<DropdownMenuItem<String>>((MealPlan plan) {
                    return DropdownMenuItem<String>(
                      value: plan.mealPlanId,
                      child: Row(
                        children: [
                          Icon(
                            plan.isFavorite ? Icons.star : Icons.calendar_today,
                            color: plan.isFavorite
                                ? Colors.amber
                                : Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              plan.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (_selectedMealPlan != null)
                IconButton(
                  icon: Icon(
                    _selectedMealPlan!.isFavorite ? Icons.star : Icons.star_border,
                    color: _selectedMealPlan!.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: () => _toggleFavorite(_selectedMealPlan!),
                  tooltip: _selectedMealPlan!.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                ),
            ],
          ),
        ),
        
        // Days and meals
        if (_selectedMealPlan != null)
          Expanded(
            child: _buildMealPlanDays(_selectedMealPlan!),
          ),
      ],
    );
  }

  Widget _buildMealPlanDays(MealPlan mealPlan) {
    return ListView.builder(
      itemCount: mealPlan.days.length,
      itemBuilder: (context, index) {
        final day = mealPlan.days[index];
        return ExpansionTile(
          initiallyExpanded: index == 0, // Expand the first day by default
          title: Text('Day ${day.dayNumber}'),
          children: [
            _buildMealCard('Breakfast', day.breakfast),
            _buildMealCard('Lunch', day.lunch),
            _buildMealCard('Dinner', day.dinner),
            _buildMealCard('Snack', day.snack),
          ],
        );
      },
    );
  }

  Widget _buildMealCard(String mealType, Meal meal) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    mealType,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                if (meal.cuisineType != null)
                  Text(
                    meal.cuisineType!,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              meal.name,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Ingredients
            if (meal.ingredients.isNotEmpty) ...[
              const Text(
                'Ingredients:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4.0),
              Wrap(
                spacing: 8.0,
                children: meal.ingredients.map((ingredient) {
                  return Chip(
                    label: Text(
                      '${ingredient.name} (${ingredient.quantity})',
                      style: const TextStyle(fontSize: 12.0),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16.0),
            ],
            
            // Instructions (truncated)
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4.0),
            Text(
              meal.instructions,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to detailed meal view
              },
              child: const Text('View full recipe'),
            ),
            
            // Nutritional info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionInfo('Calories', '${meal.nutritionalInfo.calories}'),
                _buildNutritionInfo('Protein', '${meal.nutritionalInfo.protein}g'),
                _buildNutritionInfo('Carbs', '${meal.nutritionalInfo.carbs}g'),
                _buildNutritionInfo('Fat', '${meal.nutritionalInfo.fat}g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 