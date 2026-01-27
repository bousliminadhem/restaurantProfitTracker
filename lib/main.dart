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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(RestaurantProfitApp(
    dishRepository: dishRepository,
    shiftRepository: shiftRepository,
  ));
}

class RestaurantProfitApp extends StatelessWidget {
  final DishRepository dishRepository;
  final ShiftRepository shiftRepository;
  
  const RestaurantProfitApp({
    super.key,
    required this.dishRepository,
    required this.shiftRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DishProvider(dishRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceProvider(shiftRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Restaurant Profit Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 4,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
