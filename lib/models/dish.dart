import 'package:hive/hive.dart';

part 'dish.g.dart';

@HiveType(typeId: 0)
class Dish extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double price;

  Dish({
    required this.id,
    required this.name,
    required this.price,
  });

  // Copy with method for updates
  Dish copyWith({
    String? id,
    String? name,
    double? price,
  }) {
    return Dish(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }

  // Create from JSON
  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}
