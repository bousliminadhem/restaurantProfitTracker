import 'package:flutter/foundation.dart';
import '../models/dish.dart';
import '../models/order_item.dart';
import '../models/service_shift.dart';
import '../repositories/shift_repository.dart';

class ServiceProvider extends ChangeNotifier {
  final ShiftRepository _repository;
  bool _isLoading = false;
  
  ServiceProvider(this._repository) {
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    
    await _repository.getShiftHistory();
    
    _isLoading = false;
    notifyListeners();
  }
  
  bool get isServiceActive => _repository.hasActiveShift;
  DateTime? get serviceStartTime => _repository.activeShift?.startTime;
  
  List<OrderItem> get currentOrders {
    return _repository.activeOrderItems.map((item) {
      return OrderItem(
        dish: Dish.fromJson(item['dish']),
        quantity: item['quantity'] as int,
      );
    }).toList();
  }
  
  List<ServiceShift> get shiftHistory {
    return _repository.shiftHistory;
  }

  // We need to be able to get the history synchronously for the UI
  // I should probably add a getter to ShiftRepository or handle it here
  Future<List<ServiceShift>> getShiftHistory() async {
    return await _repository.getShiftHistory();
  }
  
  double get totalProfit => _repository.currentShiftTotal;
  bool get isLoading => _isLoading;
  
  // Start a new service
  Future<void> startService() async {
    await _repository.startShift();
    notifyListeners();
  }
  
  // Add a dish to current service
  Future<void> addDishToService(Dish dish) async {
    if (!isServiceActive) return;
    await _repository.addDishToShift(dish);
    notifyListeners();
  }
  
  // Remove one quantity of a dish from service
  Future<void> removeDishFromService(String dishId) async {
    if (!isServiceActive) return;
    await _repository.removeDishFromShift(dishId);
    notifyListeners();
  }
  
  // Remove all quantities of a dish from service
  Future<void> removeAllDishFromService(String dishId) async {
    if (!isServiceActive) return;
    await _repository.removeDishFromShift(dishId, removeAll: true);
    notifyListeners();
  }
  
  // End the current service
  Future<void> endService() async {
    if (!isServiceActive) return;
    await _repository.endShift();
    notifyListeners();
  }
  
  // Clear shift history
  Future<void> clearHistory() async {
    await _repository.clearHistory();
    notifyListeners();
  }
  
  // Sync shifts
  Future<void> syncShifts() async {
    await _repository.syncShifts();
    notifyListeners();
  }

  // Get order item for a dish
  OrderItem? getOrderItem(String dishId) {
    if (!isServiceActive) return null;
    final item = _repository.activeOrderItems.firstWhere(
      (item) => item['dish']['id'] == dishId,
      orElse: () => {},
    );
    if (item.isEmpty) return null;
    
    return OrderItem(
      dish: Dish.fromJson(item['dish']),
      quantity: item['quantity'] as int,
    );
  }
}
