# Testing Dynamic Geofencing - Quick Guide

## Quick Test Procedure

### 1. Setup (2 minutes)
```bash
# In terminal where flutter run is active
Press 'R' to hot restart
```

### 2. Login and Navigate
1. Open app
2. Login as any user (e.g., user1@gmail.com)
3. Tap menu → "Geofence View"

### 3. What You Should See

#### Initial View
```
┌─────────────────────────────────────┐
│ ✅ Safe Zone              [or]      │
│ ⚠️ Risky Zone                       │
├─────────────────────────────────────┤
│ Avg Distance: X.Xm                  │
│ Threshold: 10m                      │
│ Nearby Users: N                     │
└─────────────────────────────────────┘
```

## Test Scenarios

### ✅ Test 1: Safe Zone (Easiest)
**Method A**: Using Supabase Dashboard
1. Open Supabase → Table Editor → `users` table
2. Find your logged-in user (e.g., User1)
3. Find another user (e.g., User2)
4. Set their locations close together:
   ```
   User1: Lat=12.9352, Lon=77.6245
   User2: Lat=12.9353, Lon=77.6246  (very close)
   ```
5. Wait 1-2 seconds

**Expected**:
- Safety card shows **"✅ Safe Zone"** (green)
- Average distance < 10m
- No popup appears

### ⚠️ Test 2: Risky Zone (Key Feature)
**Method A**: Using Supabase Dashboard
1. Set users far apart:
   ```
   User1: Lat=12.9352, Lon=77.6245
   User2: Lat=12.9400, Lon=77.6300  (far away)
   ```
2. Wait 1-2 seconds

**Expected**:
1. Safety card changes to **"⚠️ Risky Zone"** (red)
2. **Popup appears** asking "Are you safe?"
3. Shows average distance > 10m

**Method B**: Walk Away (If using real devices)
1. Login User1 and User2 on two phones
2. Keep them close initially (safe zone)
3. Walk 15+ meters apart with one phone
4. Wait for popup

### 📱 Test 3: Popup Responses

#### Response A: "I'm Safe"
1. Trigger risky zone
2. Click "I'm Safe" button
3. **Expected**: Green success message, popup closes
4. Wait 30 seconds before popup can show again

#### Response B: "Need Help"
1. Trigger risky zone
2. Click "Need Help" button
3. **Expected**: Emergency dialog appears
4. Shows who will be alerted
5. Click "Send Alert"
6. **Expected**: Red alert notification sent

## Manual Testing Values

### Scenario 1: All Users Close (Safe)
```
User1: Lat=12.9352, Lon=77.6245
User2: Lat=12.9353, Lon=77.6246  (~111m difference)
User3: Lat=12.9354, Lon=77.6247  (~222m difference)
User4: Lat=12.9355, Lon=77.6248  (~333m difference)

Average Distance: ~222m
Status: RISKY (exceeds 10m)
```

### Scenario 2: Very Close (Safe)
```
User1: Lat=11.3600, Lon=77.8270
User2: Lat=11.3600, Lon=77.8271  (~5m)
User3: Lat=11.3601, Lon=77.8270  (~5m)

Average Distance: ~5m
Status: SAFE
```

### Scenario 3: Mixed Distances
```
User1: Lat=11.3600, Lon=77.8270
User2: Lat=11.3600, Lon=77.8271  (~5m)
User3: Lat=11.3605, Lon=77.8275  (~700m)

Average: (5 + 700) / 2 = 352.5m
Status: RISKY
```

## Console Logs to Watch

### Safe Zone Detection
```
🔍 Checking safety status for User1...
📊 Found 2 other online users to check
  - Distance to User2: 8.50m
  - Distance to User3: 7.20m
📏 Average distance to all users: 7.85m (threshold: 10.0m)
✅ ENTERED SAFE ZONE! Average distance: 7.85m
```

