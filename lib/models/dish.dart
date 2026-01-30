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

  @HiveField(3, defaultValue: 'Vollailes')
  late String type;

  @HiveField(4, defaultValue: false)
  late bool hasVariant;

  @HiveField(5) // Nullable, no default value needing verification beyond null
  String? variant; // 'sec', 'complet', or null

  Dish({
    required this.id,
    required this.name,
    required this.price,
    this.type = 'Vollailes', // Default category
    this.hasVariant = false,
    this.variant,
  });

  // Copy with method for updates
  Dish copyWith({
    String? id,
    String? name,
    double? price,
    String? type,
    bool? hasVariant,
    String? variant,
  }) {
    return Dish(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      type: type ?? this.type,
      hasVariant: hasVariant ?? this.hasVariant,
      variant: variant ?? this.variant,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'type': type,
      'hasVariant': hasVariant,
      'variant': variant,
    };
  }

  // Create from JSON
  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      type: json['type'] as String? ?? 'Vollailes',
      hasVariant: json['hasVariant'] as bool? ?? false,
      variant: json['variant'] as String?,
    );
  }
}
