# 🏗️ Repository Architecture Documentation

## Overview

This document explains the repository-based architecture implemented for offline-first data synchronization between the Flutter app and Spring Boot backend.

---

## 📐 Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                     UI Layer                             │
│  (Screens, Widgets, Providers - NO direct data access)  │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ↓
┌─────────────────────────────────────────────────────────┐
│                Repository Layer (NEW)                    │
│  ┌──────────────────┐       ┌──────────────────┐       │
│  │  DishRepository  │       │ ShiftRepository  │       │
│  │                  │       │                  │       │
│  │ - Offline-first  │       │ - Offline-first  │       │
│  │ - Background sync│       │ - Background sync│       │
│  │ - Error handling │       │ - Error handling │       │
│  └────────┬─────────┘       └────────┬─────────┘       │
└───────────┼──────────────────────────┼─────────────────┘
            │                          │
     ┌──────┴──────┐            ┌──────┴──────┐
     ↓             ↓            ↓             ↓
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ Storage  │ │   API    │ │ Storage  │ │   API    │
│ Service  │ │ Service  │ │ Service  │ │ Service  │
│  (Hive)  │ │ (Spring) │ │  (Hive)  │ │ (Spring) │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
     ↓             ↓            ↓             ↓
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│   Hive   │ │  HTTP    │ │   Hive   │ │  HTTP    │
│   DB     │ │ Network  │ │   DB     │ │ Network  │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
```

---

## 🎯 Design Principles

### 1. **Separation of Concerns**

| Layer | Responsibility | What it CANNOT do |
|-------|----------------|-------------------|
| **UI** | Render views, handle user input | ❌ Access Hive directly<br>❌ Make HTTP calls<br>❌ Implement business logic |
| **Repository** | Data orchestration, sync logic | ❌ Render UI<br>❌ Access database directly |
| **Services** | Low-level data access | ❌ Make decisions about sync<br>❌ Access UI |

### 2. **Offline-First**

```dart
// ALWAYS load from local storage first
final data = await repository.getData();  // ← Returns immediately

// Then sync with backend in background
repository.syncData();  // ← Non-blocking, fire-and-forget
```

**Benefits:**
- ✅ Instant UI updates
- ✅ Works without internet
- ✅ Seamless user experience
- ✅ Data persists across sessions

### 3. **Graceful Degradation**

```
┌────────────────────────────────────┐
│ Write Operation Flow               │
├────────────────────────────────────┤
│ 1. Write to Hive ✅                │
│ 2. Attempt backend sync            │
│    ├─ Success ✅ → Done            │
│    └─ Failure ⚠️ → Log, retry later│
│                                    │
│ Result: User sees success always   │
│ (backend sync is transparent)      │
└────────────────────────────────────┘
```

---

## 📦 Components

### **DishRepository** (`repositories/dish_repository.dart`)

**Purpose:** Manage dish data with offline-first sync

**Key Methods:**

```dart
// Get all dishes (offline-first)
Future<List<Dish>> getAllDishes()
  └─ 1. Load from Hive immediately
  └─ 2. Trigger background sync
  └─ 3. Return local data

// Add a dish (write-through)
Future<Dish> addDish(Dish dish)
  └─ 1. Save to Hive first
  └─ 2. Attempt backend sync
  └─ 3. Return dish (even if backend fails)

// Update a dish
Future<void> updateDish(Dish dish)
  └─ Same pattern as addDish

// Delete a dish
Future<void> deleteDish(String id)
  └─ Same pattern as addDish

// Force sync
Future<void> syncDishes()
  └─ Bidirectional sync with backend
  └─ Backend is source of truth
  └─ Uploads local-only dishes
```

**Sync Strategy:**

| Scenario | Action |
|----------|--------|
| Dish exists on backend only | Download and save locally |
| Dish exists locally only | Upload to backend |
| Dish exists on both, different data | Backend version wins |
| Dish exists on both, same data | No action |

### **ShiftRepository** (`repositories/shift_repository.dart`)

**Purpose:** Manage service shifts with active shift state

**Key Methods:**

```dart
// Start a new shift
Future<ServiceShift> startShift()
  └─ 1. Check no active shift
  └─ 2. Create new shift in memory
  └─ 3. Sync start to backend (non-blocking)

