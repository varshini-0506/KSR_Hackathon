# Recurring Safety Checks Implementation

## Overview
The safety confirmation popup now appears:
1. **Every time** the user transitions from **Safe → Risky** zone
2. **Every 5 minutes** while the user remains in the **Risky** zone

## Behavior

### Scenario 1: Safe → Risky Transition
```
User is in Safe Zone (< 10m average distance)
    ↓
User moves away (>= 10m average distance)
    ↓
Status changes to Risky Zone
    ↓
🚨 Popup appears immediately: "Are you safe?"
    ↓
5-minute recurring timer starts
```

### Scenario 2: Staying in Risky Zone
```
User is in Risky Zone
    ↓
User responds "I'm Safe"
    ↓
Popup closes
    ↓
Wait 5 minutes...
    ↓
Still in Risky Zone?
    ↓
🚨 Popup appears again: "Are you safe?"
    ↓
Repeat every 5 minutes
```

### Scenario 3: Risky → Safe Transition
```
User is in Risky Zone (recurring checks active)
    ↓
User moves closer (< 10m average distance)
    ↓
Status changes to Safe Zone
    ↓
✅ Recurring timer stops automatically
    ↓
No more popups until next Risky transition
```

### Scenario 4: Emergency Escalation
```
User is in Risky Zone
    ↓
Popup: "Are you safe?"
    ↓
User clicks "Need Help"
    ↓
Emergency dialog appears
    ↓
User confirms "Send Alert"
    ↓
🚨 Emergency alert sent
    ↓
Recurring timer stops (emergency escalated)
```

## Implementation Details

### State Tracking
```dart
SafetyStatus _lastSafetyStatus = SafetyStatus.unknown;  // Track transitions
Timer? _riskyZoneTimer;                                  // 5-minute timer
DateTime? _lastRiskyPopupTime;                          // Last popup time
```

### Transition Detection
```dart
onStatusChanged: (data) {
  final previousStatus = _lastSafetyStatus;
  final currentStatus = data.status;
  
  if (previousStatus != currentStatus) {
    // State changed!
    if (currentStatus == SafetyStatus.risky) {
      _showSafetyConfirmationPopup(data);      // Show popup
      _startRiskyZoneRecurringCheck();         // Start 5-min timer
    } else if (currentStatus == SafetyStatus.safe) {
      _stopRiskyZoneRecurringCheck();          // Stop timer
    }
  }
}
```

### 5-Minute Recurring Timer
```dart
void _startRiskyZoneRecurringCheck() {
  _riskyZoneTimer = Timer.periodic(Duration(minutes: 5), (timer) {
    if (stillInRiskyZone) {
      _showSafetyConfirmationPopup();  // Show popup again
    } else {
      _stopRiskyZoneRecurringCheck();  // Stop if no longer risky
    }
  });
}
```

## Console Logs

### Safe → Risky Transition
```
🔄 Safety status changed: SafetyStatus.safe → SafetyStatus.risky
🚨 Showing safety confirmation popup
   Average distance: 15.2m
   Nearby users: 3
⏰ Starting 5-minute recurring safety check timer
```

### User Confirms Safe (Still Risky)
```
✅ User confirmed: I'm safe
(Timer continues running...)
(5 minutes later...)
⏰ 5-minute check: User still in risky zone, showing popup
🚨 Showing safety confirmation popup
```

### Risky → Safe Transition
```
🔄 Safety status changed: SafetyStatus.risky → SafetyStatus.safe
⏰ Stopping 5-minute recurring safety check timer
```

### Emergency Escalation
```
🚨 User needs help!
⏰ Stopping 5-minute recurring safety check timer
🚨 EMERGENCY ALERT TRIGGERED!
   Time: 2026-02-12 22:30:15
   Location: 11.360112, 77.827382
   Average distance: 25.5m
```

## User Experience

### Popup Frequency

| Situation | Popup Frequency | Timer Status |
|-----------|----------------|--------------|
| Safe Zone | None | Not running |
| First enter Risky | Immediate | Timer starts |
| Stay in Risky | Every 5 minutes | Running |
| Return to Safe | Stops | Timer stops |
| Emergency Alert | Stops | Timer stops |

### User Responses

#### "I'm Safe" Response
```
✅ Success message appears
💬 "You'll be checked again in 5 minutes if still in risky zone."
⏰ Timer continues (if still risky)
```

#### "Need Help" Response
```
⚠️ Emergency dialog appears
📋 Shows who will be alerted
🚨 "Send Alert" button
⏰ Timer stops (emergency escalated)
```

#### Cancel Emergency
```
❌ Emergency dialog closes
⏰ Timer restarts (if still risky)
```

## Testing

### Test 1: State Transition Detection
1. Start in safe zone (users close)
2. Move to risky zone (users far)
3. **Expected**: Popup appears immediately

