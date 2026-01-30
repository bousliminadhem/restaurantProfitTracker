import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/dish.dart';

class StorageService {
  static const String dishBoxName = 'dishes';
  static const String shiftHistoryBoxName = 'shift_history';
  
  Box<Dish>? _dishBox;
  Box? _shiftHistoryBox;
  
  bool _isInitialized = false;
  
  // Initialize Hive and open boxes with proper safety checks
  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('⚠️ StorageService already initialized, skipping...');
      return;
    }
    
    try {
      debugPrint('📦 Initializing Hive...');
      
      // Initialize Hive only if not already initialized
      if (!Hive.isBoxOpen(dishBoxName) && !Hive.isBoxOpen(shiftHistoryBoxName)) {
        await Hive.initFlutter();
        debugPrint('✅ Hive initialized');
      }
      
      // Register adapters only if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DishAdapter());
        debugPrint('✅ DishAdapter registered');
      }
      
      // Open boxes only if not already open
      if (Hive.isBoxOpen(dishBoxName)) {
        _dishBox = Hive.box<Dish>(dishBoxName);
        debugPrint('✅ Dish box retrieved (already open)');
      } else {
        _dishBox = await Hive.openBox<Dish>(dishBoxName);
        debugPrint('✅ Dish box opened');
      }
      
      if (Hive.isBoxOpen(shiftHistoryBoxName)) {
        _shiftHistoryBox = Hive.box(shiftHistoryBoxName);
        debugPrint('✅ Shift history box retrieved (already open)');
      } else {
        _shiftHistoryBox = await Hive.openBox(shiftHistoryBoxName);
        debugPrint('✅ Shift history box opened');
      }
      
      _isInitialized = true;
      debugPrint('✅ StorageService fully initialized');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing StorageService: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  // Dish operations
  Future<void> saveDish(Dish dish) async {
    if (_dishBox == null) throw Exception('Dish box not initialized');
    await _dishBox!.put(dish.id, dish);
  }
  
  Future<void> deleteDish(String id) async {
    if (_dishBox == null) throw Exception('Dish box not initialized');
    await _dishBox!.delete(id);
  }
  
  List<Dish> getAllDishes() {
    if (_dishBox == null) return [];
    return _dishBox!.values.toList();
  }
  
  Dish? getDish(String id) {
    if (_dishBox == null) return null;
    return _dishBox!.get(id);
  }
  
  // Shift history operations
  Future<void> saveShiftHistory(Map<String, dynamic> shift) async {
    if (_shiftHistoryBox == null) throw Exception('Shift history box not initialized');
    final shifts = getShiftHistory();
    shifts.add(shift);
    await _shiftHistoryBox!.put('shifts', shifts);
  }
  
  List<Map<String, dynamic>> getShiftHistory() {
    if (_shiftHistoryBox == null) return [];
    final data = _shiftHistoryBox!.get('shifts', defaultValue: <dynamic>[]);
    return (data as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
  
  Future<void> clearShiftHistory() async {
    if (_shiftHistoryBox == null) return;
    await _shiftHistoryBox!.clear();
  }
  
  // Close boxes
  Future<void> close() async {
    if (_dishBox != null && _dishBox!.isOpen) {
      await _dishBox!.close();
    }
    if (_shiftHistoryBox != null && _shiftHistoryBox!.isOpen) {
      await _shiftHistoryBox!.close();
    }
    _isInitialized = false;
  }
}
