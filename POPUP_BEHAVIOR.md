# Safety Popup Behavior - Quick Reference

## Visual Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    SAFE ZONE                            │
│              (< 10m average distance)                   │
│                                                         │
│  ✅ No popup shown                                      │
│  ⏰ No timer running                                    │
└─────────────────────────────────────────────────────────┘
                         │
                         │ User moves away
                         │ (distance >= 10m)
                         ↓
┌─────────────────────────────────────────────────────────┐
│              🚨 STATE CHANGE DETECTED 🚨                │
│           Safe → Risky Transition                       │
└─────────────────────────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────┐
│             ⚠️ RISKY ZONE (First Entry)                 │
│                                                         │
│  🚨 Popup appears IMMEDIATELY                           │
│  ⏰ 5-minute timer STARTS                               │
│                                                         │
│  ┌─────────────────────────────────────┐               │
│  │  Are you safe?                      │               │
│  │  [Need Help]  [I'm Safe ✅]         │               │
│  └─────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────┘
                         │
                         │ User clicks "I'm Safe"
                         ↓
┌─────────────────────────────────────────────────────────┐
│              Still in RISKY ZONE                        │
│                                                         │
│  ⏰ Timer continues running...                          │
│  ⏱️ Wait 5 minutes...                                   │
└─────────────────────────────────────────────────────────┘
                         │
                         │ 5 minutes pass
                         ↓
┌─────────────────────────────────────────────────────────┐
│         🚨 5-MINUTE CHECK TRIGGERED 🚨                  │
│                                                         │
│  Still in risky zone?                                  │
│  └─ YES → Show popup again                             │
│  └─ NO  → Stop timer                                   │
└─────────────────────────────────────────────────────────┘
                         │
                         │ Still risky
                         ↓
┌─────────────────────────────────────────────────────────┐
│             ⚠️ RISKY ZONE (5 min later)                 │
│                                                         │
│  🚨 Popup appears AGAIN                                 │
│  ⏰ Timer continues                                     │
│                                                         │
│  ┌─────────────────────────────────────┐               │
│  │  Are you safe?                      │               │
│  │  [Need Help]  [I'm Safe ✅]         │               │
│  └─────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────┘
                         │
                         │ Repeats every 5 minutes
                         │ while in risky zone
                         ↓
                   [Continues...]


═══════════════════════════════════════════════════════════
                   ALTERNATIVE PATHS
═══════════════════════════════════════════════════════════

PATH A: User Returns to Safe Zone
────────────────────────────────────
Risky Zone (timer running)
        │
        │ User moves closer
        │ (distance < 10m)
        ↓
┌──────────────────────────────┐
│   🚨 STATE CHANGE DETECTED   │
│    Risky → Safe Transition   │
└──────────────────────────────┘
        │
        ↓
┌──────────────────────────────┐
│      ✅ SAFE ZONE            │
│                              │
│  ⏰ Timer STOPS              │
│  🚨 No more popups           │
└──────────────────────────────┘


PATH B: User Needs Help
────────────────────────
Risky Zone Popup
        │
        │ User clicks "Need Help"
        ↓
┌──────────────────────────────┐
│   🚨 EMERGENCY DIALOG        │
│                              │
│  Who will be alerted:        │
│  • Nearby users              │
│  • Emergency contacts        │
│                              │
│  [Cancel] [Send Alert 🚨]   │
└──────────────────────────────┘
        │
        │ User clicks "Send Alert"
        ↓
┌──────────────────────────────┐
│  🚨 EMERGENCY TRIGGERED      │
│                              │
│  ⏰ Timer STOPS              │
│  📞 Alerts sent              │
│  🚨 Emergency escalated      │
└──────────────────────────────┘
```

## Timing Examples

### Example 1: Quick Return to Safety
```
10:00 AM - Enter risky zone → Popup shows
10:00 AM - Click "I'm Safe"
10:02 AM - Return to safe zone → Timer stops
          → No more popups ✅
```

### Example 2: Extended Risky Period
```
10:00 AM - Enter risky zone → Popup #1 shows
10:00 AM - Click "I'm Safe"
10:05 AM - Still risky → Popup #2 shows (5 min)
10:05 AM - Click "I'm Safe"
10:10 AM - Still risky → Popup #3 shows (5 min)
10:10 AM - Click "Need Help" → Emergency!
```

### Example 3: Multiple Transitions
```
10:00 AM - Enter risky zone → Popup shows
10:01 AM - Return to safe zone → Timer stops
10:05 AM - Enter risky zone AGAIN → Popup shows (new transition)
10:05 AM - Click "I'm Safe"
10:10 AM - Still risky → Popup shows (5 min)
```

## State Transition Matrix

| Current State | New State | Popup Action | Timer Action |
|--------------|-----------|--------------|--------------|
| Safe | Safe | None | N/A |
| Safe | **Risky** | **Show Immediately** | **Start 5-min** |
| Risky | Risky | None (wait for timer) | Continue |
| Risky | **Safe** | None | **Stop** |
| Unknown | Risky | Show Immediately | Start 5-min |
| Risky | Unknown | None | Stop |

## Console Log Timeline

```
10:00:00 - 🔄 Safety status changed: SafetyStatus.safe → SafetyStatus.risky
10:00:00 - 🚨 Showing safety confirmation popup
10:00:00 - ⏰ Starting 5-minute recurring safety check timer
10:00:15 - ✅ User confirmed: I'm safe
10:05:00 - ⏰ 5-minute check: User still in risky zone, showing popup
10:05:00 - 🚨 Showing safety confirmation popup
10:05:12 - ✅ User confirmed: I'm safe
10:10:00 - ⏰ 5-minute check: User still in risky zone, showing popup
10:10:00 - 🚨 Showing safety confirmation popup
10:10:08 - 🚨 User needs help!
10:10:08 - ⏰ Stopping 5-minute recurring safety check timer
10:10:11 - 🚨 EMERGENCY ALERT TRIGGERED!
```

## Key Features

### ✅ What Happens
1. **First risky entry**: Popup immediately
2. **Every 5 minutes**: Popup if still risky
3. **Return to safe**: Timer stops, no more popups
4. **Emergency**: Timer stops, alert sent
5. **Multiple transitions**: Each transition shows popup

### ❌ What Doesn't Happen
1. No popup spam (max once per 5 minutes while risky)
2. No popup when safe
3. No popup with no other users online
4. No timer when in safe zone
5. No popup after emergency escalation

## Quick Test Instructions

### Test in 30 Seconds (Modified Timer)
1. Edit `geofence_view_page.dart`:
   ```dart
   Timer.periodic(Duration(seconds: 30), ...); // Instead of 5 minutes
   ```
2. Hot restart app
3. Enter risky zone → Popup shows
4. Click "I'm Safe"
5. **Wait 30 seconds** → Popup shows again ✅
6. Return to safe zone → Popup stops ✅

### Test with Real 5-Minute Timer
1. Enter risky zone
2. Click "I'm Safe"
3. Set a timer for 5 minutes
4. Wait...
5. Popup should appear at exactly 5 minutes

### Test State Transitions
1. Move in and out of risky zone
2. Each entry should show popup
3. Check console for state change logs

## Summary

| Trigger | When | Action |
|---------|------|--------|
| **Safe → Risky** | Immediate | Show popup + Start timer |
| **Still Risky** | Every 5 min | Show popup + Continue timer |
| **Risky → Safe** | Immediate | Stop timer |
| **Emergency** | User action | Stop timer + Send alerts |

**Result**: Continuous monitoring with smart, non-intrusive checks! 🛡️
