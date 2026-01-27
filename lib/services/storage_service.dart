import 'package:hive_flutter/hive_flutter.dart';
import '../models/dish.dart';

class StorageService {
  static const String dishBoxName = 'dishes';
  static const String shiftHistoryBoxName = 'shift_history';
  
  late Box<Dish> _dishBox;
  late Box _shiftHistoryBox;
  
  // Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DishAdapter());
    }
    
    // Open boxes
    _dishBox = await Hive.openBox<Dish>(dishBoxName);
    _shiftHistoryBox = await Hive.openBox(shiftHistoryBoxName);
  }
  
  // Dish operations
  Future<void> saveDish(Dish dish) async {
    await _dishBox.put(dish.id, dish);
  }
  
  Future<void> deleteDish(String id) async {
    await _dishBox.delete(id);
  }
  
  List<Dish> getAllDishes() {
    return _dishBox.values.toList();
  }
  
  Dish? getDish(String id) {
    return _dishBox.get(id);
  }
  
  // Shift history operations
  Future<void> saveShiftHistory(Map<String, dynamic> shift) async {
    final shifts = getShiftHistory();
    shifts.add(shift);
    await _shiftHistoryBox.put('shifts', shifts);
  }
  
  List<Map<String, dynamic>> getShiftHistory() {
    final data = _shiftHistoryBox.get('shifts', defaultValue: <dynamic>[]);
    return (data as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
  
  Future<void> clearShiftHistory() async {
    await _shiftHistoryBox.clear();
  }
  
  // Close boxes
  Future<void> close() async {
    await _dishBox.close();
    await _shiftHistoryBox.close();
  }
}
