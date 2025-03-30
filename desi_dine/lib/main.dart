import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'services/firebase_service.dart';
import 'services/navigation_service.dart';
import 'screens/home/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/preferences/ai_config_screen.dart';
import 'screens/meal_plan/generate_meal_plan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _initializeRemoteConfig();
  runApp(const MyApp());
}

/// Initialize Firebase Remote Config with default values
Future<void> _initializeRemoteConfig() async {
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
    
    // Configure fetch settings
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    
    // Fetch and activate
    await remoteConfig.fetchAndActivate();
    
    debugPrint('Remote Config initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Remote Config: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NavigationService _navigationService = NavigationService.instance;
  ThemeMode _themeMode = ThemeMode.light;
  String _initialRoute = Constants.routeOnboarding;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load theme preference
    await _loadThemePreference();
    
    // Always check SharedPreferences for onboarding status on each app start
    final prefs = await SharedPreferences.getInstance();
    final isOnboardingComplete = prefs.getBool(Constants.prefIsOnboardingComplete) ?? false;
    
    setState(() {
      _initialRoute = isOnboardingComplete ? Constants.routeHome : Constants.routeOnboarding;
      _isLoading = false;
    });
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(Constants.prefThemeMode) ?? 'light';
    setState(() {
      _themeMode = themeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        title: Constants.appName,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: Constants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      navigatorKey: _navigationService.navigatorKey,
      initialRoute: _initialRoute,
      routes: {
        Constants.routeOnboarding: (context) => const OnboardingScreen(),
        Constants.routeHome: (context) => const MainScreen(),
        Constants.routeAiConfig: (context) => const AIConfigScreen(),
        Constants.routeMealPlanGenerate: (context) => const GenerateMealPlanScreen(),
      },
    );
  }
}
