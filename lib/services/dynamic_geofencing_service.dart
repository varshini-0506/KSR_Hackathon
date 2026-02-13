import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';

enum SafetyStatus {
  safe,
  risky,
  unknown,
}

class SafetyZoneData {
  final SafetyStatus status;
  final double averageDistance;
  final int nearbyUsersCount;
  final double threshold;
  final List<UserModel> nearbyUsers;

  SafetyZoneData({
    required this.status,
    required this.averageDistance,
    required this.nearbyUsersCount,
    required this.threshold,
    required this.nearbyUsers,
  });
}

class DynamicGeofencingService {
  static final DynamicGeofencingService _instance = DynamicGeofencingService._internal();
  factory DynamicGeofencingService() => _instance;
  DynamicGeofencingService._internal();

  // Safety threshold in meters
  static const double DEFAULT_THRESHOLD = 10.0;
  
  // GPS accuracy buffer - GPS can have ±5-10m error even when stationary
  // Add buffer to prevent false alerts from GPS jitter
  static const double GPS_ACCURACY_BUFFER = 5.0;
  
  // Hysteresis: Different thresholds for entering/leaving risky zone
  // This prevents rapid flapping between safe/risky states
  static const double ENTER_RISKY_THRESHOLD = 15.0; // Must be 15m+ to enter risky
  static const double EXIT_RISKY_THRESHOLD = 8.0;   // Must be 8m- to exit risky

  Timer? _monitoringTimer;
  SafetyStatus _currentStatus = SafetyStatus.unknown;
  SafetyZoneData? _lastSafetyData;
  
  // Debouncing: Require sustained risky state before alerting
  int _consecutiveRiskyChecks = 0;
  static const int RISKY_CHECKS_REQUIRED = 3; // Must be risky for 3 checks (3 seconds)
  
  // Callbacks
  Function(SafetyZoneData)? onSafetyStatusChanged;
  Function(SafetyZoneData)? onRiskyZoneEntered;
  Function(SafetyZoneData)? onSafeZoneEntered;

