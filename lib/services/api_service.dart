import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dish.dart';
import '../models/order_item.dart';
import '../models/service_shift.dart';

/// API Service for Restaurant Profit Tracker Backend
/// 
/// Base URL Configuration:
/// - Development (local): http://localhost:8081
/// - Development (physical device): http://<YOUR_IP>:8081
/// - Production: https://your-domain.com
class ApiService {
  // TODO: Update this URL based on your environment
  static const String baseUrl = 'http://localhost:8081';
  
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Helper method to get common headers
  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  /// ====================
  /// DISH API METHODS
  /// ====================

  /// GET /api/dishes - Fetch all dishes
  Future<List<Dish>> getAllDishes() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/dishes'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Dish.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load dishes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dishes: $e');
    }
  }

  /// GET /api/dishes/{id} - Fetch dish by ID
  Future<Dish> getDishById(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/dishes/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return Dish.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Dish not found');
      } else {
        throw Exception('Failed to load dish: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dish: $e');
    }
  }

  /// POST /api/dishes - Create new dish
  Future<Dish> createDish(Dish dish) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/dishes'),
        headers: _headers,
        body: json.encode(dish.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Dish.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create dish: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating dish: $e');
    }
  }

  /// PUT /api/dishes/{id} - Update existing dish
  Future<Dish> updateDish(String id, Dish dish) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/api/dishes/$id'),
        headers: _headers,
        body: json.encode(dish.toJson()),
      );

      if (response.statusCode == 200) {
        return Dish.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Dish not found');
      } else {
        throw Exception('Failed to update dish: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating dish: $e');
    }
  }

  /// DELETE /api/dishes/{id} - Delete dish
  Future<void> deleteDish(String id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/dishes/$id'),
        headers: _headers,
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete dish: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting dish: $e');
    }
  }

  /// ====================
  /// SHIFT API METHODS
  /// ====================

  /// POST /api/shifts/start - Start new shift
  Future<ServiceShift> startShift() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/shifts/start'),
        headers: _headers,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return _parseServiceShift(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to start shift');
      }
    } catch (e) {
      throw Exception('Error starting shift: $e');
    }
  }

  /// GET /api/shifts/active - Get active shift
  Future<ServiceShift?> getActiveShift() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/shifts/active'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return _parseServiceShift(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null; // No active shift
      } else {
        throw Exception('Failed to get active shift: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching active shift: $e');
    }
  }

  /// POST /api/shifts/{id}/add-dish - Add dish to shift
  Future<ServiceShift> addDishToShift(int shiftId, String dishId, {int quantity = 1}) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/shifts/$shiftId/add-dish'),
        headers: _headers,
        body: json.encode({
          'dishId': dishId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        return _parseServiceShift(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to add dish to shift');
      }
    } catch (e) {
      throw Exception('Error adding dish to shift: $e');
    }
  }

  /// POST /api/shifts/{id}/end - End shift
  Future<ServiceShift> endShift(int shiftId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/shifts/$shiftId/end'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return _parseServiceShift(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to end shift');
      }
    } catch (e) {
      throw Exception('Error ending shift: $e');
    }
  }

  /// GET /api/shifts - Get all shifts
  Future<List<ServiceShift>> getAllShifts() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/shifts'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => _parseServiceShift(json)).toList();
      } else {
        throw Exception('Failed to load shifts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shifts: $e');
    }
  }

  /// GET /api/shifts/{id} - Get shift by ID
  Future<ServiceShift> getShiftById(int id) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/shifts/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return _parseServiceShift(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Shift not found');
      } else {
        throw Exception('Failed to load shift: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shift: $e');
    }
  }

  /// GET /api/shifts/completed - Get completed shifts
  Future<List<ServiceShift>> getCompletedShifts() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/shifts/completed'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => _parseServiceShift(json)).toList();
      } else {
        throw Exception('Failed to load completed shifts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching completed shifts: $e');
    }
  }

  /// ====================
  /// HELPER METHODS
  /// ====================

  /// Parse ServiceShift from JSON (handles orderItems conversion)
  ServiceShift _parseServiceShift(Map<String, dynamic> json) {
    // Convert orderItems from backend format to Flutter format
    final List<Map<String, dynamic>> orderItems = 
        (json['orderItems'] as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();

    return ServiceShift(
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      orderItems: orderItems,
      totalProfit: (json['totalProfit'] as num).toDouble(),
    );
  }

  /// Dispose HTTP client
  void dispose() {
    _client.close();
  }
}
