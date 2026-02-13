# 🔍 ROOT CAUSE ANALYSIS - Map Re-rendering Issue

## The Problem
Map constantly re-renders/blinks because GPS coordinates are **slightly changing** (GPS drift), triggering full page rebuilds.

## Root Causes Identified

### 1. ⚠️ OVERLY SENSITIVE GPS UPDATES
**File**: `lib/services/user_location_service.dart`

```dart
// Lines 96-100
locationSettings: const LocationSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  distanceFilter: 0, // ❌ Updates on ANY movement (even 0.1m GPS drift!)
  timeLimit: Duration.zero,
),

// Lines 146-150
return distance > 0.5 || timeSinceUpdate.inSeconds > 1 || accuracyImproved;
// ❌ Pushes update if moved 0.5m OR 1 second passed
```

**Impact**: GPS naturally drifts 1-5 meters even when stationary! Every tiny drift triggers an update.

### 2. ⚠️ DOUBLE POLLING SYSTEM
**File**: `lib/pages/geofence_view_page.dart`

```dart
// Line 48-53: Aggressive polling timer
_refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
  _loadUsers();        // ❌ Fetches ALL users EVERY SECOND
  _checkSafetyStatus();
});

// Line 42: Also subscribed to Realtime
_subscribeToUpdates(); // ❌ WebSocket also triggers updates
```

**Impact**: We have BOTH:
- Timer polling (every 1 second)
- Realtime WebSocket (on every GPS change)

**Result**: Updates happening 2-3 times per second!

### 3. ⚠️ NO CHANGE DETECTION
**File**: `lib/pages/geofence_view_page.dart`

```dart
// Lines 162-182: Always calls setState
setState(() {
  _users = List.from(users);           // New list instance
  _currentUser = UserModel(...);       // New user instance
  _updateCounter++;                     // Force rebuild counter
});
```

**Impact**: setState called **even if location didn't meaningfully change**!
- GPS changes from `11.360053` to `11.360054` (0.1 meter)
- Still triggers full page rebuild
- Map widget receives "new" data
- Map attempts to re-render

### 4. ⚠️ UPDATE COUNTER INCREMENT
**File**: `lib/pages/geofence_view_page.dart`

```dart
// Line 181 & 244
_updateCounter++; // Increments on EVERY update
```

**Impact**: Counter goes 661, 662, 663... every second, forcing rebuilds.

## The Cascade Effect

```
GPS naturally drifts 0.5m (device sitting on desk!)
    ↓
UserLocationService: "Movement detected!" (distanceFilter: 0)
    ↓
Push to Supabase (update users table)
    ↓
Supabase Realtime: "Change detected!"
    ↓
WebSocket callback triggers _subscribeToUpdates()
    ↓
setState() called (creates new _users list, new _currentUser)
    ↓
FULL PAGE REBUILD (_updateCounter++)
    ↓
UserMapWidget receives "new" users list
    ↓
didUpdateWidget() called (coordinates changed 0.0000001°)
    ↓
Map attempts to render new position
    ↓
BLINK/STUTTER/RE-RENDER
    ↓
Meanwhile... 1 second timer fires
    ↓
_loadUsers() fetches from Supabase
    ↓
ANOTHER setState()
    ↓
ANOTHER FULL PAGE REBUILD
    ↓
ANOTHER BLINK
    ↓
REPEAT FOREVER (multiple times per second)
```

## Evidence from Console Logs

User would see this pattern:
```
📍 Live position update: Lat=11.360053, Lon=77.827360
✅ Live update pushed: Lat=11.360053, Lon=77.827360
🔔 Realtime update received for users table
📊 Fetched 4 users after realtime update
🔄 Realtime callback triggered with 4 users
📊 Realtime: Old Lat=11.360053, Old Lon=77.827360
📊 Realtime: New Lat=11.360054, New Lon=77.827360  ← 0.1m change!
✅ UI updated via realtime: 4 users (update #661)
[1 second later]
🔄 Loading users from Supabase...
📊 Before setState: Old Lat=11.360054, Old Lon=77.827360
📊 Before setState: New Lat=11.360054, New Lon=77.827361  ← Another tiny change!
✅ UI state updated with 4 users (update #662)
[Repeat every second...]
```

## Why This Causes Blinking

### Every setState() triggers:
1. ✅ Full widget tree rebuild
2. ✅ `UserMapWidget.didUpdateWidget()` called
3. ✅ Markers recalculated
4. ✅ Map attempts re-render (even for 0.1m change)
5. ✅ Brief flash/blink as tiles/markers redraw
6. ✅ 60 FPS stutters

### With 2-3 setState() per second:
- **Visible blinking** every 0.5-1 seconds
- **Map feels jittery** because it's rebuilding constantly
- **Can't interact** because user gestures interrupted by rebuilds

## Solutions Needed

### 1. Reduce GPS Sensitivity
Change `distanceFilter: 0` → `distanceFilter: 10` (10 meters)

### 2. Remove Polling Timer
Remove the 1-second `_refreshTimer` - rely ONLY on Realtime WebSocket

### 3. Add Change Detection
Only call setState if location changed more than 5 meters

### 4. Debounce setState Calls
Don't allow setState more than once every 2-3 seconds

### 5. Optimize Map Widget
Prevent map rebuilds for sub-5 meter changes

## Summary

The map isn't broken - it's **over-updating**!

**Current behavior**: Updates 2-3 times per second for 0.1m GPS drift  
**Desired behavior**: Update once every 5-10 seconds for meaningful movement (>10m)

**The fix**: Make the system less sensitive and eliminate redundant update mechanisms.
