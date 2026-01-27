import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/dish.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

/// Repository for dish management
/// 
/// Implements offline-first architecture:
/// - Reads from Hive immediately for instant UI
/// - Syncs with backend in background
/// - Writes to Hive first, then syncs to backend
/// - Handles offline mode gracefully
class DishRepository {
  final StorageService _storage;
  final ApiService _api;
  
  // Track sync status
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  
  DishRepository({
    required StorageService storage,
    required ApiService api,
  })  : _storage = storage,
        _api = api;

  /// Get all dishes (offline-first)
  /// 
  /// Flow:
  /// 1. Load from Hive immediately
  /// 2. Trigger background sync
  /// 3. Return local data (no waiting)
  Future<List<Dish>> getAllDishes() async {
    // 1. Get local data immediately
    final localDishes = _storage.getAllDishes();
    
    // 2. Trigger background sync (don't await)
    _backgroundSync();
    
    // 3. Return local data for instant UI
    return localDishes;
  }

  /// Add a new dish
  /// 
  /// Flow:
  /// 1. Save to Hive first (offline support)
  /// 2. Attempt backend sync
  /// 3. If backend fails, keep local state
  Future<Dish> addDish(Dish dish) async {
    try {
      // 1. Save to local storage first
      await _storage.saveDish(dish);
      
      // 2. Attempt backend sync
      try {
        final syncedDish = await _api.createDish(dish);
        
        // Update local storage with backend-generated ID if different
        if (syncedDish.id != dish.id) {
          await _storage.deleteDish(dish.id);
          await _storage.saveDish(syncedDish);
          return syncedDish;
        }
        
        return dish;
      } catch (apiError) {
        // Backend failed, but local save succeeded
        if (kDebugMode) {
          print('⚠️ Dish saved locally, backend sync failed: $apiError');
        }
        // Return local dish, will sync later
        return dish;
      }
    } catch (e) {
      // Local save failed (critical)
      if (kDebugMode) {
        print('❌ Failed to save dish locally: $e');
      }
      rethrow;
    }
  }

  /// Update an existing dish
  /// 
  /// Flow:
  /// 1. Update Hive first
  /// 2. Attempt backend sync
  /// 3. If backend fails, keep local changes
  Future<void> updateDish(Dish dish) async {
    try {
      // 1. Update local storage first
      await _storage.saveDish(dish);
      
      // 2. Attempt backend sync
      try {
        await _api.updateDish(dish.id, dish);
      } catch (apiError) {
        if (kDebugMode) {
          print('⚠️ Dish updated locally, backend sync failed: $apiError');
        }
        // Will sync later
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update dish locally: $e');
      }
      rethrow;
    }
  }

  /// Delete a dish
  /// 
  /// Flow:
  /// 1. Delete from Hive first
  /// 2. Attempt backend sync
  /// 3. If backend fails, dish remains deleted locally
  Future<void> deleteDish(String id) async {
    try {
      // 1. Delete from local storage first
      await _storage.deleteDish(id);
      
      // 2. Attempt backend sync
      try {
        await _api.deleteDish(id);
      } catch (apiError) {
        if (kDebugMode) {
          print('⚠️ Dish deleted locally, backend sync failed: $apiError');
        }
        // Local deletion persists
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete dish locally: $e');
      }
      rethrow;
    }
  }

  /// Force sync with backend
  /// 
  /// Use this to manually trigger sync when:
  /// - App comes back online
  /// - User manually refreshes
  /// - Periodic background sync
  Future<void> syncDishes() async {
    if (_isSyncing) {
      if (kDebugMode) {
        print('⏳ Sync already in progress, skipping...');
      }
      return;
    }

    _isSyncing = true;
    try {
      // Get backend data
      final backendDishes = await _api.getAllDishes();
      
      // Get local data
      final localDishes = _storage.getAllDishes();
      
      // Create maps for efficient lookup
      final localMap = {for (var d in localDishes) d.id: d};
      final backendMap = {for (var d in backendDishes) d.id: d};
      
      // Sync strategy: Backend is source of truth
      // 1. Add/update dishes from backend
      for (final backendDish in backendDishes) {
        final localDish = localMap[backendDish.id];
        
        if (localDish == null) {
          // New dish from backend, add locally
          await _storage.saveDish(backendDish);
        } else {
          // Dish exists, check if backend version is different
          if (_isDishDifferent(localDish, backendDish)) {
            // Backend version wins
            await _storage.saveDish(backendDish);
          }
        }
      }
      
      // 2. Upload local-only dishes to backend
      for (final localDish in localDishes) {
        if (!backendMap.containsKey(localDish.id)) {
          try {
            // Upload to backend
            final syncedDish = await _api.createDish(localDish);
            
            // Update local ID if backend generated a different one
            if (syncedDish.id != localDish.id) {
              await _storage.deleteDish(localDish.id);
              await _storage.saveDish(syncedDish);
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Failed to upload local dish ${localDish.id}: $e');
            }
            // Keep local dish, will retry later
          }
        }
      }
      
      _lastSyncTime = DateTime.now();
      
      if (kDebugMode) {
        print('✅ Dish sync completed at $_lastSyncTime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Dish sync failed: $e');
      }
      // Don't rethrow - sync failure shouldn't crash app
    } finally {
      _isSyncing = false;
    }
  }

  /// Background sync (non-blocking)
  void _backgroundSync() {
    // Don't sync if recently synced (within 30 seconds)
    if (_lastSyncTime != null) {
      final timeSinceSync = DateTime.now().difference(_lastSyncTime!);
      if (timeSinceSync.inSeconds < 30) {
        return;
      }
    }
    
    // Fire and forget
    syncDishes().catchError((error) {
      if (kDebugMode) {
        print('Background sync failed: $error');
      }
    });
  }

  /// Check if two dishes are different
  bool _isDishDifferent(Dish local, Dish backend) {
    return local.name != backend.name || local.price != backend.price;
  }

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Dispose resources
  void dispose() {
    _api.dispose();
  }
}
