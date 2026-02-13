# Group-Based Dynamic Geofencing

## Overview

The system now uses **intelligent group detection** to monitor couples and groups independently. Each group is monitored separately, and alerts only go to members of the same group.

---

## How It Works

### 1. **Automatic Group Detection**

The system automatically detects groups using a **distance-based clustering algorithm**:

```
Algorithm:
1. Start with first user
2. Find all users within GROUP_THRESHOLD (20m)
3. Expand group: Find users within 20m of any group member
4. Repeat until no more users can be added
5. Create group with all found members
6. Repeat for remaining unassigned users
```

**Example Scenario:**
```
8 users total:
- Couple 1: Alice & Bob (5m apart) → Group A
- Couple 2: Charlie & Diana (8m apart) → Group B  
- Couple 3: Eve & Frank (12m apart) → Group C
- Couple 4: Grace & Henry (15m apart) → Group D

All couples are 100m+ away from each other
Result: 4 independent groups detected
```

### 2. **Per-Group Monitoring**

Each group is monitored **independently**:

```
Group A (Alice & Bob):
- Alice monitors distance to Bob only
- Bob monitors distance to Alice only
- If Alice moves 20m away → Only Alice & Bob get alerts

Group B (Charlie & Diana):
- Charlie monitors distance to Diana only
- Diana monitors distance to Charlie only
- If Charlie moves away → Only Charlie & Diana get alerts
- Alice & Bob are NOT alerted (different group)
```

### 3. **Group-Based Alerts**

**Key Feature**: Alerts are **scoped to the group**:

```
Scenario: 8 users, 4 couples
- Couple 1: Alice & Bob (together)
- Couple 2: Charlie & Diana (together)
- Couple 3: Eve & Frank (together)
- Couple 4: Grace & Henry (together)

If Alice moves 25m away from Bob:
✅ Alice gets alert (isolated from her group)
✅ Bob gets alert (his partner moved away)
❌ Charlie, Diana, Eve, Frank, Grace, Henry do NOT get alerts
   (They're in different groups, not affected)
```

---

## Configuration

### Group Detection Threshold

```dart
static const double GROUP_THRESHOLD = 20.0; // meters
```

**What it means:**
- Users within **20 meters** of each other form a group
- This allows couples walking together to be detected as one group
- Groups separated by >20m are monitored independently

**Adjusting the threshold:**
- **Smaller (10m)**: Tighter groups, more separation required
- **Larger (30m)**: Looser groups, allows more spread

### Safety Threshold (within group)

```dart
static const double DEFAULT_THRESHOLD = 10.0; // meters
static const double ENTER_RISKY_THRESHOLD = 15.0; // meters
static const double EXIT_RISKY_THRESHOLD = 8.0; // meters
```

**What it means:**
- Within a group, users are **SAFE** if < 8m from any group member
- Users become **RISKY** if > 15m from all group members
- Hysteresis prevents rapid state flapping

---

## Real-World Examples

### Example 1: 4 Couples at Different Locations

```
Location: Shopping Mall
- Couple 1 (Alice & Bob): Electronics section
- Couple 2 (Charlie & Diana): Food court
- Couple 3 (Eve & Frank): Clothing section
- Couple 4 (Grace & Henry): Parking lot

Groups Detected:
- Group A: Alice, Bob (5m apart)
- Group B: Charlie, Diana (8m apart)
- Group C: Eve, Frank (12m apart)
- Group D: Grace, Henry (15m apart)

Monitoring:
- Each couple monitored independently
- If Alice wanders away from Bob → Only Alice & Bob alerted
- Other couples unaffected
```

### Example 2: Large Group Splits

```
Initial: 8 friends hiking together (all within 20m)
→ Single group: All 8 users

Scenario: Group splits into 2 subgroups
- Subgroup 1: 4 people continue on trail (within 20m)
- Subgroup 2: 4 people take detour (within 20m)
- Distance between subgroups: 50m

Groups Detected:
- Group A: 4 people (subgroup 1)
- Group B: 4 people (subgroup 2)

Monitoring:
- Each subgroup monitored independently
- If someone in Group A wanders → Only Group A alerted
- Group B unaffected
```

### Example 3: Dynamic Group Formation

```
Initial State:
- Alice alone (100m from others)
- Bob & Charlie together (10m apart)
- Diana, Eve, Frank together (all within 15m)

Groups Detected:
- Group A: Alice (alone)
- Group B: Bob, Charlie
- Group C: Diana, Eve, Frank

Alice walks toward Bob & Charlie:
- Distance reduces: 100m → 50m → 30m → 15m
- When Alice reaches 20m from Bob:
  → Groups merge: Group A + Group B = New Group (Alice, Bob, Charlie)
  → Group C remains separate

Monitoring Updates:
- Alice now monitored with Bob & Charlie
- If Alice moves away → All 3 get alerts
- Diana, Eve, Frank still in separate group
```

