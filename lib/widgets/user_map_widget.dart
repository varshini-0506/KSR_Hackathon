import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';

class UserMapWidget extends StatefulWidget {
  final List<UserModel> users;
  final UserModel? currentUser;

  const UserMapWidget({
    super.key,
    required this.users,
    this.currentUser,
  });

  @override
  State<UserMapWidget> createState() => _UserMapWidgetState();
}

class _UserMapWidgetState extends State<UserMapWidget> {
  final MapController _mapController = MapController();
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _centerMapInitial();
        _hasInitialized = true;
      }
    });
  }

  @override
  void didUpdateWidget(UserMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // DISABLE auto-recentering - let user control the map!
    // Only recenter on initial load in initState
    // Markers will update position without moving the map
    
    // Log for debugging (but don't recenter)
    if (widget.currentUser != null && oldWidget.currentUser != null) {
      final oldLat = oldWidget.currentUser?.latitude;
      final oldLon = oldWidget.currentUser?.longitude;
      final newLat = widget.currentUser?.latitude;
      final newLon = widget.currentUser?.longitude;
      
      if (oldLat != newLat || oldLon != newLon) {
        // Just update markers, don't move camera
        // User has full control of map position
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _centerMapInitial() {
    if (widget.currentUser?.latitude != null && widget.currentUser?.longitude != null) {
      final center = LatLng(
        widget.currentUser!.latitude!,
        widget.currentUser!.longitude!,
      );
      
      // Calculate bounds to include all online users
      final onlineUsers = widget.users.where((u) => 
        u.isOnline && u.latitude != null && u.longitude != null
      ).toList();
      
      if (onlineUsers.length > 1) {
        // Fit bounds to show all users with comfortable zoom
        double minLat = onlineUsers.map((u) => u.latitude!).reduce(math.min);
        double maxLat = onlineUsers.map((u) => u.latitude!).reduce(math.max);
        double minLng = onlineUsers.map((u) => u.longitude!).reduce(math.min);
        double maxLng = onlineUsers.map((u) => u.longitude!).reduce(math.max);
        
        final bounds = LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        );
        
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(80),
            maxZoom: 17.0, // Don't zoom in too close
          ),
        );
      } else {
        // Just center on current user with comfortable zoom
        _mapController.move(center, 14.5); // Less zoomed in
      }
    }
  }

  void _centerMapSmoothly() {
    if (widget.currentUser?.latitude != null && widget.currentUser?.longitude != null) {
      final center = LatLng(
        widget.currentUser!.latitude!,
        widget.currentUser!.longitude!,
      );
      
      // Smooth move to new position without changing zoom
      try {
        final currentZoom = _mapController.camera.zoom;
        _mapController.move(center, currentZoom);
      } catch (e) {
        // Fallback if camera not initialized
        _mapController.move(center, 14.5);
      }
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    // Add current user marker (highlighted)
    if (widget.currentUser?.latitude != null && widget.currentUser?.longitude != null) {
      markers.add(
        Marker(
          point: LatLng(
            widget.currentUser!.latitude!,
            widget.currentUser!.longitude!,
          ),
          width: 80,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Add other users markers
    for (var user in widget.users) {
      if (user.id == widget.currentUser?.id) continue;
      if (user.latitude == null || user.longitude == null) continue;
      
      final isOnline = user.isOnline;
      final markerColor = isOnline ? Colors.green : Colors.grey;
      
      markers.add(
        Marker(
          point: LatLng(user.latitude!, user.longitude!),
          width: 80,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: markerColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: markerColor.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  isOnline ? Icons.person : Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return markers;
  }

  List<Polyline> _buildConnections() {
    final polylines = <Polyline>[];
    
    if (widget.currentUser?.latitude == null || widget.currentUser?.longitude == null) {
      return polylines;
    }
    
    final currentUserPoint = LatLng(
      widget.currentUser!.latitude!,
      widget.currentUser!.longitude!,
    );
    
    // Draw connections to online users
    for (var user in widget.users) {
      if (user.id == widget.currentUser?.id) continue;
      if (!user.isOnline) continue;
      if (user.latitude == null || user.longitude == null) continue;
      
      final userPoint = LatLng(user.latitude!, user.longitude!);
      
      polylines.add(
        Polyline(
          points: [currentUserPoint, userPoint],
          color: Colors.blue.withOpacity(0.4),
          strokeWidth: 2,
          isDotted: true,
        ),
      );
    }
    
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    // Default center if no current user
    final defaultCenter = widget.currentUser?.latitude != null && widget.currentUser?.longitude != null
        ? LatLng(widget.currentUser!.latitude!, widget.currentUser!.longitude!)
        : LatLng(11.360053, 77.827360); // Fallback location
    
    print('🗺️ Building map with center: ${defaultCenter.latitude}, ${defaultCenter.longitude}');
    print('🗺️ Total users to display: ${widget.users.length}');
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: defaultCenter,
          initialZoom: 14.5, // Comfortable starting zoom
          minZoom: 11.0, // Allow zooming out to see area
          maxZoom: 18.5, // Allow zooming in for details
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
            enableMultiFingerGestureRace: true,
          ),
          onMapReady: () {
            print('✅ Map is ready!');
            _centerMapInitial();
          },
          // No onPositionChanged needed - user has full control always
        ),
        children: [
          // OpenStreetMap tile layer with optimized configuration
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.vigil',
            subdomains: const ['a', 'b', 'c'],
            maxZoom: 19,
            maxNativeZoom: 19,
            minNativeZoom: 1,
            tileSize: 256,
            keepBuffer: 5, // Keep more tiles in memory for smooth zooming
            panBuffer: 2, // Load tiles ahead while panning
            retinaMode: false,
            errorTileCallback: (tile, error, stackTrace) {
              print('❌ Tile load error at zoom ${tile.coordinates.z}: $error');
            },
            tileProvider: NetworkTileProvider(),
          ),
          
          // Connection lines between users
          PolylineLayer(
            polylines: _buildConnections(),
          ),
          
          // User markers
          MarkerLayer(
            markers: _buildMarkers(),
          ),
        ],
      ),
    );
  }
}
