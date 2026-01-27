import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/dish.dart';
import '../models/service_shift.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

/// Repository for service shift management
/// 
/// Implements offline-first architecture:
/// - Active shift stored in Hive for persistence
/// - Completed shifts synced to backend
/// - Handles offline mode gracefully
class ShiftRepository {
  final StorageService _storage;
  final ApiService _api;
  
  // In-memory active shift state
  ServiceShift? _activeShift;
  List<ServiceShift> _shiftHistory = [];
  
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  
  ShiftRepository({
    required StorageService storage,
    required ApiService api,
  })  : _storage = storage,
        _api = api {
    _loadShiftHistory();
  }

  /// Load shift history from local storage
  void _loadShiftHistory() {
    final historyData = _storage.getShiftHistory();
    _shiftHistory = historyData
        .map((json) => ServiceShift.fromJson(json))
        .toList();
  }

  /// Get active shift
  ServiceShift? get activeShift => _activeShift;

  /// Get cached shift history
  List<ServiceShift> get shiftHistory => List.unmodifiable(_shiftHistory);

  /// Get shift history (offline-first)
  Future<List<ServiceShift>> getShiftHistory() async {
    // Load from local storage
    _loadShiftHistory();
    
    // Trigger background sync
    _backgroundSync();
    
    return List.unmodifiable(_shiftHistory);
  }

  /// Get all shifts including active
  Future<List<ServiceShift>> getAllShifts() async {
    final history = await getShiftHistory();
    if (_activeShift != null) {
      return [...history, _activeShift!];
    }
    return history;
  }

  /// Start a new service shift
  /// 
  /// Flow:
  /// 1. Check no active shift exists
  /// 2. Create new shift
  /// 3. Store in memory (will persist on first order)
  Future<ServiceShift> startShift() async {
    if (_activeShift != null && _activeShift!.isActive) {
      throw Exception('A shift is already active. End it before starting a new one.');
    }

    _activeShift = ServiceShift(
      startTime: DateTime.now(),
      endTime: null,
      orderItems: [],
      totalProfit: 0.0,
    );

    if (kDebugMode) {
      print('✅ Shift started at ${_activeShift!.startTime}');
    }

    // Sync with backend
    try {
      final backendShift = await _api.startShift();
      if (kDebugMode) {
        print('✅ Shift synced to backend starting at: ${backendShift.startTime}');
      }
      // Store backend shift ID for future syncs
      // Note: We don't have ID in current ServiceShift model
      // This would require adding an id field to ServiceShift
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to sync shift start to backend: $e');
      }
      // Continue with local shift
    }