---

## Algorithm Details

### Clustering Algorithm (detectGroups)

```dart
List<UserGroup> detectGroups(List<UserModel> allUsers) {
  1. Get all online users with valid GPS
  2. For each unassigned user:
     a. Start new group with this user
     b. Find all users within GROUP_THRESHOLD
     c. Expand: Find users within threshold of any group member
     d. Repeat expansion until no more users found
     e. Create group with all found members
  3. Return all detected groups
}
```

**Time Complexity**: O(n²) where n = number of users
- Acceptable for small groups (8-20 users)
- Optimized with early termination

**Space Complexity**: O(n)
- Stores groups and assignments

### Group Finding (findUserGroup)

```dart
UserGroup? findUserGroup(UserModel user, List<UserGroup> groups) {
  For each group:
    If group contains user:
      Return group
  Return null (shouldn't happen)
}
```

**Time Complexity**: O(n × m) where n = groups, m = group size
- Typically O(n) since groups are small

---

## Benefits

### ✅ **Privacy & Relevance**
- Users only see alerts relevant to their group
- No noise from unrelated groups
- Couples can monitor each other privately

### ✅ **Scalability**
- Works with any number of groups
- Each group monitored independently
- No performance degradation with more groups

### ✅ **Dynamic Adaptation**
- Groups form/dissolve automatically
- No manual configuration needed
- Adapts to real-world movement patterns

### ✅ **Accurate Alerts**
- Only alerts when someone leaves THEIR group
- Prevents false alerts from other groups
- Reduces alert fatigue

---

## Testing Scenarios

### Test 1: Two Couples Separated

**Setup:**
```
Couple 1: Alice (12.9716, 77.5946) & Bob (12.9717, 77.5947) - 10m apart
Couple 2: Charlie (12.9750, 77.6000) & Diana (12.9751, 77.6001) - 10m apart
Distance between couples: 500m
```

**Expected:**
- 2 groups detected
- Alice monitors Bob only
- Charlie monitors Diana only
- If Alice moves 30m from Bob → Only Alice & Bob alerted

### Test 2: Group Splitting

**Setup:**
```
Initial: 4 users together (all within 15m)
- Alice, Bob, Charlie, Diana

Action: Alice & Bob walk 30m away
```

**Expected:**
- Initially: 1 group (all 4)
- After split: 2 groups
  - Group A: Alice, Bob
  - Group B: Charlie, Diana
- Each group monitored independently

### Test 3: Single User

**Setup:**
```
Alice alone (100m from nearest user)
```

**Expected:**
- 1 group detected (Alice only)
- Alice status: RISKY (no other group members)
- Alert: "No other users in your group"

---

## Debug Logging

The system provides detailed logs:

```
👥 Detected 4 group(s):
   Group(group_0): Alice, Bob
   Group(group_1): Charlie, Diana
   Group(group_2): Eve, Frank
   Group(group_3): Grace, Henry

🔍 Checking safety status for Alice...
👥 User Alice is in Group(group_0): Alice, Bob
📊 Found 1 other user(s) in same group
  - Distance to Bob (same group): 5.23m
📏 Minimum distance (closest user in group): 5.23m
👥 Group size: 2 members
✅ SAFE: Distance 5.23m < 15.0m (with buffer)
```

---

## Configuration Tuning

### For Tighter Groups (Couples)
```dart
static const double GROUP_THRESHOLD = 15.0; // Tighter coupling
```

### For Looser Groups (Hiking Groups)
```dart
static const double GROUP_THRESHOLD = 30.0; // Allows more spread
```

### For Large Events (Conferences)
```dart
static const double GROUP_THRESHOLD = 50.0; // Very loose grouping
```

---

## Future Enhancements

1. **Persistent Groups**: Remember group memberships across sessions
2. **Manual Grouping**: Allow users to manually form groups
3. **Group Names**: Display friendly group names
4. **Group Chat**: Communication within groups
5. **Group History**: Track group formation/dissolution over time

---

## Summary

The group-based system provides:
- ✅ **Automatic group detection** - No configuration needed
- ✅ **Independent monitoring** - Each group monitored separately
- ✅ **Scoped alerts** - Only relevant group members notified
- ✅ **Dynamic adaptation** - Groups form/dissolve automatically
- ✅ **Privacy** - Groups isolated from each other

Perfect for couples, hiking groups, event attendees, and any scenario where users form natural clusters!

