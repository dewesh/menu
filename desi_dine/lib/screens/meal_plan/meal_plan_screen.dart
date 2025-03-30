import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../models/meal_plan_model.dart';
import '../../models/user_model.dart';
import '../../services/meal_plan_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';

/// Meal Plan screen showing daily meal plan based on calendar dates
class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  bool _isLoading = true;
  bool _isBackgroundUpdating = false; // Track background updates from preference changes
  bool _isManuallyUpdating = false; // Track manual updates via refresh button
  String _errorMessage = '';
  MealPlan? _mealPlan;
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('EEEE, MMM d'); // e.g. "Monday, Jan 1"
  Stream<User?>? _userStream;
  String? _userId;
  int? _lastKnownUpdateTimestamp;
  bool _shouldTriggerUpdate = false;
  bool _showUpdateSuccess = false; // Show success message after update
  
  // Get a clean date without time component
  DateTime _getDateWithoutTime(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _getDateWithoutTime(DateTime.now());
    _setupUserStream();
    _loadLastKnownUpdateTimestamp();
  }
  
  // Load the last known update timestamp from SharedPreferences
  Future<void> _loadLastKnownUpdateTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastKnownUpdateTimestamp = prefs.getInt('last_user_update');
    });
  }

  Future<void> _setupUserStream() async {
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
    
    setState(() {
      _userId = userId;
      _userStream = UserService.instance.streamUser(userId);
    });
    
    // Initial load
    _loadMealPlan();
  }

  Future<void> _loadMealPlan() async {
    if (_userId == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      // This is a manual update, not triggered by preference changes
      _isManuallyUpdating = true;
      _showUpdateSuccess = false;
      // Don't reset _isBackgroundUpdating here - allow both states to be true simultaneously
    });

    try {
      // Load or create meal plan
      final mealPlanService = MealPlanService.instance;
      try {
        final mealPlan = await mealPlanService.getOrCreateMealPlan(userId: _userId!);
        
        setState(() {
          _mealPlan = mealPlan;
          _isLoading = false;
          _isManuallyUpdating = false;
          _showUpdateSuccess = true; // Show success message
          // Keep _isBackgroundUpdating unchanged
        });
        
        // Automatically hide success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showUpdateSuccess = false;
            });
          }
        });
      } catch (e) {
        if (e.toString().contains('FAILED_PRECONDITION') && 
            e.toString().contains('requires an index')) {
          setState(() {
            _isLoading = false;
            _isManuallyUpdating = false;
            _errorMessage = 'Index is still being created. Please wait a few minutes and try again.';
          });
        } else {
          rethrow; // Let the outer catch block handle it
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isManuallyUpdating = false;
        _errorMessage = 'Error loading meal plan: ${e.toString()}';
      });
    }
  }

  // Background update that runs when preferences change
  Future<void> _backgroundUpdateMealPlan() async {
    if (_userId == null) return;
    
    // Set the flag for background updates from preference changes
    setState(() {
      _isBackgroundUpdating = true;
      _shouldTriggerUpdate = false; // Reset trigger flag after starting update
      _showUpdateSuccess = false;
    });
    
    // Debug log to confirm the state change
    print('Background update started: _isBackgroundUpdating = $_isBackgroundUpdating');

    try {
      // Load or create meal plan
      final mealPlanService = MealPlanService.instance;
      try {
        // Start a timer to ensure the loading indicator shows for at least 3 seconds
        // This ensures users can see the indicator even if the update is quick
        final startTime = DateTime.now();
        
        final mealPlan = await mealPlanService.getOrCreateMealPlan(userId: _userId!);
        
        // Calculate how long the update took
        final updateDuration = DateTime.now().difference(startTime);
        
        // If the update was too quick, delay the completion to ensure visibility
        final minimumVisibleDuration = const Duration(seconds: 3);
        if (updateDuration < minimumVisibleDuration) {
          // Wait for the remaining time to reach the minimum visibility duration
          await Future.delayed(minimumVisibleDuration - updateDuration);
        }
        
        if (mounted) {
          setState(() {
            _mealPlan = mealPlan;
            _isBackgroundUpdating = false;
            _showUpdateSuccess = true; // Show success message
          });
          print('Background update completed: _isBackgroundUpdating = $_isBackgroundUpdating');
          
          // Automatically hide success message after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showUpdateSuccess = false;
              });
            }
          });
        }
      } catch (e) {
        print('Error in background update: $e');
        if (mounted) {
          setState(() {
            _isBackgroundUpdating = false;
          });
          print('Background update failed: _isBackgroundUpdating = $_isBackgroundUpdating');
        }
      }
    } catch (e) {
      print('Error in background update: $e');
      if (mounted) {
        setState(() {
          _isBackgroundUpdating = false;
        });
        print('Background update failed: _isBackgroundUpdating = $_isBackgroundUpdating');
      }
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = _getDateWithoutTime(date);
    });
  }

  Future<void> _regenerateDay() async {
    if (_mealPlan == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final mealPlanService = MealPlanService.instance;
      final updatedMealPlan = await mealPlanService.regenerateDay(
        mealPlan: _mealPlan!,
        date: _selectedDate,
      );
      
      setState(() {
        _mealPlan = updatedMealPlan;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Day regenerated successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error regenerating day: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to regenerate day: ${e.toString()}')),
      );
    }
  }

  Future<void> _regenerateMeal(String mealType) async {
    if (_mealPlan == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final mealPlanService = MealPlanService.instance;
      final updatedMealPlan = await mealPlanService.regenerateMeal(
        mealPlan: _mealPlan!,
        date: _selectedDate,
        mealType: mealType,
      );
      
      setState(() {
        _mealPlan = updatedMealPlan;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$mealType regenerated successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to regenerate $mealType: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we need to trigger a background update
    // This approach avoids calling setState during build
    if (_shouldTriggerUpdate) {
      // Use a microtask to avoid calling setState during build
      Future.microtask(() {
        _backgroundUpdateMealPlan();
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
        actions: [
          // DEV ONLY: Temporary refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_isLoading || _isBackgroundUpdating) ? null : _loadMealPlan,
            tooltip: 'DEV: Refresh meal plan',
          ),
          // Add a visual indicator for background updates in the app bar
          if (_isBackgroundUpdating || _isManuallyUpdating)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
      body: _userStream == null
          ? _buildLoadingOrError()
          : StreamBuilder<User?>(
              stream: _userStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _mealPlan == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading user data: ${snapshot.error}'),
                  );
                }
                
                // Check if the user data has changed and needs a refresh
                if (snapshot.hasData && snapshot.data != null) {
                  final user = snapshot.data!;
                  
                  // Check if user has been modified
                  if (user.lastModified != null) {
                    final lastModified = user.lastModified!;
                    final currentTimestamp = lastModified.millisecondsSinceEpoch;
                    
                    // Only trigger an update if:
                    // 1. We have the timestamp from shared preferences
                    // 2. The current timestamp is newer
                    // 3. We're not already updating
                    if (_lastKnownUpdateTimestamp != null && 
                        currentTimestamp > _lastKnownUpdateTimestamp! && 
                        !_isLoading && !_isBackgroundUpdating && !_shouldTriggerUpdate) {
                      
                      print('User preferences changed, refreshing meal plan');
                      print('Current timestamp: $currentTimestamp, Last known: $_lastKnownUpdateTimestamp');
                      
                      // Update last known timestamp
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setInt('last_user_update', currentTimestamp);
                        setState(() {
                          _lastKnownUpdateTimestamp = currentTimestamp;
                          // Set flag to trigger update on next build instead of calling directly
                          _shouldTriggerUpdate = true;
                        });
                      });
                      
                      // Don't call _backgroundUpdateMealPlan() directly from build
                      // We'll use the _shouldTriggerUpdate flag instead
                    }
                  }
                }
                
                // Continue displaying current state while background update happens
                return _buildLoadingOrError();
              },
            ),
    );
  }

  Widget _buildLoadingOrError() {
    // Show main loading indicator only when manually loading, not during background updates
    if (_isLoading && !_isBackgroundUpdating) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      return _buildErrorView();
    } else if (_mealPlan == null) {
      return _buildEmptyState();
    } else {
      return _buildMealPlanView();
    }
  }

  Widget _buildErrorView() {
    return Center(
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
              onPressed: _loadMealPlan,
              child: const Text('Try Again'),
            ),
          ],
        ),
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
              'No Meal Plan Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'We couldn\'t find or create a meal plan based on your preferences.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMealPlan,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
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
    final selectedDayMeals = _getMealsForSelectedDate();
    
    return Column(
      children: [
        // Date selector
        _buildDateSelector(),
        
        // Divider
        const Divider(height: 1),
        
        // Meals for selected date
        if (selectedDayMeals != null)
          Expanded(
            child: _buildDayMeals(selectedDayMeals),
          )
        else
          Expanded(
            child: _buildNoMealsForDate(),
          ),
      ],
    );
  }

  Widget _buildDateSelector() {
    // Get the available dates from the meal plan
    final List<DateTime> availableDates = _mealPlan!.days.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Week of ${_dateFormat.format(availableDates.first)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                
                // Update status indicators for both background/manual updates and success
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Last updated timestamp
                      if (_mealPlan != null)
                        Expanded(
                          child: Text(
                            'Last updated: ${DateFormat('MMM d, yyyy h:mm a').format(_mealPlan!.lastModified)}',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      
                      // Show a prominent update indicator for ANY kind of update
                      if (_isBackgroundUpdating || _isManuallyUpdating)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isManuallyUpdating ? 'Refreshing...' : 'Updating...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Show a success message when update completes
                      if (_showUpdateSuccess && !_isBackgroundUpdating && !_isManuallyUpdating)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Updated!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableDates.length,
              itemBuilder: (context, index) {
                final date = availableDates[index];
                final isSelected = _getDateWithoutTime(date) == _selectedDate;
                final isToday = _getDateWithoutTime(date) == _getDateWithoutTime(DateTime.now());
                
                return GestureDetector(
                  onTap: () => _selectDate(date),
                  child: Container(
                    width: 60,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 16 : 4,
                      right: index == availableDates.length - 1 ? 16 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date), // Day of week abbr
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          DateFormat('d').format(date), // Day number
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        if (isToday && !isSelected)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  MealPlanDay? _getMealsForSelectedDate() {
    if (_mealPlan == null) return null;
    
    // Find the date in the meal plan
    for (final date in _mealPlan!.days.keys) {
      if (_getDateWithoutTime(date) == _selectedDate) {
        return _mealPlan!.days[date];
      }
    }
    
    return null;
  }

  Widget _buildNoMealsForDate() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No meals for ${_dateFormat.format(_selectedDate)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a different date to view meals',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDayMeals(MealPlanDay day) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildMealCard('Breakfast', day.breakfast),
        _buildMealCard('Lunch', day.lunch),
        _buildMealCard('Dinner', day.dinner),
        _buildMealCard('Snack', day.snack),
      ],
    );
  }

  Widget _buildMealCard(String mealType, Meal meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
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