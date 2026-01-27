import 'dish.dart';

class OrderItem {
  final Dish dish;
  int quantity;

  OrderItem({
    required this.dish,
    this.quantity = 1,
  });

  double get totalPrice => dish.price * quantity;

  void incrementQuantity() {
    quantity++;
  }

  void decrementQuantity() {
    if (quantity > 0) {
      quantity--;
    }
  }

  // Copy with method
  OrderItem copyWith({
    Dish? dish,
    int? quantity,
  }) {
    return OrderItem(
      dish: dish ?? this.dish,
      quantity: quantity ?? this.quantity,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'dish': dish.toJson(),
      'quantity': quantity,
    };
  }

  // Create from JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      dish: Dish.fromJson(json['dish'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }
}