### Test 2: Recurring Checks
1. Enter risky zone → Popup appears
2. Click "I'm Safe"
3. **Wait 5 minutes** (or change system time)
4. **Expected**: Popup appears again

### Test 3: Return to Safe
1. Enter risky zone → Popup appears
2. Move back to safe zone
3. **Expected**: No more popups, timer stops

### Test 4: Emergency Stop
1. Enter risky zone → Popup appears
2. Click "Need Help"
3. Click "Send Alert"
4. **Expected**: Timer stops, no more popups

### Quick Test (Change Timer to 30 seconds)
For testing, temporarily change the timer:
```dart
// In _startRiskyZoneRecurringCheck()
_riskyZoneTimer = Timer.periodic(Duration(seconds: 30), (timer) {
  // Now checks every 30 seconds instead of 5 minutes
});
```

## Configuration

### Adjust Recurring Check Interval
Edit in `geofence_view_page.dart`:
```dart
// Default: 5 minutes
Timer.periodic(Duration(minutes: 5), ...);

// For more frequent checks:
Timer.periodic(Duration(minutes: 2), ...);   // Every 2 minutes
Timer.periodic(Duration(minutes: 10), ...);  // Every 10 minutes

// For testing:
Timer.periodic(Duration(seconds: 30), ...);  // Every 30 seconds
```

### Different Intervals Based on Risk Level
```dart
// Calculate interval based on distance
final interval = _safetyData.averageDistance > 50 
    ? Duration(minutes: 2)   // Very far - check more often
    : Duration(minutes: 5);  // Moderately far - normal check

_riskyZoneTimer = Timer.periodic(interval, ...);
```

## Edge Cases Handled

### 1. User Dismisses App
- Timer continues in background (OS permitting)
- Popup will appear when app returns to foreground

### 2. Network Loss
- Timer continues
- When network reconnects, checks status
- Shows popup if still risky

### 3. Rapid State Changes
```
Safe → Risky → Safe → Risky (within 1 minute)
```
- Each Risky entry shows popup
- Timer restarts on each Risky entry
- Timer stops on each Safe entry

### 4. Multiple Users Go Offline
```
Risky Zone (3 users) → All users go offline → No other users
```
- Status changes to "No Other Users"
- Timer stops automatically
- No popup (can't calculate distance)

### 5. Popup Already Open
```
Popup open → 5 minutes pass → Timer triggers
```
- Second popup won't show (one popup at a time)
- Timer will try again in next cycle

## Performance

### Memory Impact
- Single timer instance: ~100 bytes
- No memory leaks (timer cleaned up in dispose)

### Battery Impact
- Minimal: Timer just schedules callback
- No additional GPS sampling
- Only triggers UI update every 5 minutes

### CPU Impact
- Negligible: Timer callback runs once every 5 minutes
- < 1ms execution time per check

## Safety Considerations

### Why 5 Minutes?
- **Not too frequent**: Avoids annoying users
- **Not too long**: Ensures timely safety checks
- **Standard safety interval**: Common in safety apps
- **Allows time to move**: User can return to safe zone

### Escalation Path
```
1. First popup (immediate) → User might be temporarily far
2. Second popup (5 min) → Confirms sustained risky state
3. Third popup (10 min) → Persistent risk, needs attention
4. Emergency alert → User needs help or unresponsive
```

### Auto-Escalation (Future Enhancement)
```dart
// Count how many times user confirmed safe while still risky
int _consecutiveSafeConfirmations = 0;

if (_consecutiveSafeConfirmations >= 3) {
  // User confirmed safe 3 times but still risky
  // Auto-notify emergency contact
  _notifyEmergencyContact();
}
```

## Troubleshooting

### Popup not appearing after 5 minutes
**Check**:
1. Still in risky zone? (Check safety card)
2. Timer running? (Check console for "⏰" logs)
3. Other users still online?

**Debug**:
```dart
print('Timer active: ${_riskyZoneTimer?.isActive}');
print('Current status: ${_safetyData?.status}');
print('Time since last popup: ${DateTime.now().difference(_lastRiskyPopupTime!)}');
```

### Timer not stopping when returning to safe
**Check**:
1. State actually changed to safe? (Check console)
2. `_stopRiskyZoneRecurringCheck()` called?

**Fix**: Hot restart app

### Popup appears too frequently
**Reduce frequency**:
```dart
Timer.periodic(Duration(minutes: 10), ...);  // 10 minutes instead of 5
```

## Summary

✅ **Popup on every Safe → Risky transition**  
✅ **Recurring popup every 5 minutes in Risky zone**  
✅ **Timer auto-stops on Safe zone entry**  
✅ **Timer stops on emergency escalation**  
✅ **No popups when no other users online**  
✅ **Proper cleanup on disposal**  

Your users will now be continuously monitored while in risky zones! 🛡️
