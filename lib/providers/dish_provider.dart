import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/dish.dart';
import '../repositories/dish_repository.dart';

class DishProvider extends ChangeNotifier {
  final DishRepository _repository;
  List<Dish> _dishes = [];
  bool _isLoading = false;
  
  DishProvider(this._repository) {
    loadDishes();
  }
  
  List<Dish> get dishes => List.unmodifiable(_dishes);
  bool get isLoading => _isLoading;
  
  // Load dishes from repository (offline-first)
  Future<void> loadDishes() async {
    _isLoading = true;
    notifyListeners();
    
    _dishes = await _repository.getAllDishes();
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Add a new dish
  Future<void> addDish(String name, double price) async {
    final dish = Dish(
      id: const Uuid().v4(),
      name: name,
      price: price,
    );
    
    final created = await _repository.addDish(dish);
    _dishes.add(created);
    notifyListeners();
  }
  
  // Update an existing dish
  Future<void> updateDish(String id, String name, double price) async {
    final index = _dishes.indexWhere((dish) => dish.id == id);
    if (index != -1) {
      final updatedDish = _dishes[index].copyWith(
        name: name,
        price: price,
      );
      
      await _repository.updateDish(updatedDish);
      _dishes[index] = updatedDish;
      notifyListeners();
    }
  }
  
  // Delete a dish
  Future<void> deleteDish(String id) async {
    await _repository.deleteDish(id);
    _dishes.removeWhere((dish) => dish.id == id);
    notifyListeners();
  }
  
  // Force sync
  Future<void> syncDishes() async {
    await _repository.syncDishes();
    await loadDishes();
  }

  // Get dish by ID
  Dish? getDishById(String id) {
    try {
      return _dishes.firstWhere((dish) => dish.id == id);
    } catch (e) {
      return null;
    }
  }
}
