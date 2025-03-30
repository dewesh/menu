/// Constants class for holding app-wide constants
class Constants {
  // Private constructor to prevent instantiation
  Constants._();

  // App Info
  static const String appName = 'DesiDine';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String mealsCollection = 'meals';
  static const String mealPlansCollection = 'mealPlans';
  static const String groceryListsCollection = 'groceryLists';
  
  // Shared Preferences Keys
  static const String prefIsOnboardingComplete = 'isOnboardingComplete';
  static const String prefUserId = 'userId';
  static const String prefThemeMode = 'themeMode';
  
  // Routes
  static const String routeOnboarding = '/onboarding';
  static const String routeHome = '/home';
  static const String routeMealPlan = '/meal-plan';
  static const String routeGrocery = '/grocery';
  static const String routePreferences = '/preferences';
  static const String routeMealDetail = '/meal-detail';
  
  // Onboarding Routes
  static const String routeOnboardingWelcome = '/onboarding/welcome';
  static const String routeOnboardingCuisine = '/onboarding/cuisine';
  static const String routeOnboardingDietary = '/onboarding/dietary';
  static const String routeOnboardingFamily = '/onboarding/family';
  static const String routeOnboardingTaste = '/onboarding/taste';
  static const String routeOnboardingIngredients = '/onboarding/ingredients';
  static const String routeOnboardingComplete = '/onboarding/complete';
  
  // Bottom Navigation Indices
  static const int navIndexHome = 0;
  static const int navIndexMealPlan = 1;
  static const int navIndexGrocery = 2;
  static const int navIndexPreferences = 3;
} 