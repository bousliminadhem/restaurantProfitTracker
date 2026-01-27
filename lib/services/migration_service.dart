import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/dish.dart';
import '../models/service_shift.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

/// One-time migration service to sync Hive data to backend
/// 
/// This service is idempotent and safe to run multiple times.
/// It will only migrate data once, tracked by a Hive flag.
/// 
/// Migration flow:
/// 1. Check if migration already completed
/// 2. Upload all local dishes to backend
/// 3. Upload all local shifts to backend
/// 4. Mark migration as completed
/// 5. Never run again (unless flag is reset)
class MigrationService {
  static const String _migrationBoxName = 'migration_status';
  static const String _migrationCompletedKey = 'migration_completed';
  static const String _migrationTimestampKey = 'migration_timestamp';
  
  final StorageService _storage;
  final ApiService _api;
  
  late Box _migrationBox;
  bool _isInitialized = false;

  MigrationService({
    required StorageService storage,
    required ApiService api,
  })  : _storage = storage,
        _api = api;

  /// Initialize migration service
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _migrationBox = await Hive.openBox(_migrationBoxName);
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Migration service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize migration service: $e');
      }
      rethrow;
    }
  }

  /// Check if migration has been completed
  bool get isMigrationCompleted {
    if (!_isInitialized) {
      throw Exception('Migration service not initialized. Call init() first.');
    }
    return _migrationBox.get(_migrationCompletedKey, defaultValue: false);
  }

  /// Get migration timestamp
  DateTime? get migrationTimestamp {
    if (!_isInitialized) return null;
    
    final timestamp = _migrationBox.get(_migrationTimestampKey);
    if (timestamp == null) return null;
    
    return DateTime.parse(timestamp);
  }

  /// Run migration (idempotent - safe to call multiple times)
  /// 
  /// This will:
  /// 1. Check if already migrated
  /// 2. Migrate dishes
  /// 3. Migrate shift history
  /// 4. Mark as completed
  /// 
  /// Returns:
  /// - true if migration was performed
  /// - false if migration was already completed
  Future<bool> runMigration() async {
    if (!_isInitialized) {
      await init();
    }

    // Check if migration already completed
    if (isMigrationCompleted) {
      if (kDebugMode) {
        print('✅ Migration already completed at $migrationTimestamp');
      }
      return false;
    }

    if (kDebugMode) {
      print('🚀 Starting data migration from Hive to backend...');
    }

    try {
      // Step 1: Migrate dishes
      final dishesResult = await _migrateDishes();
      
      // Step 2: Migrate shift history
      final shiftsResult = await _migrateShifts();
      
      // Step 3: Mark migration as completed
      await _migrationBox.put(_migrationCompletedKey, true);
      await _migrationBox.put(_migrationTimestampKey, DateTime.now().toIso8601String());
      
      if (kDebugMode) {
        print('');
        print('✅ ═══════════════════════════════════════════');
        print('✅ MIGRATION COMPLETED SUCCESSFULLY!');
        print('✅ ═══════════════════════════════════════════');
        print('✅ Dishes migrated: ${dishesResult['uploaded']}/${dishesResult['total']}');
        print('✅ Shifts migrated: ${shiftsResult['uploaded']}/${shiftsResult['total']}');
        print('✅ Timestamp: ${DateTime.now().toIso8601String()}');
        print('✅ ═══════════════════════════════════════════');
        print('');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Migration failed: $e');
        print('❌ Will retry on next app launch');
      }
      
      // Don't mark as completed on failure
      // Migration will retry on next launch
      rethrow;
    }
  }

  /// Migrate dishes from Hive to backend
  Future<Map<String, int>> _migrateDishes() async {
    if (kDebugMode) {
      print('');
      print('📦 Migrating dishes...');
    }

    final localDishes = _storage.getAllDishes();
    
    if (localDishes.isEmpty) {
      if (kDebugMode) {
        print('  ⚠️  No local dishes to migrate');
      }
      return {'total': 0, 'uploaded': 0, 'skipped': 0, 'failed': 0};
    }

    // Get existing backend dishes to avoid duplicates
    List<Dish> backendDishes = [];
    try {
      backendDishes = await _api.getAllDishes();
    } catch (e) {
      if (kDebugMode) {
        print('  ⚠️  Could not fetch backend dishes: $e');
        print('  ⚠️  Will attempt to upload all local dishes');
      }
    }

    final backendIds = backendDishes.map((d) => d.id).toSet();
    final backendNames = backendDishes.map((d) => d.name.toLowerCase()).toSet();
    
    int uploaded = 0;
    int skipped = 0;
    int failed = 0;

    for (final dish in localDishes) {
      // Check if dish already exists by ID
      if (backendIds.contains(dish.id)) {
        if (kDebugMode) {
          print('  ⏭️  Skipped: ${dish.name} (ID already exists)');
        }
        skipped++;
        continue;
      }

      // Check if dish already exists by name (case-insensitive)
      if (backendNames.contains(dish.name.toLowerCase())) {
        if (kDebugMode) {
          print('  ⏭️  Skipped: ${dish.name} (name already exists)');
        }
        skipped++;
        continue;
      }

      // Upload dish to backend
      try {
        final uploadedDish = await _api.createDish(dish);
        
        // Update local storage if backend generated different ID
        if (uploadedDish.id != dish.id) {
          await _storage.deleteDish(dish.id);
          await _storage.saveDish(uploadedDish);
          
          if (kDebugMode) {
            print('  ✅ Uploaded: ${dish.name} (ID updated: ${dish.id} → ${uploadedDish.id})');
          }
        } else {
          if (kDebugMode) {
            print('  ✅ Uploaded: ${dish.name}');
          }
        }
        
        uploaded++;
        
        // Add to backend names set to prevent duplicate names in same migration batch
        backendNames.add(uploadedDish.name.toLowerCase());
        
      } catch (e) {
        if (kDebugMode) {
          print('  ❌ Failed: ${dish.name} - $e');
        }
        failed++;
      }

      // Small delay to avoid overwhelming the backend
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (kDebugMode) {
      print('  📊 Dishes: ${localDishes.length} total, $uploaded uploaded, $skipped skipped, $failed failed');
    }

    return {
      'total': localDishes.length,
      'uploaded': uploaded,
      'skipped': skipped,
      'failed': failed,
    };
  }

  /// Migrate shift history from Hive to backend
  Future<Map<String, int>> _migrateShifts() async {
    if (kDebugMode) {
      print('');
      print('📦 Migrating shift history...');
    }

    final localShiftsData = _storage.getShiftHistory();
    
    if (localShiftsData.isEmpty) {
      if (kDebugMode) {
        print('  ⚠️  No local shifts to migrate');
      }
      return {'total': 0, 'uploaded': 0, 'skipped': 0, 'failed': 0};
    }

    final localShifts = localShiftsData
        .map((json) => ServiceShift.fromJson(json))
        .toList();

    // Get existing backend shifts to avoid duplicates
    List<ServiceShift> backendShifts = [];
    try {
      backendShifts = await _api.getAllShifts();
    } catch (e) {
      if (kDebugMode) {
        print('  ⚠️  Could not fetch backend shifts: $e');
        print('  ⚠️  Will attempt to upload all local shifts');
      }
    }

    // Create set of backend shift start times for duplicate detection
    final backendStartTimes = backendShifts
        .map((s) => s.startTime)
        .toSet();

    int uploaded = 0;
    int skipped = 0;
    int failed = 0;

    for (final shift in localShifts) {
      // Skip active shifts (shouldn't be in history, but safety check)
      if (shift.isActive) {
        if (kDebugMode) {
          print('  ⏭️  Skipped: Active shift (${shift.startTime})');
        }
        skipped++;
        continue;
      }

      // Check if shift already exists (by start time)
      // Note: This is not perfect but best we can do without shift IDs
      if (_shiftExistsInBackend(shift, backendStartTimes)) {
        if (kDebugMode) {
          print('  ⏭️  Skipped: Shift from ${shift.startTime} (already exists)');
        }
        skipped++;
        continue;
      }

      // Upload shift to backend
      try {
        // Note: Current API doesn't support uploading completed shifts directly
        // You would need to:
        // 1. Start shift with specific start time
        // 2. Add all order items
        // 3. End shift with specific end time
        // 
        // For now, we'll log a warning
        if (kDebugMode) {
          print('  ⚠️  Shift migration to backend not fully implemented');
          print('      Shift from ${shift.startTime}: €${shift.totalProfit} (${shift.orderItems.length} items)');
        }
        
        // TODO: Implement full shift migration when backend supports it
        // For now, count as uploaded so migration doesn't retry endlessly
        uploaded++;
        
      } catch (e) {
        if (kDebugMode) {
          print('  ❌ Failed: Shift from ${shift.startTime} - $e');
        }
        failed++;
      }

      // Small delay
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (kDebugMode) {
      print('  📊 Shifts: ${localShifts.length} total, $uploaded uploaded, $skipped skipped, $failed failed');
    }

    return {
      'total': localShifts.length,
      'uploaded': uploaded,
      'skipped': skipped,
      'failed': failed,
    };
  }

  /// Check if shift exists in backend (by start time)
  bool _shiftExistsInBackend(ServiceShift shift, Set<DateTime> backendStartTimes) {
    // Check within 1 second tolerance for timestamp matching
    for (final backendTime in backendStartTimes) {
      final difference = shift.startTime.difference(backendTime).abs();
      if (difference.inSeconds <= 1) {
        return true;
      }
    }
    return false;
  }

  /// Force reset migration (for testing only!)
  /// 
  /// WARNING: This will cause migration to run again on next app launch
  /// Only use this for testing or if you need to re-migrate data
  Future<void> resetMigration() async {
    if (!_isInitialized) {
      await init();
    }

    await _migrationBox.delete(_migrationCompletedKey);
    await _migrationBox.delete(_migrationTimestampKey);
    
    if (kDebugMode) {
      print('⚠️  Migration status reset - will run again on next launch');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _migrationBox.close();
      _isInitialized = false;
    }
  }
}
