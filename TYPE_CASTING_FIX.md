# Type Casting Fix - Second Launch Error

## Problem
When opening the app for the second time after installation, users encountered this error:
```
Initialization Error

type '_Map<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>' in type cast
```

## Root Cause
The issue occurred because Hive (local storage) returns data as `Map<dynamic, dynamic>`, but the code was using direct type casting with `as Map<String, dynamic>`. This unsafe casting worked fine with data from the API (which returns properly typed JSON), but failed when loading cached data from Hive storage on subsequent app launches.

## Files Fixed

### 1. `lib/models/service_shift.dart` (Line 34)
**Before:**
```dart
orderItems: (json['orderItems'] as List<dynamic>)
    .map((e) => e as Map<String, dynamic>)
    .toList(),
```

**After:**
```dart
orderItems: (json['orderItems'] as List<dynamic>)
    .map((e) => Map<String, dynamic>.from(e as Map))
    .toList(),
```

### 2. `lib/services/api_service.dart` (Line 277)
**Before:**
```dart
final List<Map<String, dynamic>> orderItems = 
    (json['orderItems'] as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .toList();
```

**After:**
```dart
final List<Map<String, dynamic>> orderItems = 
    (json['orderItems'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
```

### 3. `lib/models/order_item.dart` (Line 46)
**Before:**
```dart
dish: Dish.fromJson(json['dish'] as Map<String, dynamic>),
```

**After:**
```dart
dish: Dish.fromJson(Map<String, dynamic>.from(json['dish'] as Map)),
```

## Solution Explanation
Instead of using direct type casting (`as Map<String, dynamic>`), we now use `Map<String, dynamic>.from(e as Map)`. This method:
- First casts to the generic `Map` type
- Then creates a new `Map<String, dynamic>` by copying the entries
- Properly converts the key-value types regardless of the source (Hive or API)

This is the same pattern already used successfully in `storage_service.dart` line 96.

## Testing
After applying these fixes:
1. The app should launch normally on first install
2. The app should launch normally on subsequent opens (using cached data from Hive)
3. No type casting errors should occur when loading data from local storage

## Next Steps
To verify the fix:
1. Uninstall the app from your Samsung device
2. Rebuild and install: `flutter run --release`
3. Open the app (first time - should work)
4. Close the app completely
5. Open the app again from the home screen icon (second time - should now work without errors)
