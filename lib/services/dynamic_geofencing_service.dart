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

  // SIMPLE: 10 meter radius threshold
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

  /// SIMPLE LOGIC: Check if anyone is within 10m radius
  /// If YES → SAFE, If NO → RISKY
  SafetyZoneData checkSafetyStatus({
    required UserModel currentUser,
    required List<UserModel> allUsers,
    double threshold = DEFAULT_THRESHOLD,
  }) {
    print('🔍 Safety check for ${currentUser.name}');

    // Filter: Get all OTHER online users with valid location
    final otherUsers = allUsers.where((user) => 
      user.id != currentUser.id && 
      user.isOnline &&
      user.latitude != null && 
      user.longitude != null
    ).toList();

    print('📊 ${otherUsers.length} other online users');

    // No other users → RISKY (alone)
    if (otherUsers.isEmpty) {
      print('⚠️ No other users online → RISKY');
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

    // Current user has no location → Unknown
    if (currentUser.latitude == null || currentUser.longitude == null) {
      print('⚠️ No current user location → UNKNOWN');
      return SafetyZoneData(
        status: SafetyStatus.unknown,
        averageDistance: 0,
        nearbyUsersCount: 0,
        threshold: threshold,
        nearbyUsers: [],
      );
    }

    // Calculate distances to ALL other users
    double minDistance = double.infinity;
    final distances = <double>[];
    final usersWithinRadius = <UserModel>[];
    
    for (var user in otherUsers) {
      final distance = Geolocator.distanceBetween(
        currentUser.latitude!,
        currentUser.longitude!,
        user.latitude!,
        user.longitude!,
      );
      
      distances.add(distance);
      
      // Track closest user
      if (distance < minDistance) {
        minDistance = distance;
      }
      
      // Track users within radius
      if (distance <= threshold) {
        usersWithinRadius.add(user);
      }
      
      print('  ${user.name}: ${distance.toStringAsFixed(1)}m');
    }

    // SIMPLE LOGIC: Anyone within 10m? → SAFE, Nobody? → RISKY
    final status = usersWithinRadius.isNotEmpty ? SafetyStatus.safe : SafetyStatus.risky;
    
    final avgDistance = distances.isNotEmpty 
        ? distances.reduce((a, b) => a + b) / distances.length 
        : double.infinity;
    
    if (status == SafetyStatus.safe) {
      print('✅ SAFE - ${usersWithinRadius.length} user(s) within ${threshold}m');
    } else {
      print('⚠️ RISKY - No users within ${threshold}m (closest: ${minDistance.toStringAsFixed(1)}m)');
    }
    
    final data = SafetyZoneData(
      status: status,
      averageDistance: avgDistance,
      nearbyUsersCount: usersWithinRadius.length,
      threshold: threshold,
      nearbyUsers: usersWithinRadius,
    );

    _updateStatus(data);
    return data;
  }

  /// Update status and trigger callbacks
  void _updateStatus(SafetyZoneData data) {
    final previousStatus = _currentStatus;
    final newStatus = data.status;
    
    _currentStatus = newStatus;
    _lastSafetyData = data;

    // Always notify (UI needs to update even if status same)
    onSafetyStatusChanged?.call(data);

    // Trigger alerts ONLY when status changes
    if (previousStatus != newStatus) {
      print('🔄 Status changed: $previousStatus → $newStatus');
      
      if (newStatus == SafetyStatus.risky) {
        print('🚨 RISKY ZONE - Triggering alert');
        onRiskyZoneEntered?.call(data);
      } else if (newStatus == SafetyStatus.safe) {
        print('✅ SAFE ZONE');
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
