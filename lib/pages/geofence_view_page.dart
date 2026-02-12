import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class GeofenceViewPage extends StatefulWidget {
  const GeofenceViewPage({super.key});

  @override
  State<GeofenceViewPage> createState() => _GeofenceViewPageState();
}

class _GeofenceViewPageState extends State<GeofenceViewPage> {
  bool _isStaticGeofence = false;

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
                    // Map View
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                      ),
                      child: Stack(
                        children: [
                          // Placeholder for map
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map, size: 64, color: AppTheme.textSecondary),
                                const SizedBox(height: 16),
                                Text(
                                  'Map View',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          // User Location Indicator
                          Positioned(
                            top: 180,
                            left: 180,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                          // Safety Zone Circle
                          Positioned(
                            top: 100,
                            left: 100,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.successColor,
                                  width: 2,
                                ),
                                color: AppTheme.successColor.withOpacity(0.1),
                              ),
                            ),
                          ),
                          // Trusted Contact Indicators
                          Positioned(
                            top: 120,
                            left: 250,
                            child: Icon(Icons.person, color: AppTheme.secondaryColor, size: 24),
                          ),
                          Positioned(
                            top: 250,
                            left: 150,
                            child: Icon(Icons.person, color: AppTheme.secondaryColor, size: 24),
                          ),
                        ],
                      ),
                    ),
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
                                'Your safety zone moves with your trusted circle',
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
                            _buildLegendItem(AppTheme.primaryColor, 'Your Location'),
                            _buildLegendItem(AppTheme.successColor, 'Safety Zone'),
                            _buildLegendItem(AppTheme.secondaryColor, 'Trusted Contacts'),
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
