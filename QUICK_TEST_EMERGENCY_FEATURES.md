# Quick Test: Emergency Features

## What to Test

1. ✅ **10-second countdown timer** appears in popup
2. ✅ **Emergency call** to +919361353368 when clicking "Need Help"
3. ✅ **Auto-alert** when no response after 10 seconds

## Test Setup

### Step 1: Install Dependencies & Restart
```bash
# Dependencies already installed! Just hot restart:
Press 'R' in terminal where flutter run is active
```

### Step 2: Set Other Users Online (To Test Distance)
In **Supabase SQL Editor**, run:
```sql
UPDATE users 
SET 
    latitude = 11.360100,  -- Near User1
    longitude = 77.827400,
    is_online = true
WHERE name = 'User2';
```

## Test Scenarios

### 🧪 Test 1: Countdown Timer (30 seconds)

1. Navigate to **Geofence View** page
2. You should see risky zone (if User2 is now close, move them far first)
3. **Popup appears** with countdown badge in top-right
4. Watch the timer: **10s → 9s → 8s → ...**
5. Timer turns **red** at 3 seconds
6. Click "I'm Safe" before it reaches 0
7. **Expected**: Popup closes, timer stops

### 🧪 Test 2: Emergency Call (1 minute)

1. Trigger risky zone popup
2. Click **"Need Help"** button
3. **Expected**:
   - Phone dialer opens with **+919361353368**
   - Green message: "Calling emergency contact: Calling Help"
   - Emergency dialog appears

4. You can:
   - Actually make the call (will dial +919361353368)
   - Or cancel and return to app

### 🧪 Test 3: Auto-Alert on No Response (15 seconds)

1. Trigger risky zone popup
2. **Don't click anything**
3. Watch countdown: 10 → 9 → 8 → ... → 1 → 0
4. **Expected at 0 seconds**:
   - Popup auto-closes
   - Red notification appears at bottom
   - Message: "No response detected! Alert sent to nearby users."
   - "I'm Safe" button available in notification

5. Click "I'm Safe" on notification
6. **Expected**: "Alert cancelled" confirmation

### 🧪 Test 4: Multiple State Changes

1. Enter risky zone → Popup #1
2. Click "I'm Safe"
3. Move to safe zone (< 10m)
4. Move to risky zone again → Popup #2 ✅
5. Verify popup appears again on second risky entry

## Console Logs to Watch

### Successful Emergency Call
```
🚨 User needs help!
📞 Initiating emergency call to +919361353368
   Contact name: Calling Help
✅ Emergency call initiated successfully
```

### Auto-Alert Triggered
```
⏱️ Countdown: 3 seconds remaining
⏱️ Countdown: 2 seconds remaining
⏱️ Countdown: 1 seconds remaining
⏱️ Countdown: 0 seconds remaining
⏰ NO RESPONSE after 10 seconds - Auto-alerting other users
🚨 AUTO-ALERT: User did not respond in time!
   User: User1
   Location: 11.360053, 77.827360
   Average distance: 15.2m
   Notifying 3 nearby users...
✅ Auto-alert logged successfully
```

## Expected Behavior Summary

| Action | Result | Time |
|--------|--------|------|
| Enter risky zone | Popup appears with 10s timer | Immediate |
| Click "I'm Safe" | Popup closes, timer stops | Immediate |
| Click "Need Help" | Phone dialer opens, call +919361353368 | < 1s |
| No response (10s) | Auto-alert sent to others | After 10s |
| Click "I'm Safe" on alert | Alert cancelled | Immediate |

## Visual Elements

### Countdown Badge
```
🕐 10s  ← Orange badge (countdown > 3)
🕐 3s   ← Red badge (countdown <= 3, urgent!)
🕐 0s   ← Auto-triggers
```

### Complete Popup View
```
┌─────────────────────────────────────────┐
│ ⚠️  Safety Check              🕐 7s     │
├─────────────────────────────────────────┤
│ ⚠️ You are in a risky zone              │
│ Average distance: 15.2m                 │
│ Safety threshold: 10m                   │
│ Nearby users: 3                         │
│                                         │
│ Are you safe?                           │
│ Please confirm your safety status.      │
│ If no response, alert will be sent.     │
├─────────────────────────────────────────┤
│ [Need Help 🚨]  [I'm Safe ✅]           │
└─────────────────────────────────────────┘
```

## Troubleshooting

### Countdown not visible
- Ensure hot restart (not just hot reload)
- Check console for "⏱️ Countdown" messages

### Phone dialer doesn't open
- **Check**: CALL_PHONE permission granted
- **Android**: Settings → Apps → Vigil → Permissions → Phone
- **iOS**: Automatically handles tel: URLs

### Auto-alert not working
- **Must wait full 10 seconds** without clicking
- Check console for "NO RESPONSE" message
- Verify red notification appears

### Want to test faster
Change countdown to 5 seconds for testing:
```dart
int secondsRemaining = 5;  // Instead of 10
```

## Production Checklist

Before deploying:
- [ ] Test emergency call works on real device
- [ ] Verify correct phone number configured
- [ ] Test auto-alert notification delivery
- [ ] Configure push notifications (FCM)
- [ ] Create safety_alerts table in Supabase
- [ ] Set up emergency contact management
- [ ] Test on both Android and iOS
- [ ] Add logging for all emergency events
- [ ] Configure escalation policies

## Quick Fix if Issues

### Re-install dependencies
```bash
flutter clean
flutter pub get
flutter run
```

### Check permissions in code
```dart
// Check if permission granted
PermissionStatus status = await Permission.phone.status;
print('Phone permission: $status');
```

### Verify URL launcher works
```dart
// Test call functionality
final Uri testUri = Uri.parse('tel:+919361353368');
print('Can launch: ${await canLaunchUrl(testUri)}');
```

## Success Criteria

✅ Popup shows countdown timer (orange/red badge)  
✅ Timer counts down from 10 to 0  
✅ Clicking "Need Help" opens phone dialer  
✅ Phone number +919361353368 appears in dialer  
✅ No response after 10s triggers auto-alert  
✅ Red notification appears with "I'm Safe" option  
✅ All console logs appear as expected  

**All emergency features are now ready to test!** 🚨
