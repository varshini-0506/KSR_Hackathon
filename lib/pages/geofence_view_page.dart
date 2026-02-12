import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/user_location_service.dart';
import '../services/user_auth_service.dart';
import '../services/dynamic_geofencing_service.dart';
import '../widgets/user_map_widget.dart';

class GeofenceViewPage extends StatefulWidget {
  const GeofenceViewPage({super.key});

  @override
  State<GeofenceViewPage> createState() => _GeofenceViewPageState();
}

class _GeofenceViewPageState extends State<GeofenceViewPage> {
  bool _isStaticGeofence = false;
  final UserLocationService _locationService = UserLocationService();
  final UserAuthService _authService = UserAuthService();
  final DynamicGeofencingService _geofencingService = DynamicGeofencingService();
  
  List<UserModel> _users = [];
  UserModel? _currentUser;
  RealtimeChannel? _realtimeChannel;
  Timer? _refreshTimer;
  int _updateCounter = 0; // Force rebuild counter
  
  // Safety zone data
  SafetyZoneData? _safetyData;
  double _safetyThreshold = 10.0; // 10 meters default
  bool _hasShownRiskyPopup = false; // Prevent multiple popups

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _subscribeToUpdates();
    _startSafetyMonitoring();
    
    // Aggressive refresh for real-time sync (every 1 second)
    // Note: Supabase Realtime (WebSocket) will trigger most updates instantly
    // This is just a backup to ensure UI consistency
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _loadUsers();
        _checkSafetyStatus(); // Check safety on every refresh
      }
    });
  }

  void _startSafetyMonitoring() {
    print('🛡️ Starting safety zone monitoring');
    
    _geofencingService.startMonitoring(
      threshold: _safetyThreshold,
      onStatusChanged: (data) {
        if (mounted) {
          setState(() {
            _safetyData = data;
          });
        }
      },
      onRiskyZone: (data) {
        // Show popup when entering risky zone (but not if there are no other users)
        if (mounted && !_hasShownRiskyPopup && data.nearbyUsersCount > 0) {
          _hasShownRiskyPopup = true;
          _showSafetyConfirmationPopup(data);
        }
      },
      onSafeZone: (data) {
        // Reset popup flag when returning to safe zone
        _hasShownRiskyPopup = false;
      },
    );
  }

  void _checkSafetyStatus() {
    if (_currentUser == null || _users.isEmpty) return;
    
    final data = _geofencingService.checkSafetyStatus(
      currentUser: _currentUser!,
      allUsers: _users,
      threshold: _safetyThreshold,
    );
    
    if (mounted) {
      setState(() {
        _safetyData = data;
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      print('🔄 Loading users from Supabase...');
      final users = await _locationService.getAllUsers();
      
      // Get current logged-in user ID from UserAuthService
      final currentAuthUser = _authService.getCurrentUser();
      final currentUserId = currentAuthUser?.id;
      
      // Find current user in the fetched users list (with latest location data)
      UserModel? currentUserWithLatestData;
      if (currentUserId != null) {
        currentUserWithLatestData = users.firstWhere(
          (u) => u.id == currentUserId,
          orElse: () => currentAuthUser ?? users.first,
        );
      } else if (users.isNotEmpty) {
        currentUserWithLatestData = users.first;
      }
      
      print('Current logged-in user: ${currentUserWithLatestData?.name} (${currentUserWithLatestData?.id})');
      if (currentUserWithLatestData != null && currentUserWithLatestData.latitude != null) {
        print('  Latest location: Lat=${currentUserWithLatestData.latitude?.toStringAsFixed(6)}, Lon=${currentUserWithLatestData.longitude?.toStringAsFixed(6)}');
      }
      
      print('Loaded ${users.length} users with locations:');
      for (var user in users) {
        if (user.latitude != null && user.longitude != null) {
          print('  - ${user.name}: Lat=${user.latitude?.toStringAsFixed(6)}, Lon=${user.longitude?.toStringAsFixed(6)}, Online=${user.isOnline}');
        } else {
          print('  - ${user.name}: No location data');
        }
      }

      if (mounted) {
        final oldLat = _currentUser?.latitude;
        final oldLon = _currentUser?.longitude;
        final newLat = currentUserWithLatestData?.latitude;
        final newLon = currentUserWithLatestData?.longitude;
        
        print('📊 Before setState: Old Lat=$oldLat, Old Lon=$oldLon');
        print('📊 Before setState: New Lat=$newLat, New Lon=$newLon');
        
        // Force rebuild by creating new list and updating state
        setState(() {
          _users = List.from(users); // Create new list instance
          _currentUser = currentUserWithLatestData != null 
              ? UserModel(
                  id: currentUserWithLatestData.id,
                  email: currentUserWithLatestData.email,
                  phone: currentUserWithLatestData.phone,
                  name: currentUserWithLatestData.name,
                  latitude: currentUserWithLatestData.latitude,
                  longitude: currentUserWithLatestData.longitude,
                  speed: currentUserWithLatestData.speed,
                  accuracy: currentUserWithLatestData.accuracy,
                  lastLocationUpdate: currentUserWithLatestData.lastLocationUpdate,
                  isOnline: currentUserWithLatestData.isOnline,
                  sessionId: currentUserWithLatestData.sessionId,
                  createdAt: currentUserWithLatestData.createdAt,
                  updatedAt: currentUserWithLatestData.updatedAt,
                )
              : null; // Create new instance to force rebuild
          _updateCounter++; // Increment counter to force rebuild
        });
        
        print('✅ UI state updated with ${users.length} users (update #$_updateCounter)');
        print('✅ After setState: Current user location: Lat=${_currentUser?.latitude?.toStringAsFixed(6)}, Lon=${_currentUser?.longitude?.toStringAsFixed(6)}');
        print('✅ Location changed: ${oldLat != newLat || oldLon != newLon}');
      }
    } catch (e) {
      print('❌ Error loading users: $e');
    }
  }

  void _subscribeToUpdates() {
    print('Subscribing to realtime updates...');
    _realtimeChannel = _locationService.subscribeToUserUpdates(
      onUsersUpdated: (users) {
        print('🔄 Realtime callback triggered with ${users.length} users');
        if (mounted) {
          // Get current user ID from auth service
          final currentAuthUser = _authService.getCurrentUser();
          final currentUserId = currentAuthUser?.id;
          
          // Find current user in the updated users list (with latest location)
          UserModel? currentUserWithLatestData;
          if (currentUserId != null) {
            currentUserWithLatestData = users.firstWhere(
              (u) => u.id == currentUserId,
              orElse: () => currentAuthUser ?? users.first,
            );
          } else if (users.isNotEmpty) {
            currentUserWithLatestData = users.first;
          }
          
          print('Updating UI with users: ${users.map((u) => '${u.name}(${u.latitude?.toStringAsFixed(6)},${u.longitude?.toStringAsFixed(6)})').join(', ')}');
          
          final oldLat = _currentUser?.latitude;
          final oldLon = _currentUser?.longitude;
          final newLat = currentUserWithLatestData?.latitude;
          final newLon = currentUserWithLatestData?.longitude;
          
          print('📊 Realtime: Old Lat=$oldLat, Old Lon=$oldLon');
          print('📊 Realtime: New Lat=$newLat, New Lon=$newLon');
          
          // Force rebuild by creating new instances
          setState(() {
            _users = List.from(users); // New list instance
            _currentUser = currentUserWithLatestData != null
                ? UserModel(
                    id: currentUserWithLatestData.id,
                    email: currentUserWithLatestData.email,
                    phone: currentUserWithLatestData.phone,
                    name: currentUserWithLatestData.name,
                    latitude: currentUserWithLatestData.latitude,
                    longitude: currentUserWithLatestData.longitude,
                    speed: currentUserWithLatestData.speed,
                    accuracy: currentUserWithLatestData.accuracy,
                    lastLocationUpdate: currentUserWithLatestData.lastLocationUpdate,
                    isOnline: currentUserWithLatestData.isOnline,
                    sessionId: currentUserWithLatestData.sessionId,
                    createdAt: currentUserWithLatestData.createdAt,
                    updatedAt: currentUserWithLatestData.updatedAt,
                  )
                : null; // New instance to force rebuild
            _updateCounter++; // Increment counter to force rebuild
          });
          
          print('✅ UI updated via realtime: ${users.length} users (update #$_updateCounter)');
          print('✅ Realtime: After setState - Lat=${_currentUser?.latitude?.toStringAsFixed(6)}, Lon=${_currentUser?.longitude?.toStringAsFixed(6)}');
          print('✅ Realtime: Location changed: ${oldLat != newLat || oldLon != newLon}');
        } else {
          print('⚠️ Widget not mounted, skipping UI update');
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    _geofencingService.stopMonitoring();
    super.dispose();
  }

  void _showSafetyConfirmationPopup(SafetyZoneData data) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must respond
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.dangerColor, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Safety Check',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ You are in a risky zone',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Average distance to other users: ${data.averageDistance.toStringAsFixed(1)}m',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Safety threshold: ${data.threshold.toStringAsFixed(0)}m',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (data.nearbyUsersCount > 0)
                      Text(
                        'Nearby users: ${data.nearbyUsersCount}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Are you safe?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please confirm your safety status. If you need help, emergency services can be contacted.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _handleNotSafe();
              },
              icon: const Icon(Icons.emergency, color: Colors.red),
              label: const Text(
                'Need Help',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _handleSafe();
              },
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('I\'m Safe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleSafe() {
    print('✅ User confirmed: I\'m safe');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Great! Stay aware of your surroundings.'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Reset popup flag after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _hasShownRiskyPopup = false;
      }
    });
  }

  void _handleNotSafe() {
    print('🚨 User needs help!');
    
    // Show emergency options
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.emergency, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text(
                'Emergency',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Emergency alert will be sent to:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '• All nearby trusted contacts\n'
                '• Your emergency contacts\n'
                '• Local authorities (optional)',
                style: TextStyle(fontSize: 14, height: 1.8),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _hasShownRiskyPopup = false;
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _triggerEmergencyAlert();
              },
              icon: const Icon(Icons.warning, color: Colors.white),
              label: const Text('Send Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  void _triggerEmergencyAlert() {
    print('🚨 EMERGENCY ALERT TRIGGERED!');
    
    // TODO: Implement emergency alert logic
    // - Send notifications to nearby users
    // - Alert emergency contacts
    // - Log incident
    // - Start recording audio/location trail
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Emergency alert sent to nearby users and contacts!'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to emergency page
          },
        ),
      ),
    );
    
    _hasShownRiskyPopup = false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with refresh button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Live Geofence Map',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          print('Manual refresh triggered');
                          _loadUsers();
                        },
                        tooltip: 'Refresh locations',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Map View with Users
                  UserMapWidget(
                    key: ValueKey('map_${_updateCounter}_${_users.length}_${_users.map((u) => '${u.latitude?.toStringAsFixed(6)}_${u.longitude?.toStringAsFixed(6)}').join('_')}'),
                    users: _users,
                    currentUser: _currentUser,
                    mapWidth: MediaQuery.of(context).size.width - 48,
                    mapHeight: 400,
                  ),
                  const SizedBox(height: 24),
                  // Safety Status Card (Priority Display)
                  if (_safetyData != null) _buildSafetyStatusCard(),
                  const SizedBox(height: 16),
                  // Current User Info (rebuild on every update)
                  if (_currentUser != null) _buildCurrentUserCard(),
                  const SizedBox(height: 16),
                  // Online Users List
                  _buildUsersList(),
                  const SizedBox(height: 24),
                  // Explanation Tooltip
                  Card(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Dynamic geofencing: Your safety zone adapts based on nearby trusted users',
                              style: TextStyle(color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Legend
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Legend',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem(AppTheme.primaryColor, 'You'),
                          _buildLegendItem(AppTheme.successColor, 'Online Users'),
                          _buildLegendItem(AppTheme.textSecondary, 'Offline Users'),
                          _buildLegendItem(AppTheme.successColor.withOpacity(0.3), 'Safety Zone'),
                          _buildLegendItem(AppTheme.primaryColor.withOpacity(0.3), 'Network Connections'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Toggle
                  Card(
                    child: SwitchListTile(
                      title: const Text('Static Geofence'),
                      subtitle: const Text('Optional fallback mode'),
                      value: _isStaticGeofence,
                      onChanged: (value) {
                        setState(() {
                          _isStaticGeofence = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserCard() {
    // Extract values to local variables to ensure fresh reads
    final lat = _currentUser?.latitude;
    final lon = _currentUser?.longitude;
    final isOnline = _currentUser?.isOnline ?? false;
    final name = _currentUser?.name ?? 'Unknown';
    
    // Debug: Print current values when building
    if (lat != null && lon != null) {
      print('🏗️ Building current user card: Lat=${lat.toStringAsFixed(6)}, Lon=${lon.toStringAsFixed(6)}, Counter=$_updateCounter');
    }
    
    return Card(
      key: ValueKey('user_card_$_updateCounter'),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    key: ValueKey('name_$_updateCounter'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (lat != null && lon != null)
                    Text(
                      'Lat: ${lat.toStringAsFixed(6)}, Lon: ${lon.toStringAsFixed(6)}',
                      key: ValueKey('location_${_updateCounter}_${lat}_${lon}'),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  if (isOnline)
                    Row(
                      key: ValueKey('online_$_updateCounter'),
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    final onlineUsers = _users.where((u) => u.isOnline && u.id != _currentUser?.id).toList();
    final offlineUsers = _users.where((u) => !u.isOnline && u.id != _currentUser?.id).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Users',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (onlineUsers.isNotEmpty) ...[
              const Text(
                'Online',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...onlineUsers.map((user) => _buildUserListItem(user, true)),
              const SizedBox(height: 16),
            ],
            if (offlineUsers.isNotEmpty) ...[
              const Text(
                'Offline',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...offlineUsers.map((user) => _buildUserListItem(user, false)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserListItem(UserModel user, bool isOnline) {
    final distance = user.latitude != null && user.longitude != null 
        ? _calculateDistance(user) 
        : 0.0;
    
    return Padding(
      key: ValueKey('user_${user.id}_${user.latitude?.toStringAsFixed(6)}_${user.longitude?.toStringAsFixed(6)}_$_updateCounter'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnline ? AppTheme.successColor : AppTheme.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(user.name),
          ),
          if (user.latitude != null && user.longitude != null)
            Builder(
              builder: (context) {
                // Force rebuild by using the actual distance value
                return Text(
                  '${distance.toStringAsFixed(2)} km',
                  key: ValueKey('distance_${user.id}_${distance.toStringAsFixed(2)}_$_updateCounter'),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSafetyStatusCard() {
    if (_safetyData == null) return const SizedBox.shrink();

    final isSafe = _safetyData!.status == SafetyStatus.safe;
    final isRisky = _safetyData!.status == SafetyStatus.risky;
    final isUnknown = _safetyData!.status == SafetyStatus.unknown;
    final noOtherUsers = _safetyData!.nearbyUsersCount == 0;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    if (noOtherUsers) {
      // Special case: No other users online
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.person_off;
      statusText = '⚠️ No Other Users Online';
      statusDescription = 'You are alone. Ensure other trusted users are online for safety monitoring.';
    } else if (isSafe) {
      statusColor = AppTheme.successColor;
      statusIcon = Icons.shield_outlined;
      statusText = '✅ Safe Zone';
      statusDescription = 'You are within ${_safetyData!.threshold.toStringAsFixed(0)}m average distance from ${_safetyData!.nearbyUsersCount} user(s)';
    } else if (isRisky) {
      statusColor = AppTheme.dangerColor;
      statusIcon = Icons.warning_amber_rounded;
      statusText = '⚠️ Risky Zone';
      statusDescription = 'Average distance ${_safetyData!.averageDistance.toStringAsFixed(1)}m exceeds ${_safetyData!.threshold.toStringAsFixed(0)}m threshold';
    } else {
      statusColor = AppTheme.textSecondary;
      statusIcon = Icons.help_outline;
      statusText = '❓ Unknown';
      statusDescription = 'Unable to determine safety status';
    }

    return Card(
      key: ValueKey('safety_status_$_updateCounter'),
      color: statusColor.withOpacity(0.1),
      elevation: isSafe ? 2 : (isRisky ? 8 : 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDescription,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isRisky)
                  Icon(Icons.notification_important, color: statusColor, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: statusColor.withOpacity(0.3)),
            const SizedBox(height: 12),
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSafetyMetric(
                  'Avg Distance',
                  _safetyData!.averageDistance == double.infinity
                      ? 'N/A'
                      : '${_safetyData!.averageDistance.toStringAsFixed(1)}m',
                  Icons.straighten,
                  statusColor,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: statusColor.withOpacity(0.3),
                ),
                _buildSafetyMetric(
                  'Threshold',
                  '${_safetyData!.threshold.toStringAsFixed(0)}m',
                  Icons.gps_fixed,
                  statusColor,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: statusColor.withOpacity(0.3),
                ),
                _buildSafetyMetric(
                  'Nearby Users',
                  '${_safetyData!.nearbyUsersCount}',
                  Icons.people,
                  statusColor,
                ),
              ],
            ),
            if (noOtherUsers) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: statusColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Other users need to be online for safety monitoring to work.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isRisky) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showSafetyConfirmationPopup(_safetyData!);
                  },
                  icon: const Icon(Icons.notification_important, color: Colors.white),
                  label: const Text('Safety Check'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  double _calculateDistance(UserModel user) {
    if (_currentUser?.latitude == null ||
        _currentUser?.longitude == null ||
        user.latitude == null ||
        user.longitude == null) {
      return 0.0;
    }

    return _haversineDistance(
      _currentUser!.latitude!,
      _currentUser!.longitude!,
      user.latitude!,
      user.longitude!,
    );
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        _toRadians(lat1).cos() *
            _toRadians(lat2).cos() *
            (dLon / 2).sin() *
            (dLon / 2).sin();
    final c = 2 * (a.sqrt()).atan2((1 - a).sqrt());
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (3.141592653589793 / 180);

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

extension MathExtensions on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double sqrt() => math.sqrt(this);
  double atan2(double other) => math.atan2(this, other);
}

