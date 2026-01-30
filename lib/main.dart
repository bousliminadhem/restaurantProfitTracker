import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/dish_provider.dart';
import 'providers/service_provider.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'services/migration_service.dart';
import 'repositories/dish_repository.dart';
import 'repositories/shift_repository.dart';
import 'theme/app_theme.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable edge-to-edge mode for full screen (Samsung notch support)
  AppTheme.enableEdgeToEdge();
  AppTheme.setSystemUIOverlay();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Run app with splash screen
  runApp(const RestaurantProfitApp(isInitializing: true));
  
  // Initialize services in background
  try {
    // 1. Initialize Storage Service (Hive)
    final storageService = StorageService();
    await storageService.init();
    
    // 2. Initialize API Service
    final apiService = ApiService();
    
    // 3. Initialize Repositories
    final dishRepository = DishRepository(
      storage: storageService,
      api: apiService,
    );
    
    final shiftRepository = ShiftRepository(
      storage: storageService,
      api: apiService,
    );
    
    // 4. Initialize and Run Migration (Hive -> Backend)
    final migrationService = MigrationService(
      storage: storageService,
      api: apiService,
    );
    
    await migrationService.init();
    if (!migrationService.isMigrationCompleted) {
      try {
        await migrationService.runMigration();
      } catch (e) {
        debugPrint('⚠️ Migration failed during startup: $e');
        // Migration will be retried on next launch
      }
    }
    
    // Re-run app with initialized services
    runApp(RestaurantProfitApp(
      isInitializing: false,
      dishRepository: dishRepository,
      shiftRepository: shiftRepository,
    ));
    
  } catch (e, stackTrace) {
    debugPrint('❌ Critical error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Show error screen
    runApp(RestaurantProfitApp(
      isInitializing: false,
      initError: e.toString(),
    ));
  }
}

class RestaurantProfitApp extends StatelessWidget {
  final bool isInitializing;
  final DishRepository? dishRepository;
  final ShiftRepository? shiftRepository;
  final String? initError;
  
  const RestaurantProfitApp({
    super.key,
    required this.isInitializing,
    this.dishRepository,
    this.shiftRepository,
    this.initError,
  });

  @override
  Widget build(BuildContext context) {
    // Show splash or error screens without providers
    if (isInitializing) {
      return MaterialApp(
        title: 'Restaurant Profit Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      );
    }
    
    if (initError != null) {
      return MaterialApp(
        title: 'Restaurant Profit Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: ErrorScreen(error: initError!),
      );
    }
    
    // Main app with providers available to all routes
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DishProvider(dishRepository!),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceProvider(shiftRepository!),
        ),
      ],
      child: MaterialApp(
        title: 'Restaurant Profit Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}

// Splash Screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Restaurant Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.offWhite.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  border: Border.all(
                    color: AppTheme.offWhite.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: AppTheme.offWhite,
                ),
              ),
              const SizedBox(height: 32),
              
              // App Title
              const Text(
                'Restaurant Profit',
                style: AppTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tracker',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.offWhite,
                  letterSpacing: 3,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Loading Indicator
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldenOrange),
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Initializing...',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.offWhite.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Error Screen
class ErrorScreen extends StatelessWidget {
  final String error;
  
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppTheme.goldenOrange,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Initialization Error',
                    style: AppTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.offWhite.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: AppTheme.offWhite.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      error,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.offWhite,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Restart app
                      SystemNavigator.pop();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Restart App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldenOrange,
                      foregroundColor: AppTheme.offWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
