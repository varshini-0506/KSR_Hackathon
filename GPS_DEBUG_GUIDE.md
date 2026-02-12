# GPS Debugging Guide

## Issues Fixed

### 1. ✅ Network Connections
- **Fixed**: Now ALL users connect to ALL other users (no distance restriction)
- **Before**: Only users within 5km were connected
- **After**: Complete network visualization showing all connections

### 2. ✅ User Name Labels
- **Fixed**: User names now display above each marker icon
- **Feature**: Names are color-coded (blue = you, green = online, gray = offline)
- **Location**: Names appear above the circular markers

### 3. ✅ GPS Data Reading
- **Enhanced**: Added comprehensive error handling and logging
- **Features**:
  - Detailed permission checking
  - Fallback to last known position if current position fails
  - Better error messages
  - Debug logging at every step

## How to Debug GPS Issues

### Check Console Logs

When you run the app, check the console for these messages:

```
Starting location updates for user: [user-id]
Location services enabled: true/false
Current location permission: [permission status]
Requesting location permission...
Permission request result: [result]
Location permission granted: [permission]
Getting initial location...
Fetching current position...
Position obtained: Lat=[lat], Lon=[lon], Accuracy=[acc]m
✅ User location updated in Supabase: Lat=[lat], Lon=[lon]
```

### Common Issues & Solutions

#### Issue 1: "Location services are disabled"
**Solution**: 
- Go to Device Settings → Location → Turn ON
- Make sure "Use location" is enabled

#### Issue 2: "Location permissions are denied"
**Solution**:
- Go to Device Settings → Apps → Vigil → Permissions → Location
- Grant "Allow all the time" or "Allow only while using the app"

#### Issue 3: "Location permissions are permanently denied"
**Solution**:
- Go to Device Settings → Apps → Vigil → Permissions → Location
- Enable "Allow all the time"
- Or uninstall and reinstall the app

#### Issue 4: GPS not updating in Supabase
**Check**:
1. Console logs show "✅ User location updated"?
   - If YES → Check Supabase table directly
   - If NO → Check error messages

2. Is internet connection working?
   - Check if other Supabase operations work

3. Is Supabase configured correctly?
   - Verify `supabase_config.dart` has correct credentials

#### Issue 5: Position timeout
**Solution**:
- Make sure you're in an area with GPS signal (not indoors)
- Try going outside or near a window
- Wait a few seconds for GPS to lock

## Testing GPS

### Step 1: Check Permissions
1. Run the app
2. Login
3. Check console for permission messages
4. If denied, grant permission when prompted

### Step 2: Verify Location Updates
1. Login and go to Home page
2. Check console logs every 7 seconds
3. You should see: "✅ User location updated"
4. Go to Geofence View
5. You should see your location marker

### Step 3: Check Supabase
1. Go to Supabase Dashboard → Table Editor → `users` table
2. Find your user
3. Check `latitude` and `longitude` columns
4. Check `last_location_update` timestamp
5. Should update every 7 seconds

### Step 4: Test on Multiple Devices
1. Login as different users on different devices
2. All should update their locations
3. All should appear on the geofence map
4. All should be connected with network lines

## Debug Commands

### Check Current User Location
```dart
final authService = UserAuthService();
final user = authService.getCurrentUser();
print('User: ${user?.name}');
print('Location: ${user?.latitude}, ${user?.longitude}');
```

### Force Location Update
```dart
final locationService = UserLocationService();
await locationService.startLocationUpdates(userId);
```

### Check All Users
```dart
final locationService = UserLocationService();
final users = await locationService.getAllUsers();
for (var user in users) {
  print('${user.name}: ${user.latitude}, ${user.longitude}');
}
```

## Expected Behavior

1. **On Login**: 
   - Location updates start immediately
   - First location fetched within 10 seconds
   - Updates continue every 7 seconds

2. **On Geofence View**:
   - All users displayed with names
   - All users connected with lines
   - Current user shown in blue
   - Online users shown in green
   - Offline users shown in gray

3. **In Supabase**:
   - `latitude` and `longitude` update every 7 seconds
   - `last_location_update` timestamp updates
   - `is_online` is `true` when app is active

## Still Having Issues?

1. **Check AndroidManifest.xml**:
   - Should have `ACCESS_FINE_LOCATION` permission
   - Should have `ACCESS_COARSE_LOCATION` permission

2. **Check Device Settings**:
   - Location services enabled
   - App has location permission
   - GPS signal available (go outside)

3. **Check Console Logs**:
   - Look for error messages
   - Check permission status
   - Verify Supabase connection

4. **Test with Different Device**:
   - Some devices have GPS issues
   - Try on a different phone/emulator

## Quick Fix Checklist

- [ ] Location services enabled on device
- [ ] App has location permission
- [ ] Internet connection working
- [ ] Supabase credentials configured
- [ ] Users table exists in Supabase
- [ ] User logged in successfully
- [ ] Console shows "Location update timer started"
- [ ] Console shows "✅ User location updated" messages
