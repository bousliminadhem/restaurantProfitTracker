class ServiceShift {
  final DateTime startTime;
  DateTime? endTime;
  final List<Map<String, dynamic>> orderItems; // Stores order items as JSON
  double totalProfit;

  ServiceShift({
    required this.startTime,
    this.endTime,
    List<Map<String, dynamic>>? orderItems,
    this.totalProfit = 0.0,
  }) : orderItems = orderItems ?? [];

  bool get isActive => endTime == null;

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'orderItems': orderItems,
      'totalProfit': totalProfit,
    };
  }

  // Create from JSON
  factory ServiceShift.fromJson(Map<String, dynamic> json) {
    return ServiceShift(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime'] as String) 
          : null,
      orderItems: (json['orderItems'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      totalProfit: (json['totalProfit'] as num).toDouble(),
    );
  }
}