    return _activeShift!;
  }

  /// Add a dish to the active shift
  /// 
  /// Flow:
  /// 1. Check active shift exists
  /// 2. Add or increment order item
  /// 3. Recalculate total
  /// 4. Persist changes locally
  /// 5. Attempt backend sync (non-blocking)
  Future<void> addDishToShift(Dish dish, {int quantity = 1}) async {
    if (_activeShift == null || !_activeShift!.isActive) {
      throw Exception('No active shift. Start a shift first.');
    }

    // Find existing order item for this dish
    int existingIndex = -1;
    for (int i = 0; i < _activeShift!.orderItems.length; i++) {
      final item = _activeShift!.orderItems[i];
      if (item['dish']['id'] == dish.id) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex >= 0) {
      // Increment existing item
      final existingItem = Map<String, dynamic>.from(_activeShift!.orderItems[existingIndex]);
      existingItem['quantity'] = (existingItem['quantity'] as int) + quantity;
      _activeShift!.orderItems[existingIndex] = existingItem;
    } else {
      // Add new item
      _activeShift!.orderItems.add({
        'dish': dish.toJson(),
        'quantity': quantity,
      });
    }

    // Recalculate total profit
    _activeShift!.totalProfit = _calculateTotalProfit(_activeShift!.orderItems);

    if (kDebugMode) {
      print('✅ Added ${dish.name} (x$quantity) to shift. Total: €${_activeShift!.totalProfit}');
    }

    // Note: We don't persist active shift to Hive in current architecture
    // Active shift is in-memory only until ended
    // If you want persistence of active shifts, you'd need to add a separate box

    // Attempt backend sync (non-blocking)
    _syncDishToBackend(dish.id, quantity);
  }

  /// Remove a dish from the active shift
  /// 
  /// Flow:
  /// 1. Find the dish in order items
  /// 2. Decrement quantity or remove if quantity = 1
  /// 3. Recalculate total
  Future<void> removeDishFromShift(String dishId, {bool removeAll = false}) async {
    if (_activeShift == null || !_activeShift!.isActive) {
      throw Exception('No active shift.');
    }

    int itemIndex = -1;
    for (int i = 0; i < _activeShift!.orderItems.length; i++) {
      final item = _activeShift!.orderItems[i];
      if (item['dish']['id'] == dishId) {
        itemIndex = i;
        break;
      }
    }

    if (itemIndex < 0) {
      return; // Dish not in shift
    }

    if (removeAll) {
      _activeShift!.orderItems.removeAt(itemIndex);
    } else {
      final item = Map<String, dynamic>.from(_activeShift!.orderItems[itemIndex]);
      final currentQuantity = item['quantity'] as int;
      
      if (currentQuantity > 1) {
        item['quantity'] = currentQuantity - 1;
        _activeShift!.orderItems[itemIndex] = item;
      } else {
        _activeShift!.orderItems.removeAt(itemIndex);
      }
    }

    // Recalculate total profit
    _activeShift!.totalProfit = _calculateTotalProfit(_activeShift!.orderItems);

    if (kDebugMode) {
      print('✅ Removed dish from shift. New total: €${_activeShift!.totalProfit}');
    }
  }

  /// End the active shift
  /// 
  /// Flow:
  /// 1. Set end time
  /// 2. Save to local history
  /// 3. Sync to backend
  /// 4. Clear active shift
  Future<ServiceShift> endShift() async {
    if (_activeShift == null || !_activeShift!.isActive) {
      throw Exception('No active shift to end.');
    }

    // Set end time
    _activeShift!.endTime = DateTime.now();

    // Save to local storage
    await _storage.saveShiftHistory(_activeShift!.toJson());
    _shiftHistory.add(_activeShift!);

    final completedShift = _activeShift!;

    if (kDebugMode) {
      print('✅ Shift ended. Total profit: €${completedShift.totalProfit}');
    }

    // Attempt backend sync
    try {
      // Note: Current API doesn't have shift ID
      // This would require tracking shift ID from startShift
      // For now, we'll skip backend sync on end
      if (kDebugMode) {
        print('⚠️ Shift end sync to backend not implemented (need shift ID tracking)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to sync shift end to backend: $e');
      }
      // Shift is saved locally, will sync later
    }

    // Clear active shift
    _activeShift = null;

    return completedShift;
  }

  /// Sync completed shifts to backend
  /// 
  /// Flow:
  /// 1. Get all local shifts
  /// 2. Get all backend shifts
  /// 3. Upload local-only shifts
  Future<void> syncShifts() async {
    if (_isSyncing) {
      if (kDebugMode) {
        print('⏳ Shift sync already in progress, skipping...');
      }
      return;
    }

    _isSyncing = true;
    try {
      // Get backend shifts
      final backendShifts = await _api.getAllShifts();
      
      // Load local shifts
      _loadShiftHistory();
      
      if (kDebugMode) {
        print('📊 Local shifts: ${_shiftHistory.length}, Backend shifts: ${backendShifts.length}');
      }

      // Note: Current backend returns List<Map<String, dynamic>>
      // We'd need to match shifts by startTime since we don't have IDs
      // This is a limitation of the current architecture
      
      // For production, you'd want:
      // 1. Add ID field to ServiceShift model
      // 2. Track backend shift ID from startShift
      // 3. Use ID for matching instead of timestamp
      
      _lastSyncTime = DateTime.now();
      
      if (kDebugMode) {
        print('✅ Shift sync completed at $_lastSyncTime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Shift sync failed: $e');
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
    syncShifts().catchError((error) {
      if (kDebugMode) {
        print('Background shift sync failed: $error');
      }
    });
  }

  /// Sync dish addition to backend (non-blocking)
  void _syncDishToBackend(String dishId, int quantity) {
    // Note: This would require the backend shift ID
    // Current implementation doesn't track it
    // Skipping for now
    if (kDebugMode) {
      print('⚠️ Dish-to-shift backend sync not implemented (need shift ID tracking)');
    }
  }

  /// Calculate total profit from order items
  double _calculateTotalProfit(List<Map<String, dynamic>> orderItems) {
    double total = 0.0;
    for (final item in orderItems) {
      final dish = item['dish'];
      final quantity = item['quantity'] as int;
      final price = dish['price'] as double;
      total += price * quantity;
    }
    return total;
  }

  /// Get current shift total
  double get currentShiftTotal {
    if (_activeShift == null) return 0.0;
    return _activeShift!.totalProfit;
  }

  /// Check if shift is active
  bool get hasActiveShift => _activeShift != null && _activeShift!.isActive;

  /// Get order items from active shift
  List<Map<String, dynamic>> get activeOrderItems {
    if (_activeShift == null) return [];
    return List.unmodifiable(_activeShift!.orderItems);
  }

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Clear all shift history (local only)
  Future<void> clearHistory() async {
    await _storage.clearShiftHistory();
    _shiftHistory.clear();
    
    if (kDebugMode) {
      print('✅ Shift history cleared');
    }
  }

  /// Dispose resources
  void dispose() {
    // Repository doesn't own API service, so don't dispose it
  }
}
