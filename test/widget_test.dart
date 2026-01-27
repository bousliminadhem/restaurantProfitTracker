// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_profit_tracker/main.dart';
import 'package:restaurant_profit_tracker/services/storage_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize storage service for testing
    final storageService = StorageService();
    await storageService.init();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(RestaurantProfitApp(storageService: storageService));

    // Verify that home screen loads
    expect(find.text('Restaurant Profit'), findsOneWidget);
    expect(find.text('Tracker'), findsOneWidget);
    
    // Verify main buttons are present
    expect(find.text('Start Service'), findsOneWidget);
    expect(find.text('Manage Dishes'), findsOneWidget);
  });
}
