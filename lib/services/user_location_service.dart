import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';
import '../config/supabase_config.dart';

class UserLocationService {
  static final UserLocationService _instance = UserLocationService._internal();
  factory UserLocationService() => _instance;
  UserLocationService._internal();

  final SupabaseService _supabase = SupabaseService();
  StreamSubscription<Position>? _locationSubscription;
  Timer? _updateTimer;
  String? _currentUserId;
  bool _isUpdating = false;
  Position? _lastPosition;
  DateTime? _lastUpdateTime;

  /// Initialize Supabase if not already initialized
  Future<void> _ensureSupabaseInitialized() async {
    if (!SupabaseConfig.isConfigured) {
      throw Exception('Supabase not configured');
    }
    final supabaseService = SupabaseService();
    try {
      await supabaseService.initialize(
        supabaseUrl: SupabaseConfig.supabaseUrl,
        supabaseAnonKey: SupabaseConfig.supabaseAnonKey,
      );
    } catch (e) {
      // Already initialized, ignore
    }
  }

  /// Start updating user location every 5-10 seconds
  Future<void> startLocationUpdates(String userId) async {
    await _ensureSupabaseInitialized();
    if (_isUpdating && _currentUserId == userId) {
      print('Location updates already running for user: $userId');
      return;
    }
    
    _currentUserId = userId;
    _isUpdating = true;

    print('Starting location updates for user: $userId');

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('ERROR: Location services are disabled. Please enable location services in device settings.');
      _isUpdating = false;
      return;
    }
    print('Location services enabled: $serviceEnabled');

    // Check and request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    print('Current location permission: $permission');

    if (permission == LocationPermission.denied) {
      print('Requesting location permission...');
      permission = await Geolocator.requestPermission();
      print('Permission request result: $permission');
      
      if (permission == LocationPermission.denied) {
        print('ERROR: Location permissions are denied. Please grant location permission in app settings.');
        _isUpdating = false;
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('ERROR: Location permissions are permanently denied. Please enable in app settings.');
      _isUpdating = false;
      return;
    }

    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      print('ERROR: Invalid permission state: $permission');
      _isUpdating = false;
      return;
    }

    print('Location permission granted: $permission');

    // Update immediately
    print('Getting initial location...');
    await _updateUserLocation(userId);

