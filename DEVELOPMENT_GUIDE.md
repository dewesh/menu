# DesiDine App - Development Guide

## Overview
This guide outlines the implementation plan for building the DesiDine app prototype in a single day. We'll focus on creating a working app with Firebase and AI integration (except authentication) that follows the requirements in the README.md.

## Project Structure
```
lib/
  ├── main.dart              # App entry point
  ├── firebase_options.dart  # Firebase configuration
  ├── models/                # Data models
  │   ├── user_model.dart
  │   ├── meal_model.dart
  │   ├── ingredient_model.dart
  │   └── grocery_model.dart
  ├── services/              # Business logic & API services
  │   ├── firebase_service.dart
  │   ├── ai_service.dart
  │   ├── meal_service.dart
  │   └── grocery_service.dart
  ├── screens/               # All app screens
  │   ├── onboarding/        # Onboarding screens
  │   ├── home/              # Main app screens
  │   ├── meal_plan/         # Meal planning screens
  │   ├── grocery/           # Grocery list screens
  │   └── preferences/       # Preference management
  ├── widgets/               # Reusable components
  │   ├── meal_card.dart
  │   ├── ingredient_swiper.dart
  │   └── ... other widgets
  └── utils/                 # Helper functions & constants
      ├── constants.dart
      ├── theme.dart
      └── helpers.dart
```

## Implementation Steps & Testing Checkpoints

### Step 1: Project Setup & Firebase Integration
- [ ] Create new Flutter project
- [ ] Configure Firebase (Cloud Firestore)
- [ ] Set up theme and base navigation
- **TESTING CHECKPOINT**: App launches, connects to Firebase

### Step 2: Data Models & Services
- [ ] Implement data models for User, Meal, Ingredient, Grocery
- [ ] Create Firebase service with CRUD operations
- [ ] Setup simple AI service interface (we'll implement later)
- **TESTING CHECKPOINT**: Verify data models with sample data in Firebase console

### Step 3: Onboarding Flow (Simplified)
- [ ] Implement Welcome Screen
- [ ] Create Regional Cuisine Selection Screen
- [ ] Build Dietary Preferences Screen
- [ ] Add Family Size Input Screen
- [ ] Implement Taste Preferences Screen
- [ ] Create Ingredient Selection with swiper UI
- [ ] Build Completion Screen
- **TESTING CHECKPOINT**: Navigate through onboarding flow, save preferences to Firebase

### Step 4: Home Screen & Meal Plan
- [ ] Implement Home Screen with Today's Meals
- [ ] Create 7-Day Meal Plan view
- [ ] Build Meal Detail Screen
- [ ] Add basic navigation between these screens
- **TESTING CHECKPOINT**: View meals, navigate between meal screens

### Step 5: AI Integration for Meal Planning
- [ ] Implement AI service using OpenAI API or similar
- [ ] Create prompt engineering for meal suggestions based on preferences
- [ ] Add caching for faster responses
- [ ] Connect AI service to meal planning screens
- **TESTING CHECKPOINT**: Generate personalized meal plans based on preferences

### Step 6: Grocery List Management
- [ ] Generate grocery lists from meal plans
- [ ] Implement categorized grocery list UI
- [ ] Add item marking functionality
- [ ] Create list sharing feature
- **TESTING CHECKPOINT**: Generate, update, and share grocery lists

### Step 7: Preference Management
- [ ] Create preferences/settings screen
- [ ] Implement preference updating
- [ ] Connect preference changes to meal plan updates
- **TESTING CHECKPOINT**: Update preferences, verify meal plan changes

### Step 8: Health State Adjustments
- [ ] Implement Health State Input Screen
- [ ] Add logic to modify meal plans based on health state
- [ ] Create notification for adjusted meal plans
- **TESTING CHECKPOINT**: Adjust meal plans based on health state

### Step 9: Final Integration & Polish
- [ ] Ensure all components work together
- [ ] Add loading indicators where needed
- [ ] Implement error handling
- [ ] Polish transitions and UI
- **TESTING CHECKPOINT**: End-to-end testing of main user flows

## Firebase Integration
We'll use Firebase Firestore with the following collections:
- `users`: User preferences and profile data
- `meals`: Predefined meal options with ingredients and instructions
- `mealPlans`: Generated meal plans for users
- `groceryLists`: Generated grocery lists

## AI Integration
We'll use a simple AI implementation with the following approach:
1. Create an `ai_service.dart` that interfaces with OpenAI API
2. Implement prompt engineering for:
   - Meal plan generation based on preferences
   - Adjusting meals for health states
   - Refining grocery lists
3. Add caching to minimize API calls

## Testing Strategy
1. **Component Testing**: Test each screen and feature in isolation
2. **Integration Testing**: Test related features together
3. **User Flow Testing**: Test complete user journeys
4. **Firebase Testing**: Verify data is correctly saved and retrieved
5. **Error Testing**: Test error handling and edge cases

## Development Timeline
- **Hours 1-2**: Project setup, Firebase integration
- **Hours 2-4**: Data models, services, onboarding UI
- **Hours 4-6**: Home screen, meal plan screens
- **Hours 6-8**: AI integration, grocery list functionality
- **Hours 8-10**: Preference management, health adjustments
- **Hours 10-12**: Final integration, testing, and polish

Regularly commit code and check off completed items to track progress. 