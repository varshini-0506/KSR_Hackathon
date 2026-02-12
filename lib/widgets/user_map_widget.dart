import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class UserMapWidget extends StatefulWidget {
  final List<UserModel> users;
  final UserModel? currentUser;
  final double mapWidth;
  final double mapHeight;

  const UserMapWidget({
    super.key,
    required this.users,
    this.currentUser,
    this.mapWidth = 400,
    this.mapHeight = 400,
  });

  @override
  State<UserMapWidget> createState() => _UserMapWidgetState();
}

class _UserMapWidgetState extends State<UserMapWidget> {
  @override
  void didUpdateWidget(UserMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force repaint when users data changes
    bool hasChanged = false;
    if (oldWidget.users.length != widget.users.length) {
      hasChanged = true;
    } else {
      for (int i = 0; i < widget.users.length; i++) {
        final oldUser = oldWidget.users[i];
        final newUser = widget.users[i];
        if (oldUser.id != newUser.id ||
            oldUser.latitude != newUser.latitude ||
            oldUser.longitude != newUser.longitude ||
            oldUser.isOnline != newUser.isOnline) {
          hasChanged = true;
          break;
        }
      }
    }
    if (oldWidget.currentUser?.id != widget.currentUser?.id ||
        oldWidget.currentUser?.latitude != widget.currentUser?.latitude ||
        oldWidget.currentUser?.longitude != widget.currentUser?.longitude) {
      hasChanged = true;
    }
    if (hasChanged) {
      print('🔄 Map widget updating: ${widget.users.length} users');
      print('  Current user location: Lat=${widget.currentUser?.latitude?.toStringAsFixed(6)}, Lon=${widget.currentUser?.longitude?.toStringAsFixed(6)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = widget.users;
    final currentUser = widget.currentUser;
    final mapWidth = widget.mapWidth;
    final mapHeight = widget.mapHeight;

    if (users.isEmpty) {
      return Container(
        height: mapHeight,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No users found'),
        ),
      );
    }

    // Calculate bounds
    final bounds = _calculateBounds(users);
    final latRange = bounds['latRange'] as double;
    final lonRange = bounds['lonRange'] as double;
    final centerLat = bounds['centerLat'] as double;
    final centerLon = bounds['centerLon'] as double;

    return Container(
      height: mapHeight,
      width: mapWidth,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: CustomPaint(
        key: ValueKey('painter_${users.length}_${users.map((u) => '${u.latitude}_${u.longitude}').join('_')}'),
        painter: UserMapPainter(
          users: users,
          currentUserId: currentUser?.id,
          latRange: latRange,
          lonRange: lonRange,
          centerLat: centerLat,
          centerLon: centerLon,
        ),
        child: Stack(
          children: [
            // User markers with names
            ...users.map((user) {
              if (user.latitude == null || user.longitude == null) {
                return const SizedBox.shrink();
              }

              final x = _normalizeLongitude(user.longitude!, centerLon, lonRange);
              final y = _normalizeLatitude(user.latitude!, centerLat, latRange);

              final isCurrentUser = currentUser?.id == user.id;
              final isOnline = user.isOnline;

              return Positioned(
                left: x * mapWidth - 30,
                top: y * mapHeight - 40,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User name label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isCurrentUser
                              ? AppTheme.primaryColor
                              : isOnline
                                  ? AppTheme.successColor
                                  : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // User marker icon
                    GestureDetector(
                      onTap: () {
                        // Show user info
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? AppTheme.primaryColor
                              : isOnline
                                  ? AppTheme.successColor
                                  : AppTheme.textSecondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isCurrentUser ? Icons.person : Icons.person_outline,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateBounds(List<UserModel> users) {
    final validUsers = users.where((u) => u.latitude != null && u.longitude != null).toList();
    
    if (validUsers.isEmpty) {
      return {
        'latRange': 0.01,
        'lonRange': 0.01,
        'centerLat': 0.0,
        'centerLon': 0.0,
      };
    }

    double minLat = validUsers.first.latitude!;
    double maxLat = validUsers.first.latitude!;
    double minLon = validUsers.first.longitude!;
    double maxLon = validUsers.first.longitude!;

    for (var user in validUsers) {
      if (user.latitude! < minLat) minLat = user.latitude!;
      if (user.latitude! > maxLat) maxLat = user.latitude!;
      if (user.longitude! < minLon) minLon = user.longitude!;
      if (user.longitude! > maxLon) maxLon = user.longitude!;
    }

    final latRange = (maxLat - minLat).abs();
    final lonRange = (maxLon - minLon).abs();

    // Add padding
    final padding = math.max(latRange, lonRange) * 0.2;
    final paddedLatRange = latRange + padding * 2;
    final paddedLonRange = lonRange + padding * 2;

    return {
      'latRange': paddedLatRange == 0 ? 0.01 : paddedLatRange,
      'lonRange': paddedLonRange == 0 ? 0.01 : paddedLonRange,
      'centerLat': (minLat + maxLat) / 2,
      'centerLon': (minLon + maxLon) / 2,
    };
  }

  double _normalizeLongitude(double lon, double centerLon, double lonRange) {
    return ((lon - centerLon) / lonRange) + 0.5;
  }

  double _normalizeLatitude(double lat, double centerLat, double latRange) {
    return ((lat - centerLat) / latRange) + 0.5;
  }
}

class UserMapPainter extends CustomPainter {
  final List<UserModel> users;
  final String? currentUserId;
  final double latRange;
  final double lonRange;
  final double centerLat;
  final double centerLon;
  final double mapWidth = 400;
  final double mapHeight = 400;

  UserMapPainter({
    required this.users,
    this.currentUserId,
    required this.latRange,
    required this.lonRange,
    required this.centerLat,
    required this.centerLon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final validUsers = users.where((u) => u.latitude != null && u.longitude != null).toList();
    
    if (validUsers.isEmpty) return;

    // Draw connecting lines (network visualization) - connect ALL users to ALL users
    final paint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Connect every user to every other user
    for (int i = 0; i < validUsers.length; i++) {
      for (int j = i + 1; j < validUsers.length; j++) {
        final user1 = validUsers[i];
        final user2 = validUsers[j];

        final x1 = _normalizeLongitude(user1.longitude!, centerLon, lonRange) * size.width;
        final y1 = _normalizeLatitude(user1.latitude!, centerLat, latRange) * size.height;
        final x2 = _normalizeLongitude(user2.longitude!, centerLon, lonRange) * size.width;
        final y2 = _normalizeLatitude(user2.latitude!, centerLat, latRange) * size.height;

        // Draw line connecting all users (no distance restriction)
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
    }

    // Draw safety zone around current user
    if (currentUserId != null) {
      final currentUser = validUsers.firstWhere(
        (u) => u.id == currentUserId,
        orElse: () => validUsers.first,
      );

      if (currentUser.latitude != null && currentUser.longitude != null) {
        final centerX = _normalizeLongitude(currentUser.longitude!, centerLon, lonRange) * size.width;
        final centerY = _normalizeLatitude(currentUser.latitude!, centerLat, latRange) * size.height;

        final zonePaint = Paint()
          ..color = AppTheme.successColor.withOpacity(0.1)
          ..style = PaintingStyle.fill;
        
        final zoneBorderPaint = Paint()
          ..color = AppTheme.successColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        // Draw safety zone circle (radius based on nearest user or fixed 2km)
        final radius = _calculateSafetyZoneRadius(currentUser, validUsers, size);
        canvas.drawCircle(Offset(centerX, centerY), radius, zonePaint);
        canvas.drawCircle(Offset(centerX, centerY), radius, zoneBorderPaint);
      }
    }
  }

  double _normalizeLongitude(double lon, double centerLon, double lonRange) {
    return ((lon - centerLon) / lonRange) + 0.5;
  }

  double _normalizeLatitude(double lat, double centerLat, double latRange) {
    return ((lat - centerLat) / latRange) + 0.5;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula
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

  double _calculateSafetyZoneRadius(
    UserModel currentUser,
    List<UserModel> allUsers,
    Size size,
  ) {
    // Find nearest user
    double minDistance = double.infinity;
    for (var user in allUsers) {
      if (user.id != currentUser.id && user.latitude != null && user.longitude != null) {
        final distance = _calculateDistance(
          currentUser.latitude!,
          currentUser.longitude!,
          user.latitude!,
          user.longitude!,
        );
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
    }

    // Convert distance to pixels (approximate)
    // Assuming 1km = ~100 pixels at this zoom level
    final radiusInMeters = math.min(minDistance * 0.5, 2000); // Max 2km radius
    return (radiusInMeters / 1000) * 50; // Scale to pixels
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is UserMapPainter) {
      // Repaint if users list changed or locations changed
      if (oldDelegate.users.length != users.length) return true;
      for (int i = 0; i < users.length; i++) {
        if (i >= oldDelegate.users.length) return true;
        if (oldDelegate.users[i].id != users[i].id) return true;
        if (oldDelegate.users[i].latitude != users[i].latitude) return true;
        if (oldDelegate.users[i].longitude != users[i].longitude) return true;
      }
      return oldDelegate.currentUserId != currentUserId;
    }
    return true;
  }
}
