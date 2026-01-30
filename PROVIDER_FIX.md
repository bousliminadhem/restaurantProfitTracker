# Provider Scope Fix

## Issue
When navigating to `ServiceScreen` or `DishManagementScreen`, the app threw:
```
ProviderNotFoundException: Could not find the correct Provider<DishProvider> above this ServiceScreen Widget
```

## Root Cause
The `MultiProvider` was only wrapping the `HomeScreen` widget instead of the entire `MaterialApp`. When Navigator.push() created new routes, those routes were outside the MultiProvider's scope and couldn't access the providers.

**Before (BROKEN):**
```dart
MaterialApp(
  home: isInitializing
    ? SplashScreen()
    : MultiProvider(  // ❌ Only HomeScreen has providers
        providers: [...],
        child: HomeScreen(),
      ),
)
```

**After (FIXED):**
```dart
MultiProvider(  // ✅ All routes have providers
  providers: [...],
  child: MaterialApp(
    home: isInitializing ? SplashScreen() : HomeScreen(),
  ),
)
```

## Solution Applied
Restructured `lib/main.dart` to:
1. Show splash/error screens in separate MaterialApp instances (without providers)
2. Wrap the main MaterialApp with MultiProvider so ALL routes have access to providers
3. This ensures ServiceScreen, DishManagementScreen, and any future screens can access DishProvider and ServiceProvider

## Files Modified
- `lib/main.dart` - Restructured provider scope

## Test
✅ Start Service button now works
✅ Manage Dishes button now works
✅ All screens can access providers via `Provider.of<T>(context)`

The fix ensures that when you use `Navigator.push()` to go to any screen, those screens are still within the MultiProvider's widget tree and can access the providers properly.