// Add dish to active shift
Future<void> addDishToShift(Dish dish)
  └─ 1. Update in-memory shift
  └─ 2. Recalculate total
  └─ 3. Sync to backend (non-blocking)

// End shift
Future<ServiceShift> endShift()
  └─ 1. Set end time
  └─ 2. Save to Hive history
  └─ 3. Sync to backend
  └─ 4. Clear active shift

// Get shift history
Future<List<ServiceShift>> getShiftHistory()
  └─ Offline-first like dishes

// Force sync
Future<void> syncShifts()
  └─ Sync completed shifts to backend
```

**State Management:**

```
Active Shift:
├─ In-memory only (for performance)
├─ Persisted on endShift()
└─ NOT synced until completed

Completed Shifts:
├─ Saved to Hive immediately
├─ Synced to backend in background
└─ Never modified after completion
```

### **MigrationService** (`services/migration_service.dart`)

**Purpose:** One-time migration of existing Hive data to backend

**Key Features:**

- ✅ **Idempotent**: Safe to run multiple times
- ✅ **Flag-based**: Tracks completion in Hive
- ✅ **Duplicate detection**: Avoids re-uploading data
- ✅ **Comprehensive logging**: Shows what was migrated

**Flow:**

```
App Launch
    │
    ↓
Check migration flag
    │
    ├─ Completed? → Skip
    │
    └─ Not completed
        │
        ↓
    Migrate Dishes
        ├─ Check backend for existing dishes
        ├─ Upload local-only dishes
        └─ Update local IDs if needed
        │
        ↓
    Migrate Shifts
        ├─ Check backend for existing shifts
        ├─ Upload local-only shifts
        └─ Skip active shifts
        │
        ↓
    Set migration flag = true
        │
        ↓
    Never run again
```

**Usage:**

```dart
// In main.dart initialization
final migrationService = MigrationService(
  storage: storageService,
  api: apiService,
);

await migrationService.init();

if (!migrationService.isMigrationCompleted) {
  await migrationService.runMigration();
}
```

---

## 🔄 Data Flow Examples

### **Example 1: User Adds a Dish**

```
User clicks "Add Dish"
    │
    ↓
UI calls repository.addDish()
    │
    ↓
Repository
    ├─ Save to Hive ✅ (instant, returns immediately)
    │
    ├─ Attempt API call
    │   ├─ Success → Update local ID if needed
    │   └─ Failure → Log error, keep local dish
    │
    └─ Return dish to UI
        │
        ↓
UI shows success (user never sees backend failures)
```

**Timeline:**
- 0ms: User clicks button
- 10ms: Hive save complete, UI updates
- 200ms: API call completes (or fails silently)

**Benefits:**
- UI never blocks
- Works offline
- Data persists immediately

### **Example 2: User Opens Dish List**

```
User opens dish management screen
    │
    ↓
UI calls repository.getAllDishes()
    │
    ↓
Repository
    ├─ Read from Hive (instant)
    │
    ├─ Trigger background sync (non-blocking)
    │   ├─ Fetch from backend
    │   ├─ Compare with local data
    │   ├─ Update Hive if differences found
    │   └─ (UI watches Hive for changes)
    │
    └─ Return local dishes immediately
        │
        ↓
UI displays dishes (instant)
    │
    ├─ Background sync completes
    │   └─ If changes → UI auto-updates
    │
    └─ User sees data immediately
```

**Timeline:**
- 0ms: User navigates to screen
- 5ms: Local data loaded, UI displays
- 500ms: Background sync completes
- 510ms: UI updates if new data found

### **Example 3: App Starts for First Time**

```
App starts
    │
    ├─ Initialize StorageService
    ├─ Initialize ApiService
    │
    ↓
Initialize MigrationService
    │
    ├─ Check migration flag
    │   └─ Not set (first launch)
    │
    ↓
Run migration
    │
    ├─ Get all local dishes
    ├─ Get backend dishes
    ├─ Upload local-only dishes
    │   └─ Dish A: Exists → Skip
    │   └─ Dish B: New → Upload ✅
    │   └─ Dish C: New → Upload ✅
    │
    ├─ Get all local shifts
    ├─ Get backend shifts  
    ├─ Upload local-only shifts
    │   └─ Shift 1: Exists → Skip
    │   └─ Shift 2: New → Upload ✅
    │
    └─ Set migration flag = true
        │
        ↓
    Migration never runs again
        │
        ↓
    Normal operation (repositories handle sync)
