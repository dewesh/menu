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
  static const String ingredientsCollection = 'ingredients';
  static const String aiConfigCollection = 'aiConfig';
  
  // Shared Preferences Keys
  static const String prefIsOnboardingComplete = 'isOnboardingComplete';
  static const String prefUserId = 'userId';
  static const String prefThemeMode = 'themeMode';
  static const String prefAIProviderConfig = 'aiProviderConfig';
  
  // AI Provider Types
  static const String aiProviderOpenAI = 'openai';
  static const String aiProviderAnthropic = 'anthropic';
  static const String aiProviderGoogle = 'google';
  
  // Default AI Models
  static const String aiModelOpenAI = 'gpt-3.5-turbo';
  static const String aiModelAnthropic = 'claude-2';
  static const String aiModelGoogle = 'gemini-pro';
  
  // Remote Config Keys
  static const String remoteConfigAiProvider = 'ai_provider';
  static const String remoteConfigOpenAiKey = 'openai_api_key';
  static const String remoteConfigOpenAiModel = 'openai_model';
  static const String remoteConfigAnthropicKey = 'anthropic_api_key';
  static const String remoteConfigAnthropicModel = 'anthropic_model';
  static const String remoteConfigGoogleKey = 'google_api_key';
  static const String remoteConfigGoogleModel = 'google_model';
  
  // Routes
  static const String routeOnboarding = '/onboarding';
  static const String routeHome = '/home';
  static const String routeMealPlan = '/meal-plan';
  static const String routeGrocery = '/grocery';
  static const String routePreferences = '/preferences';
  static const String routeMealDetail = '/meal-detail';
  static const String routeAiConfig = '/ai-config';
  static const String routeMealPlanGenerate = '/meal-plan/generate';
  
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