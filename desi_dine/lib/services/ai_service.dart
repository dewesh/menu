import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';

/// Exception for AI-related errors
class AIServiceException implements Exception {
  final String message;
  final dynamic error;

  AIServiceException(this.message, [this.error]);

  @override
  String toString() => 'AIServiceException: $message ${error != null ? '($error)' : ''}';
}

/// Model class for the connection test response
class ConnectionTestResponse {
  final bool success;
  final String message;
  
  ConnectionTestResponse({
    required this.success,
    required this.message,
  });
  
  factory ConnectionTestResponse.fromJson(Map<String, dynamic> json) {
    return ConnectionTestResponse(
      success: json['success'] == true,
      message: json['message'] as String? ?? 'No message provided',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}

/// Model class for meal plan ingredients
class MealIngredient {
  final String name;
  final String quantity;
  final String unit;
  
  MealIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });
  
  factory MealIngredient.fromJson(Map<String, dynamic> json) {
    return MealIngredient(
      name: json['name'] as String,
      quantity: json['quantity'] as String,
      unit: json['unit'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

/// Model class for nutritional information
class NutritionalInfo {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  
  NutritionalInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
  
  factory NutritionalInfo.fromJson(Map<String, dynamic> json) {
    return NutritionalInfo(
      calories: _parseIntValue(json['calories']),
      protein: _parseIntValue(json['protein']),
      carbs: _parseIntValue(json['carbs']),
      fat: _parseIntValue(json['fat']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
  
  /// Helper to safely parse int values that might come as strings or other formats
  static int _parseIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      // Try parsing string, handling both "100" and "100g" formats
      final numericString = value.replaceAll(RegExp(r'[^0-9.]'), '');
      if (numericString.isEmpty) return 0;
      try {
        if (numericString.contains('.')) {
          return double.parse(numericString).round();
        } else {
          return int.parse(numericString);
        }
      } catch (_) {
        return 0;
      }
    }
    return 0;
  }
}

/// Model class for a single meal
class Meal {
  final String name;
  final String cuisineType;
  final List<MealIngredient> ingredients;
  final String instructions;
  final NutritionalInfo nutritionalInfo;
  
  Meal({
    required this.name,
    required this.cuisineType,
    required this.ingredients,
    required this.instructions,
    required this.nutritionalInfo,
  });
  
  factory Meal.fromJson(Map<String, dynamic> json) {
    try {
      // Handle ingredient list - could be missing or not a list
      List<MealIngredient> parsedIngredients = [];
      if (json.containsKey('ingredients') && json['ingredients'] is List) {
        parsedIngredients = (json['ingredients'] as List)
            .map((item) {
              // Item must be a map to convert to an ingredient
              if (item is Map<String, dynamic>) {
                return MealIngredient.fromJson(item);
              }
              // Handle string items or other formats
              if (item is String) {
                return MealIngredient(
                  name: item,
                  quantity: "as needed",
                  unit: ""
                );
              }
              return null;
            })
            .whereType<MealIngredient>() // Filter out nulls
            .toList();
      }
      
      // Handle nutritional info - could be missing or in wrong format
      NutritionalInfo parsedNutritionalInfo;
      if (json.containsKey('nutritionalInfo') && json['nutritionalInfo'] is Map<String, dynamic>) {
        parsedNutritionalInfo = NutritionalInfo.fromJson(json['nutritionalInfo'] as Map<String, dynamic>);
      } else {
        // Default nutritional info if missing
        parsedNutritionalInfo = NutritionalInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
      }
      
      return Meal(
        name: json['name'] as String? ?? "Unnamed Dish",
        cuisineType: json['cuisineType'] as String? ?? "Not Specified",
        ingredients: parsedIngredients,
        instructions: json['instructions'] as String? ?? "No instructions provided",
        nutritionalInfo: parsedNutritionalInfo,
      );
    } catch (e) {
      debugPrint('Error parsing Meal: $e');
      // Return a placeholder meal rather than crashing
      return Meal(
        name: json['name'] as String? ?? "Error: Could not parse meal",
        cuisineType: "Not Available",
        ingredients: [],
        instructions: "Error parsing meal data",
        nutritionalInfo: NutritionalInfo(calories: 0, protein: 0, carbs: 0, fat: 0),
      );
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cuisineType': cuisineType,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'nutritionalInfo': nutritionalInfo.toJson(),
    };
  }
}

/// Model class for a single day in a meal plan
class MealPlanDay {
  final int day;
  final Meal breakfast;
  final Meal lunch;
  final Meal dinner;
  final Meal snack;
  
  MealPlanDay({
    required this.day,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });
  
  factory MealPlanDay.fromJson(Map<String, dynamic> json) {
    try {
      // Convert day to int if it's a string
      int dayNumber = 1;
      if (json.containsKey('day')) {
        if (json['day'] is int) {
          dayNumber = json['day'];
        } else if (json['day'] is String) {
          dayNumber = int.tryParse(json['day']) ?? 1;
        }
      }
      
      return MealPlanDay(
        day: dayNumber,
        breakfast: _parseMealSafely(json, 'breakfast'),
        lunch: _parseMealSafely(json, 'lunch'),
        dinner: _parseMealSafely(json, 'dinner'),
        snack: _parseMealSafely(json, 'snack'),
      );
    } catch (e) {
      debugPrint('Error parsing MealPlanDay: $e');
      // Return a placeholder day rather than crashing
      final placeholderMeal = Meal(
        name: "Error: Could not parse meal plan day",
        cuisineType: "Not Available",
        ingredients: [],
        instructions: "Error parsing meal plan data",
        nutritionalInfo: NutritionalInfo(calories: 0, protein: 0, carbs: 0, fat: 0),
      );
      
      return MealPlanDay(
        day: json['day'] as int? ?? 1,
        breakfast: placeholderMeal,
        lunch: placeholderMeal,
        dinner: placeholderMeal,
        snack: placeholderMeal,
      );
    }
  }
  
  // Helper method to safely parse a meal or return a placeholder
  static Meal _parseMealSafely(Map<String, dynamic> json, String mealKey) {
    if (json.containsKey(mealKey) && json[mealKey] is Map<String, dynamic>) {
      try {
        return Meal.fromJson(json[mealKey] as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Error parsing $mealKey: $e');
      }
    }
    // Return placeholder meal if parsing fails
    return Meal(
      name: "Missing $mealKey",
      cuisineType: "Not Available",
      ingredients: [],
      instructions: "No data available",
      nutritionalInfo: NutritionalInfo(calories: 0, protein: 0, carbs: 0, fat: 0),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'breakfast': breakfast.toJson(),
      'lunch': lunch.toJson(),
      'dinner': dinner.toJson(),
      'snack': snack.toJson(),
    };
  }
}

/// Model class for the complete meal plan
class MealPlanResponse {
  final List<MealPlanDay> days;
  
  MealPlanResponse({
    required this.days,
  });
  
  factory MealPlanResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Try to find the days array wherever it might be in the JSON structure
      List<dynamic> daysData = [];
      
      // Case 1: Directly under the "days" key
      if (json.containsKey('days') && json['days'] is List) {
        daysData = json['days'] as List<dynamic>;
      }
      // Case 2: Under a "mealPlan" object
      else if (json.containsKey('mealPlan') && json['mealPlan'] is Map<String, dynamic>) {
        final mealPlan = json['mealPlan'] as Map<String, dynamic>;
        if (mealPlan.containsKey('days') && mealPlan['days'] is List) {
          daysData = mealPlan['days'] as List<dynamic>;
        }
      }
      // Case 3: Look for any array in the top-level keys that could be days
      else {
        for (final key in json.keys) {
          if (json[key] is List && (json[key] as List).isNotEmpty) {
            // Check if the first item has day, breakfast, lunch etc.
            final firstItem = (json[key] as List).first;
            if (firstItem is Map<String, dynamic> && 
                (firstItem.containsKey('day') || 
                 firstItem.containsKey('breakfast') || 
                 firstItem.containsKey('lunch'))) {
              daysData = json[key] as List<dynamic>;
              break;
            }
          }
        }
      }
      
      // If no days array was found, create a single empty day
      if (daysData.isEmpty) {
        debugPrint('No days data found in meal plan JSON: $json');
        return MealPlanResponse(days: []);
      }
      
      // Try to parse each day
      List<MealPlanDay> parsedDays = [];
      int dayCounter = 1;
      
      for (var dayData in daysData) {
        try {
          if (dayData is Map<String, dynamic>) {
            parsedDays.add(MealPlanDay.fromJson(dayData));
          } else {
            debugPrint('Day data is not a map: $dayData');
          }
        } catch (e) {
          debugPrint('Error parsing day $dayCounter: $e');
        }
        dayCounter++;
      }
      
      return MealPlanResponse(days: parsedDays);
    } catch (e) {
      debugPrint('Error parsing MealPlanResponse: $e');
      return MealPlanResponse(days: []);
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'mealPlan': {
        'days': days.map((day) => day.toJson()).toList(),
      }
    };
  }
}

/// Configuration for AI providers
class AIProviderConfig {
  final String provider; // 'openai', 'anthropic', etc.
  final String apiKey;
  final String model; // 'gpt-3.5-turbo', 'gpt-4', 'claude-2', etc.
  final Map<String, dynamic> additionalParams;

  AIProviderConfig({
    required this.provider,
    required this.apiKey,
    required this.model,
    this.additionalParams = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'model': model,
      'additionalParams': additionalParams,
    };
  }

  factory AIProviderConfig.fromMap(Map<String, dynamic> map) {
    return AIProviderConfig(
      provider: map['provider'],
      apiKey: map['apiKey'] ?? '',
      model: map['model'],
      additionalParams: Map<String, dynamic>.from(map['additionalParams'] ?? {}),
    );
  }
}

/// Abstract class for AI services
abstract class AIService {
  /// Get the current AI provider configuration
  Future<AIProviderConfig?> getConfig();
  
  /// Save the AI provider configuration
  Future<void> saveConfig(AIProviderConfig config);
  
  /// Test the connection to the AI provider API
  Future<bool> testConnection();
  
  /// Generate a meal plan based on user preferences
  Future<Map<String, dynamic>> generateMealPlan({
    required List<CuisinePreference> cuisinePreferences,
    required List<String> dietaryPreferences,
    required int familySize,
    required int numberOfDays,
    Map<String, dynamic>? additionalPreferences,
  });
  
  /// Create instance of appropriate AIService implementation with admin config
  static Future<AIService> create() async {
    // Initialize Remote Config
    final remoteConfig = FirebaseRemoteConfig.instance;
    
    try {
      // Set default values
      await remoteConfig.setDefaults({
        Constants.remoteConfigAiProvider: Constants.aiProviderOpenAI,
        Constants.remoteConfigOpenAiKey: '',
        Constants.remoteConfigOpenAiModel: Constants.aiModelOpenAI,
        Constants.remoteConfigAnthropicKey: '',
        Constants.remoteConfigAnthropicModel: Constants.aiModelAnthropic,
        Constants.remoteConfigGoogleKey: '',
        Constants.remoteConfigGoogleModel: Constants.aiModelGoogle,
      });
      
      // Fetch the latest values (setting expiration to 1 hour)
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      
      await remoteConfig.fetchAndActivate();
      
      // Get the provider from Remote Config
      final provider = remoteConfig.getString(Constants.remoteConfigAiProvider);
      
      // Debug logging to verify Remote Config values
      debugPrint('📱 REMOTE CONFIG VALUES:');
      debugPrint('📱 AI Provider: $provider');
      debugPrint('📱 OpenAI Key: ${remoteConfig.getString(Constants.remoteConfigOpenAiKey).isNotEmpty ? "*******" : "empty"}');
      debugPrint('📱 OpenAI Model: ${remoteConfig.getString(Constants.remoteConfigOpenAiModel)}');
      debugPrint('📱 Anthropic Key: ${remoteConfig.getString(Constants.remoteConfigAnthropicKey).isNotEmpty ? "*******" : "empty"}');
      debugPrint('📱 Anthropic Model: ${remoteConfig.getString(Constants.remoteConfigAnthropicModel)}');
      debugPrint('📱 Google Key: ${remoteConfig.getString(Constants.remoteConfigGoogleKey).isNotEmpty ? "*******" : "empty"}');
      debugPrint('📱 Google Model: ${remoteConfig.getString(Constants.remoteConfigGoogleModel)}');
      
      // Return the appropriate implementation based on the provider
      switch (provider.toLowerCase()) {
        case 'openai':
          final apiKey = remoteConfig.getString(Constants.remoteConfigOpenAiKey);
          final model = remoteConfig.getString(Constants.remoteConfigOpenAiModel);
          
          return OpenAIService(AIProviderConfig(
            provider: 'openai',
            apiKey: apiKey,
            model: model.isNotEmpty ? model : Constants.aiModelOpenAI,
          ));
          
        case 'anthropic':
          final apiKey = remoteConfig.getString(Constants.remoteConfigAnthropicKey);
          final model = remoteConfig.getString(Constants.remoteConfigAnthropicModel);
          
          // TODO: Implement Anthropic service
          throw AIServiceException('Anthropic provider not yet implemented');
          
        case 'google':
          final apiKey = remoteConfig.getString(Constants.remoteConfigGoogleKey);
          final model = remoteConfig.getString(Constants.remoteConfigGoogleModel);
          
          // TODO: Implement Google AI service
          throw AIServiceException('Google AI provider not yet implemented');
          
        default:
          throw AIServiceException('Unknown AI provider: $provider');
      }
    } catch (e) {
      debugPrint('Error loading AI provider config: $e');
      
      // Default to OpenAI with empty config
      return OpenAIService(AIProviderConfig(
        provider: 'openai',
        apiKey: '',
        model: 'gpt-3.5-turbo',
      ));
    }
  }
}

/// OpenAI implementation of the AI service
class OpenAIService extends AIService {
  AIProviderConfig _config;
  
  OpenAIService(this._config);
  
  @override
  Future<AIProviderConfig?> getConfig() async {
    return _config;
  }
  
  @override
  Future<void> saveConfig(AIProviderConfig config) async {
    _config = config;
    // You would typically save this to persistent storage here
    // For example, using SharedPreferences or Firestore
    try {
      // For now, we'll just update the in-memory config
      debugPrint('Saving config: ${config.provider}, ${config.model}');
    } catch (e) {
      throw AIServiceException('Failed to save AI provider configuration: $e');
    }
  }
  
  @override
  Future<bool> testConnection() async {
    if (_config.apiKey.isEmpty) {
      throw AIServiceException('OpenAI API key not set. Please contact the app administrator to configure the API key.');
    }
    
    try {
      // Make a small request to test the API connection
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.apiKey}',
        },
        body: jsonEncode({
          'model': _config.model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that responds in JSON format. ' +
                          'For test connection requests, respond with ONLY a valid JSON object in this exact format: ' +
                          '{"success": true, "message": "Connection successful"}'
            },
            {
              'role': 'user',
              'content': 'This is a connection test. Respond with the specified JSON format.',
            }
          ],
          'max_tokens': 50, // Keep it small for a fast response
          'response_format': { 'type': 'json_object' }, // Request JSON format if supported by the model
        }),
      );
      
      // Check if the response is successful
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Log full response for debugging
        debugPrint('OpenAI API test response: ${response.body}');
        
        try {
          // Check if the response contains the expected fields
          if (responseData.containsKey('choices') && 
              responseData['choices'] is List && 
              responseData['choices'].isNotEmpty && 
              responseData['choices'][0].containsKey('message') &&
              responseData['choices'][0]['message'].containsKey('content')) {
            
            // Try to parse the response content as our specific ConnectionTestResponse format
            final contentJson = jsonDecode(responseData['choices'][0]['message']['content']);
            final testResponse = ConnectionTestResponse.fromJson(contentJson);
            
            // Check for success
            if (testResponse.success) {
              debugPrint('Connection test successful: ${testResponse.message}');
              return true;
            } else {
              debugPrint('Connection test returned success=false: ${testResponse.message}');
              return false;
            }
          } else {
            // Response structure is unexpected, but we still got a 200 status code
            debugPrint('Unexpected response structure but connection succeeded');
            return true;
          }
        } catch (parseError) {
          // We got a response but couldn't parse the content as expected JSON
          debugPrint('Error parsing response content as JSON: $parseError');
          debugPrint('Raw content: ${responseData['choices'][0]['message']['content']}');
          // Still return true since connection worked, even if format was unexpected
          return true;
        }
      } else {
        // API returned an error
        final errorData = jsonDecode(response.body);
        throw AIServiceException('OpenAI API error: ${response.statusCode} - ${errorData['error']['message']}');
      }
    } catch (e) {
      // Log the error for debugging
      debugPrint('OpenAI API connection test failed: $e');
      if (e is FormatException) {
        throw AIServiceException('Failed to parse OpenAI API response: $e');
      } else if (e is AIServiceException) {
        rethrow;
      } else {
        throw AIServiceException('Failed to connect to OpenAI API: $e');
      }
    }
  }
  
  @override
  Future<Map<String, dynamic>> generateMealPlan({
    required List<CuisinePreference> cuisinePreferences,
    required List<String> dietaryPreferences,
    required int familySize,
    required int numberOfDays,
    Map<String, dynamic>? additionalPreferences,
  }) async {
    if (_config.apiKey.isEmpty) {
      throw AIServiceException('OpenAI API key not set. Please contact the app administrator to configure the API key.');
    }
    
    // Construct the prompt for meal plan generation
    final prompt = _buildMealPlanPrompt(
      cuisinePreferences: cuisinePreferences,
      dietaryPreferences: dietaryPreferences,
      familySize: familySize,
      numberOfDays: numberOfDays,
      additionalPreferences: additionalPreferences,
    );
    
    try {
      // Make API request to OpenAI
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.apiKey}',
        },
        body: jsonEncode({
          'model': _config.model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a nutritionist and chef specialized in meal planning. '
                  'Create meal plans that follow dietary preferences and restrictions, '
                  'focusing on the cuisine types specified by the user. '
                  'Provide detailed information about each meal including ingredients, '
                  'nutritional information, and preparation steps. '
                  'CRITICALLY IMPORTANT: Your response MUST be valid, parseable JSON. '
                  'Do not include ANY explanation text before or after the JSON. '
                  'Return ONLY the JSON object.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 3000,
          'top_p': 1,
          'frequency_penalty': 0,
          'presence_penalty': 0,
          'response_format': { 'type': 'json_object' }, // Request JSON format if supported by the model
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final mealPlanText = responseData['choices'][0]['message']['content'];
        
        // Log the raw response for debugging
        debugPrint('Meal plan response received. First 100 chars: ${mealPlanText.length > 100 ? mealPlanText.substring(0, 100) + "..." : mealPlanText}');
        
        try {
          // Step 1: Parse the response content as JSON
          final Map<String, dynamic> jsonData;
          try {
            jsonData = jsonDecode(mealPlanText) as Map<String, dynamic>;
            debugPrint('Successfully parsed JSON response');
          } catch (jsonError) {
            debugPrint('Error parsing meal plan JSON: $jsonError');
            // Extract JSON from text if direct parse fails
            final jsonPattern = RegExp(r'({[\s\S]*})');
            final match = jsonPattern.firstMatch(mealPlanText);
            if (match != null) {
              final jsonText = match.group(0);
              if (jsonText != null) {
                final extractedJson = jsonDecode(jsonText) as Map<String, dynamic>;
                debugPrint('Successfully extracted and parsed JSON using regex');
                return extractedJson;
              } else {
                throw AIServiceException('Could not extract JSON from response: $mealPlanText');
              }
            } else {
              throw AIServiceException('Could not find JSON pattern in response: $mealPlanText');
            }
          }
          
          // Step 2: Try to convert to our structured model
          try {
            final mealPlanResponse = MealPlanResponse.fromJson(jsonData);
            if (mealPlanResponse.days.isEmpty) {
              debugPrint('Warning: Meal plan has no days');
            }
            return mealPlanResponse.toJson();
          } catch (modelError) {
            debugPrint('Error converting JSON to MealPlanResponse: $modelError');
            // If structure parsing fails, return the raw JSON
            return jsonData;
          }
        } catch (e) {
          debugPrint('Error processing meal plan response: $e');
          throw AIServiceException('Failed to process meal plan response: $e');
        }
      } else {
        final errorBody = response.body;
        debugPrint('OpenAI API error response: $errorBody');
        try {
          final errorData = jsonDecode(errorBody);
          throw AIServiceException(
            'OpenAI API error: ${errorData['error']['message']}',
            errorBody,
          );
        } catch (jsonError) {
          throw AIServiceException(
            'OpenAI API error: ${response.statusCode}',
            errorBody,
          );
        }
      }
    } catch (e) {
      if (e is AIServiceException) {
        rethrow;
      }
      throw AIServiceException('Error generating meal plan: $e');
    }
  }
  
  /// Build the prompt for meal plan generation
  String _buildMealPlanPrompt({
    required List<CuisinePreference> cuisinePreferences,
    required List<String> dietaryPreferences,
    required int familySize,
    required int numberOfDays,
    Map<String, dynamic>? additionalPreferences,
  }) {
    // Format cuisine preferences
    final cuisinePrefs = cuisinePreferences.map((pref) => 
      '${pref.cuisineType} (${pref.frequencyPreference})'
    ).join(', ');
    
    // Format dietary preferences
    final dietaryPrefs = dietaryPreferences.isEmpty 
      ? 'No specific dietary restrictions'
      : dietaryPreferences.join(', ');
    
    // Build the prompt with a simpler, more focused structure
    return '''
Create a meal plan for $numberOfDays days for a family of $familySize people with these preferences:

- Cuisine Preferences: $cuisinePrefs
- Dietary Restrictions: $dietaryPrefs
${additionalPreferences != null ? '- Additional Preferences: ${jsonEncode(additionalPreferences)}' : ''}

For each day, include breakfast, lunch, dinner, and one snack.
Each meal should include the dish name, cuisine type, ingredients with quantities, preparation instructions, and nutritional information.

IMPORTANT: Your response must be a valid JSON object with this structure:
{
  "mealPlan": {
    "days": [
      {
        "day": 1,
        "breakfast": {
          "name": "Name of dish",
          "cuisineType": "Type of cuisine",
          "ingredients": [
            {"name": "Ingredient name", "quantity": "amount", "unit": "unit of measurement"}
          ],
          "instructions": "Brief preparation instructions",
          "nutritionalInfo": {"calories": 300, "protein": 15, "carbs": 40, "fat": 10}
        },
        "lunch": { similar structure as breakfast },
        "dinner": { similar structure as breakfast },
        "snack": { similar structure as breakfast }
      }
      // Additional days follow the same pattern
    ]
  }
}

Do not include ANY explanatory text. Your response must ONLY contain valid JSON.
''';
  }
} 