```

---

## 🧪 Testing Strategy

### **Unit Tests**

```dart
// Test repository without network
testWidgets('DishRepository works offline', () async {
  final mockStorage = MockStorageService();
  final mockApi = MockApiService();
  
  // Make API service fail
  when(mockApi.getAllDishes()).thenThrow(Exception('No internet'));
  
  final repo = DishRepository(storage: mockStorage, api: mockApi);
  
  // Should still work with local data
  final dishes = await repo.getAllDishes();
  expect(dishes, isNotEmpty);
});
```

### **Integration Tests**

```dart
// Test full flow with real services
testWidgets('End-to-end dish creation', () async {
  final storage = StorageService();
  await storage.init();
  
  final api = ApiService();
  final repo = DishRepository(storage: storage, api: api);
  
  // Add dish
  final dish = Dish(id: '', name: 'Test', price: 10.0);
  final created = await repo.addDish(dish);
  
  // Verify in local storage
  expect(storage.getDish(created.id), isNotNull);
  
  // Verify sync to backend
  await repo.syncDishes();
  final backendDishes = await api.getAllDishes();
  expect(backendDishes.any((d) => d.id == created.id), isTrue);
});
```

---

## 📱 Migration to Repository Pattern

### **Before: Direct Service Access**

```dart
// ❌ OLD: Provider directly uses services
class DishProvider extends ChangeNotifier {
  final StorageService _storage;
  
  Future<void> addDish(Dish dish) async {
    await _storage.saveDish(dish);  // ❌ No backend sync
    notifyListeners();
  }
}
```

### **After: Repository Pattern**

```dart
// ✅ NEW: Provider uses repository
class DishProvider extends ChangeNotifier {
  final DishRepository _repository;
  
  Future<void> addDish(Dish dish) async {
    final created = await _repository.addDish(dish);  // ✅ Handles sync
    notifyListeners();
  }
}
```

### **Migration Steps**

1. **Create repositories** ✅ (Done)
2. **Update providers to use repositories** (Next step)
3. **Test offline functionality**
4. **Test sync functionality**
5. **Run one-time migration**
6. **Monitor sync logs**

---

## 🔍 Debugging & Monitoring

### **Check Repository Status**

```dart
// Check last sync time
print('Last sync: ${dishRepository.lastSyncTime}');

// Check if currently syncing
if (dishRepository.isSyncing) {
  print('Sync in progress...');
}
```

### **Migration Status**

```dart
// Check if migration completed
if (migrationService.isMigrationCompleted) {
  print('Migration completed at ${migrationService.migrationTimestamp}');
}
```

### **Debug Logs**

When running in debug mode, you'll see logs like:

```
✅ Dish saved locally, backend sync failed: SocketException
⚠️ Background sync failed: Connection refused
✅ Dish sync completed at 2026-01-27 11:30:00
```

---

## 🚀 Production Readiness

### **Checklist**

- [x] Repository layer implemented
- [x] Offline-first pattern
- [x] Background sync
- [x] Error handling
- [x] Migration service
- [x] Idempotent operations
- [ ] Provider integration (Next step)
- [ ] Integration testing
- [ ] Production deployment

### **Future Enhancements**

1. **Conflict Resolution**: Handle concurrent updates from multiple devices
2. **Delta Sync**: Only sync changed data instead of full sync
3. **Optimistic Updates**: Show updates immediately even before backend confirms
4. **Retry Logic**: Exponential backoff for failed syncs
5. **Sync Queue**: Queue operations when offline, process when online
6. **Analytics**: Track sync success rates, latency, etc.

---

## 📚 Additional Resources

- `DishRepository`: Offline-first dish management
- `ShiftRepository`: Service shift management with active state
- `MigrationService`: One-time Hive → Backend migration
- `TROUBLESHOOTING_FIXES.md`: Backend connectivity fixes
- `FLUTTER_INTEGRATION.md`: Full integration guide

---

**Last Updated:** 2026-01-27  
**Status:** Repository layer complete, ready for provider integration  
**Next Step:** Update providers to use repositories instead of services
