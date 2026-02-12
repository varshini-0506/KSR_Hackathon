import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/user_location_service.dart';
import '../services/user_auth_service.dart';
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
  
  List<UserModel> _users = [];
  UserModel? _currentUser;
  RealtimeChannel? _realtimeChannel;
  Timer? _refreshTimer;
  int _updateCounter = 0; // Force rebuild counter

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _subscribeToUpdates();
    
    // Aggressive refresh for real-time sync (every 1 second)
    // Note: Supabase Realtime (WebSocket) will trigger most updates instantly
    // This is just a backup to ensure UI consistency
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _loadUsers();
      }
    });
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
    super.dispose();
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

