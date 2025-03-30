import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Service class to handle app navigation
class NavigationService {
  // Private constructor to prevent direct instantiation
  NavigationService._();
  
  // Singleton instance
  static final NavigationService _instance = NavigationService._();
  
  /// Get the singleton instance of NavigationService
  static NavigationService get instance => _instance;
  
  /// Global key for navigator
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.prefIsOnboardingComplete) ?? false;
  }
  
  /// Mark onboarding as complete
  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.prefIsOnboardingComplete, true);
  }
  
  /// Navigate to a named route
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }
  
  /// Navigate to a named route and remove all previous routes
  Future<dynamic> navigateToAndRemoveUntil(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }
  
  /// Navigate to a named route and remove all routes until a specific route
  Future<dynamic> navigateToAndRemoveUntilRoute(String routeName, String untilRouteName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      ModalRoute.withName(untilRouteName),
      arguments: arguments,
    );
  }
  
  /// Navigate back
  void goBack() {
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop();
    }
  }
  
  /// Get the initial route based on onboarding status
  Future<String> getInitialRoute() async {
    final isComplete = await isOnboardingComplete();
    return isComplete ? Constants.routeHome : Constants.routeOnboarding;
  }
} 