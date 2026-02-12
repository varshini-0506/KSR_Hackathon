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

  Timer? _monitoringTimer;
  SafetyStatus _currentStatus = SafetyStatus.unknown;
  SafetyZoneData? _lastSafetyData;
  
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
  }

  /// Calculate safety zone status based on average distance to all users
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
    
    for (var user in otherUsers) {
      final distance = Geolocator.distanceBetween(
        currentUser.latitude!,
        currentUser.longitude!,
        user.latitude!,
        user.longitude!,
      );
      
      distances.add(distance);
      nearbyUsers.add(user);
      
      print('  - Distance to ${user.name}: ${distance.toStringAsFixed(2)}m');
    }

    // Calculate average distance
    final averageDistance = distances.reduce((a, b) => a + b) / distances.length;
    
    print('📏 Average distance to all users: ${averageDistance.toStringAsFixed(2)}m (threshold: ${threshold}m)');

    // Determine safety status
    final status = averageDistance < threshold ? SafetyStatus.safe : SafetyStatus.risky;
    
    final data = SafetyZoneData(
      status: status,
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