    // Use position stream for real-time updates via WebSocket-like streaming
    // This provides instant updates when device moves
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, // Highest accuracy
        distanceFilter: 1, // Update every 1 meter of movement (very sensitive)
        timeLimit: Duration.zero, // No time limit - continuous updates
      ),
    ).listen(
      (Position position) async {
        // Push position update immediately to Supabase (WebSocket-style)
        if (_shouldUpdateLocation(position)) {
          print('📍 Live position update: Lat=${position.latitude}, Lon=${position.longitude}');
          await _pushLocationToSupabase(userId, position);
          _lastPosition = position;
          _lastUpdateTime = DateTime.now();
        }
      },
      onError: (error) {
        print('Location stream error: $error');
        // Fallback to periodic updates if stream fails
        _startPeriodicUpdates(userId);
      },
    );
    
    // Aggressive backup timer (every 2 seconds) in case stream misses updates
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      // Only update if stream hasn't updated recently
      if (_lastUpdateTime == null || 
          DateTime.now().difference(_lastUpdateTime!) > const Duration(seconds: 3)) {
        await _updateUserLocation(userId);
      }
    });
    
    print('🚀 Real-time location tracking started (WebSocket-style streaming + 2s backup)');
  }

  bool _shouldUpdateLocation(Position newPosition) {
    if (_lastPosition == null) return true;
    
    // Calculate distance moved
    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    
    // Calculate time since last update
    final timeSinceUpdate = _lastUpdateTime != null 
        ? DateTime.now().difference(_lastUpdateTime!)
        : const Duration(seconds: 10);
    
    // Update if moved more than 1 meter OR more than 2 seconds passed OR accuracy improved
    final accuracyImproved = newPosition.accuracy < (_lastPosition!.accuracy - 5);
    
    return distance > 1 || timeSinceUpdate.inSeconds > 2 || accuracyImproved;
  }

  void _startPeriodicUpdates(String userId) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _updateUserLocation(userId);
    });
    print('Fallback periodic updates started (every 2 seconds for real-time sync)');
  }

  /// Push location directly to Supabase (optimized for streaming)
  Future<void> _pushLocationToSupabase(String userId, Position position) async {
    try {
      final client = _supabase.client;
      
      // Direct push to Supabase via WebSocket connection
      await client.from('users').update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed >= 0 ? position.speed : null,
        'accuracy': position.accuracy >= 0 ? position.accuracy : null,
        'last_location_update': DateTime.now().toIso8601String(),
        'is_online': true,
      }).eq('id', userId);
      
      print('✅ Live update pushed: Lat=${position.latitude}, Lon=${position.longitude}');
    } catch (e) {
      print('❌ Error pushing live location: $e');
    }
  }

  Future<void> _updateUserLocation(String userId) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 5),
      );

      await _pushLocationToSupabase(userId, position);
      _lastPosition = position;
      _lastUpdateTime = DateTime.now();
    } catch (e) {
      print('❌ Error updating user location: $e');
      
      // Try to get last known position as fallback
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          print('Using last known position: Lat=${lastPosition.latitude}, Lon=${lastPosition.longitude}');
          await _pushLocationToSupabase(userId, lastPosition);
          _lastPosition = lastPosition;
          _lastUpdateTime = DateTime.now();
        }
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
      }
    }
  }

  /// Stop location updates
  Future<void> stopLocationUpdates() async {
    _isUpdating = false;
    _updateTimer?.cancel();
    _updateTimer = null;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _lastPosition = null;
    _lastUpdateTime = null;

    // Mark user as offline
    if (_currentUserId != null) {
      try {
        await _supabase.client.from('users').update({
          'is_online': false,
        }).eq('id', _currentUserId!);
        print('User marked as offline: $_currentUserId');
      } catch (e) {
        print('Error marking user offline: $e');
      }
    }
    _currentUserId = null;
  }

  /// Get all users with their locations
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase.client
          .from('users')
          .select()
          .order('name');

      return (response as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  /// Get online users only
  Future<List<UserModel>> getOnlineUsers() async {
    try {
      final response = await _supabase.client
          .from('users')
          .select()
          .eq('is_online', true)
          .order('name');

      return (response as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching online users: $e');
      return [];
    }
  }

  /// Subscribe to real-time user location updates
  RealtimeChannel subscribeToUserUpdates({
    required Function(List<UserModel>) onUsersUpdated,
  }) {
    print('Setting up realtime subscription for user location updates...');
    
    final channel = _supabase.client
        .channel('users_location_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: (payload) {
            print('🔔 Realtime update received for users table');
            print('Event type: ${payload.eventType}');
            print('Old record: ${payload.oldRecord}');
            print('New record: ${payload.newRecord}');
            
            // Fetch updated users list immediately when any user location changes
            getAllUsers().then((users) {
              print('📊 Fetched ${users.length} users after realtime update');
              // Log location data for debugging
              for (var user in users) {
                if (user.latitude != null && user.longitude != null) {
                  print('  - ${user.name}: Lat=${user.latitude}, Lon=${user.longitude}');
                }
              }
              onUsersUpdated(users);
            }).catchError((error) {
              print('❌ Error fetching users after realtime update: $error');
            });
          },
        )
        .subscribe(
          (status, [error]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              print('✅ Successfully subscribed to realtime updates');
            } else if (status == RealtimeSubscribeStatus.timedOut) {
              print('⚠️ Realtime subscription timed out');
            } else if (status == RealtimeSubscribeStatus.channelError) {
              print('❌ Realtime channel error: $error');
            } else {
              print('Realtime status: $status');
            }
          },
        );

    return channel;
  }

  /// Get current user by ID
  Future<UserModel?> getCurrentUser(String userId) async {
    try {
      final response = await _supabase.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }

  void dispose() {
    stopLocationUpdates();
  }
}