### Risky Zone Detection
```
🔍 Checking safety status for User1...
📊 Found 2 other online users to check
  - Distance to User2: 15.20m
  - Distance to User3: 18.50m
📏 Average distance to all users: 16.85m (threshold: 10.0m)
⚠️ ENTERED RISKY ZONE! Average distance: 16.85m
```

## Visual Indicators

### Safe Zone (Green)
- 🛡️ Shield icon
- Green border (2px)
- Light green background
- Elevation: 2
- Shows "within Xm" message

### Risky Zone (Red)
- ⚠️ Warning icon
- Red border (2px)
- Light red background
- Elevation: 8 (appears raised)
- Animated notification icon
- "Safety Check" button visible

## Troubleshooting

### ❌ "No safety status showing"
**Fix**: Ensure at least one other user is online
```sql
-- In Supabase
UPDATE users SET is_online = true WHERE name = 'User2';
```

### ❌ "Always shows risky zone"
**Reason**: Other users are far away or offline
**Fix**: 
1. Set users closer in Supabase
2. Ensure users have `is_online = true`
3. Check `latitude` and `longitude` are not null

### ❌ "Popup doesn't appear"
**Check**:
1. Safety status IS risky (check card)
2. Haven't shown popup recently (30s cooldown)
3. Check console for "ENTERED RISKY ZONE" message

**Debug**:
```dart
print('Has shown popup: $_hasShownRiskyPopup');
print('Status: ${_safetyData?.status}');
```

### ❌ "Popup appears too often"
**Fix**: Increase cooldown
```dart
// In _handleSafe() method
Future.delayed(const Duration(seconds: 60), () { // Changed from 30
  _hasShownRiskyPopup = false;
});
```

## Quick Distance Reference

```
Latitude/Longitude Difference → Approximate Distance
0.0001 degree ≈ 11 meters
0.0005 degree ≈ 55 meters
0.001 degree ≈ 111 meters
0.01 degree ≈ 1.1 kilometers
```

### Example Calculations
```
Point A: (12.9352, 77.6245)
Point B: (12.9353, 77.6246)

Difference: 0.0001 lat, 0.0001 lon
Distance: ~15 meters (diagonal)
```

## Success Criteria

### ✅ Feature Working Correctly If:
1. Safety card appears at top of geofence view
2. Card shows green when users are close (< 10m average)
3. Card shows red when users are far (>= 10m average)
4. Popup appears when entering risky zone
5. Popup has two buttons: "Need Help" and "I'm Safe"
6. "I'm Safe" closes popup with success message
7. "Need Help" opens emergency alert dialog
8. Status updates in real-time (1-2 second latency)

### 📊 Metrics to Verify
- Average distance calculation is correct
- Threshold is 10.0m by default
- Nearby users count matches number of online users
- Update counter increments with each status check

## Advanced Testing

### Multi-Device Test
1. Use 3+ physical devices
2. Login different users on each
3. Vary distances between devices
4. Watch all devices update simultaneously

### Threshold Adjustment Test
```dart
// Change threshold temporarily
double _safetyThreshold = 5.0; // More sensitive
// or
double _safetyThreshold = 20.0; // Less sensitive
```

### Offline User Test
1. Set User2 as offline in Supabase
2. Verify they're excluded from calculation
3. Average should only include online users

## Performance Benchmarks

**Expected Performance**:
- Safety check duration: < 1ms
- UI update latency: < 100ms
- Popup appearance: < 500ms after risky detection
- Memory usage: < 5MB additional

**Console Performance Logs**:
```
🔍 Checking safety status... [START]
📊 Found 3 users
📏 Calculated average: 12.5m
⚠️ Determined risky zone
✅ Updated UI [0.8ms elapsed]
```

## Next Steps After Testing

If all tests pass:
1. ✅ Dynamic geofencing is working
2. ✅ Safety monitoring is active
3. ✅ Emergency alerts are functional

Consider:
- Adjusting threshold based on use case
- Customizing popup messages
- Adding more emergency contact options
- Implementing automatic escalation

---

**Happy Testing!** 🛡️ Your safety monitoring is now live!