  /// Start monitoring safety zone status
  void startMonitoring({
    double threshold = DEFAULT_THRESHOLD,
    Function(SafetyZoneData)? onStatusChanged,
    Function(SafetyZoneData)? onRiskyZone,
    Function(SafetyZoneData)? onSafeZone,
  }) {
    print('🛡️ Starting dynamic geofencing monitoring (threshold: ${threshold}m)');
    
    onSafetyStatusChanged = onStatusChanged;
    onRiskyZoneEntered = onRiskyZone;
    onSafeZoneEntered = onSafeZone;

    // Monitor every 2 seconds for real-time safety updates
    _monitoringTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      // Monitoring will be triggered externally by calling checkSafetyStatus
    });
  }

  /// Stop monitoring
  void stopMonitoring() {
    print('🛡️ Stopping dynamic geofencing monitoring');
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _currentStatus = SafetyStatus.unknown;
    _lastSafetyData = null;
    _consecutiveRiskyChecks = 0;
  }

  /// Calculate safety zone status based on minimum distance to closest user
  /// NEW LOGIC: User is SAFE if close to AT LEAST ONE user, RISKY only if ALL users are far
  SafetyZoneData checkSafetyStatus({
    required UserModel currentUser,
    required List<UserModel> allUsers,
    double threshold = DEFAULT_THRESHOLD,
  }) {
    print('🔍 Checking safety status for ${currentUser.name}...');

    // Filter out current user and offline users
    final otherUsers = allUsers.where((user) => 
      user.id != currentUser.id && 
      user.isOnline &&
      user.latitude != null && 
      user.longitude != null
    ).toList();

    print('📊 Found ${otherUsers.length} other online users to check');

    if (otherUsers.isEmpty) {
      // No other users nearby - consider risky
      final data = SafetyZoneData(
        status: SafetyStatus.risky,
        averageDistance: double.infinity,
        nearbyUsersCount: 0,
        threshold: threshold,
        nearbyUsers: [],
      );
      
      _updateStatus(data);
      return data;
    }

    if (currentUser.latitude == null || currentUser.longitude == null) {
      // Current user location unknown
      final data = SafetyZoneData(
        status: SafetyStatus.unknown,
        averageDistance: 0,
        nearbyUsersCount: 0,
        threshold: threshold,
        nearbyUsers: [],
      );
      
      return data;
    }

    // Calculate distances to all other users
    final distances = <double>[];
    final nearbyUsers = <UserModel>[];
    double minDistance = double.infinity;
    
    for (var user in otherUsers) {
      final distance = Geolocator.distanceBetween(
        currentUser.latitude!,
        currentUser.longitude!,
        user.latitude!,
        user.longitude!,
      );
      
      distances.add(distance);
      nearbyUsers.add(user);
      
      // Track minimum distance (closest user)
      if (distance < minDistance) {
        minDistance = distance;
      }
      
      print('  - Distance to ${user.name}: ${distance.toStringAsFixed(2)}m');
    }

    // Calculate average distance (for display purposes)
    final averageDistance = distances.reduce((a, b) => a + b) / distances.length;
    
    print('📏 Minimum distance (closest user): ${minDistance.toStringAsFixed(2)}m');
    print('📏 Average distance to all users: ${averageDistance.toStringAsFixed(2)}m');
    print('🎯 Base threshold: ${threshold}m');

    // IMPROVED LOGIC with Hysteresis and GPS Accuracy Buffer
    // Prevents false alerts from GPS jitter and state flapping
    
    SafetyStatus newStatus;
    
    if (_currentStatus == SafetyStatus.safe || _currentStatus == SafetyStatus.unknown) {
      // Currently safe: Need to exceed ENTER_RISKY threshold to become risky
      // This prevents false alerts when GPS jitters around 10m mark
      if (minDistance >= ENTER_RISKY_THRESHOLD) {
        newStatus = SafetyStatus.risky;
        print('⚠️ POTENTIALLY RISKY: Distance ${minDistance.toStringAsFixed(2)}m >= ${ENTER_RISKY_THRESHOLD}m');
      } else {
        newStatus = SafetyStatus.safe;
        print('✅ SAFE: Distance ${minDistance.toStringAsFixed(2)}m < ${ENTER_RISKY_THRESHOLD}m (with buffer)');
      }
    } else {
      // Currently risky: Need to go below EXIT_RISKY threshold to become safe
      // This prevents rapid flapping when user is at boundary
      if (minDistance <= EXIT_RISKY_THRESHOLD) {
        newStatus = SafetyStatus.safe;
        print('✅ RETURNING TO SAFE: Distance ${minDistance.toStringAsFixed(2)}m <= ${EXIT_RISKY_THRESHOLD}m');
      } else {
        newStatus = SafetyStatus.risky;
        print('⚠️ STILL RISKY: Distance ${minDistance.toStringAsFixed(2)}m > ${EXIT_RISKY_THRESHOLD}m');
      }
    }
    
    // Debouncing: Require sustained risky state before confirming
    if (newStatus == SafetyStatus.risky) {
      _consecutiveRiskyChecks++;
      print('🔄 Risky check ${_consecutiveRiskyChecks}/$RISKY_CHECKS_REQUIRED');
      
      // If not enough consecutive checks, keep current status but increment counter
      if (_consecutiveRiskyChecks < RISKY_CHECKS_REQUIRED && _currentStatus == SafetyStatus.safe) {
        print('⏳ Waiting for ${RISKY_CHECKS_REQUIRED - _consecutiveRiskyChecks} more checks before alerting');
        newStatus = SafetyStatus.safe; // Keep safe until confirmed
      }
    } else {
      // Reset counter when safe
      if (_consecutiveRiskyChecks > 0) {
        print('🔄 Reset risky counter (was at ${_consecutiveRiskyChecks})');
      }
      _consecutiveRiskyChecks = 0;
    }
    
    final data = SafetyZoneData(
      status: newStatus,
      averageDistance: averageDistance,
      nearbyUsersCount: otherUsers.length,
      threshold: threshold,
      nearbyUsers: nearbyUsers,
    );

    _updateStatus(data);
    return data;
  }

  /// Update status and trigger callbacks
  void _updateStatus(SafetyZoneData data) {
    final previousStatus = _currentStatus;
    _currentStatus = data.status;
    _lastSafetyData = data;

    // Always notify status changed
    onSafetyStatusChanged?.call(data);

    // Notify specific zone changes
    if (previousStatus != _currentStatus) {
      if (_currentStatus == SafetyStatus.risky) {
        print('⚠️ ENTERED RISKY ZONE! Average distance: ${data.averageDistance.toStringAsFixed(2)}m');
        onRiskyZoneEntered?.call(data);
      } else if (_currentStatus == SafetyStatus.safe) {
        print('✅ ENTERED SAFE ZONE! Average distance: ${data.averageDistance.toStringAsFixed(2)}m');
        onSafeZoneEntered?.call(data);
      }
    }
  }

  /// Get current safety status
  SafetyStatus get currentStatus => _currentStatus;

  /// Get last safety zone data
  SafetyZoneData? get lastSafetyData => _lastSafetyData;

  /// Calculate distance to nearest user
  double? getNearestUserDistance({
    required UserModel currentUser,
    required List<UserModel> allUsers,
  }) {
    if (currentUser.latitude == null || currentUser.longitude == null) {
      return null;
    }

    final otherUsers = allUsers.where((user) => 
      user.id != currentUser.id && 
      user.isOnline &&
      user.latitude != null && 
      user.longitude != null
    ).toList();

    if (otherUsers.isEmpty) return null;

    double? minDistance;
    
    for (var user in otherUsers) {
      final distance = Geolocator.distanceBetween(
        currentUser.latitude!,
        currentUser.longitude!,
        user.latitude!,
        user.longitude!,
      );
      
      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// Get users within a specific radius
  List<UserModel> getUsersWithinRadius({
    required UserModel currentUser,
    required List<UserModel> allUsers,
    required double radiusInMeters,
  }) {
    if (currentUser.latitude == null || currentUser.longitude == null) {
      return [];
    }

    final nearbyUsers = <UserModel>[];
    
    for (var user in allUsers) {
      if (user.id == currentUser.id) continue;
      if (!user.isOnline) continue;
      if (user.latitude == null || user.longitude == null) continue;

      final distance = Geolocator.distanceBetween(
        currentUser.latitude!,
        currentUser.longitude!,
        user.latitude!,
        user.longitude!,
      );
      
      if (distance <= radiusInMeters) {
        nearbyUsers.add(user);
      }
    }

    return nearbyUsers;
  }

  void dispose() {
    stopMonitoring();
  }
}
