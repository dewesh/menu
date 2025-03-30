import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  
  /// Save a new AI provider configuration
  Future<void> saveConfig(AIProviderConfig config);
  
  /// Generate a meal plan based on user preferences
  Future<Map<String, dynamic>> generateMealPlan({
    required List<CuisinePreference> cuisinePreferences,
    required List<String> dietaryPreferences,
    required int familySize,
    required int numberOfDays,
    Map<String, dynamic>? additionalPreferences,
  });
  
  /// Create instance of appropriate AIService implementation
  static Future<AIService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final configStr = prefs.getString(Constants.prefAIProviderConfig);
    
    if (configStr != null) {
      try {
        final configMap = jsonDecode(configStr) as Map<String, dynamic>;
        final config = AIProviderConfig.fromMap(configMap);
        
        // Return the appropriate implementation based on the provider
        switch (config.provider.toLowerCase()) {
          case 'openai':
            return OpenAIService(config);
          case 'anthropic':
            // TODO: Implement Anthropic service
            throw AIServiceException('Anthropic provider not yet implemented');
          case 'google':
            // TODO: Implement Google AI service
            throw AIServiceException('Google AI provider not yet implemented');
          default:
            throw AIServiceException('Unknown AI provider: ${config.provider}');
        }
      } catch (e) {
        debugPrint('Error parsing AI provider config: $e');
      }
    }
    
    // Default to OpenAI with empty config
    return OpenAIService(AIProviderConfig(
      provider: 'openai',
      apiKey: '',
      model: 'gpt-3.5-turbo',
    ));
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
    if (config.provider.toLowerCase() != 'openai') {
      throw AIServiceException('Invalid provider for OpenAIService: ${config.provider}');
    }
    
    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.prefAIProviderConfig, jsonEncode(config.toMap()));
    
    // Update current config
    _config = config;
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
      throw AIServiceException('OpenAI API key not set. Please configure the API key first.');
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
                  'Always return responses in JSON format for easy parsing.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
          'top_p': 1,
          'frequency_penalty': 0,
          'presence_penalty': 0,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final mealPlanText = responseData['choices'][0]['message']['content'];
        
        // Parse the response and extract the meal plan JSON
        return _parseMealPlanResponse(mealPlanText);
      } else {
        throw AIServiceException(
          'OpenAI API error: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is AIServiceException) {
        rethrow;
      }
      throw AIServiceException('Error generating meal plan', e);
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
    
    // Build the prompt
    return '''
Please create a meal plan for $numberOfDays days for a family of $familySize with the following preferences:

Cuisine Preferences: $cuisinePrefs
Dietary Restrictions: $dietaryPrefs
${additionalPreferences != null ? 'Additional Preferences: ${jsonEncode(additionalPreferences)}' : ''}

For each day, provide:
1. Breakfast
2. Lunch
3. Dinner
4. One snack

For each meal, include:
- Name of the dish
- List of ingredients with quantities
- Brief preparation instructions
- Nutritional information (calories, protein, carbs, fats)

Return the meal plan in JSON format that can be easily parsed, with the following structure:
{
  "mealPlan": {
    "days": [
      {
        "day": 1,
        "breakfast": {
          "name": "Dish Name",
          "cuisineType": "Cuisine Type",
          "ingredients": [{"name": "Ingredient 1", "quantity": "Quantity", "unit": "Unit"}],
          "instructions": "Brief instructions",
          "nutritionalInfo": {"calories": 000, "protein": 00, "carbs": 00, "fat": 00}
        },
        "lunch": { ... },
        "dinner": { ... },
        "snack": { ... }
      },
      ...
    ]
  }
}
''';
  }
  
  /// Parse the AI response to extract the meal plan
  Map<String, dynamic> _parseMealPlanResponse(String responseText) {
    try {
      // Find JSON in the response text
      final jsonPattern = RegExp(r'{[\s\S]*}');
      final match = jsonPattern.firstMatch(responseText);
      
      if (match != null) {
        final jsonText = match.group(0);
        if (jsonText != null) {
          return jsonDecode(jsonText);
        }
      }
      
      // If no JSON found, try to parse the whole response
      return jsonDecode(responseText);
    } catch (e) {
      debugPrint('Error parsing meal plan response: $e');
      debugPrint('Response text: $responseText');
      throw AIServiceException('Failed to parse meal plan response', e);
    }
  }
} 