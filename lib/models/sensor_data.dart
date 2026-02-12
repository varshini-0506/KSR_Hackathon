class AccelerometerData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  AccelerometerData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'timestamp': timestamp.toIso8601String(),
      };
}

class GyroscopeData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  GyroscopeData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'timestamp': timestamp.toIso8601String(),
      };
}

class ProximityData {
  final int proximityState; // 0 = Near, 1 = Far
  final DateTime timestamp;

  ProximityData({
    required this.proximityState,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'proximity_state': proximityState,
        'timestamp': timestamp.toIso8601String(),
      };
}

class GPSData {
  final double latitude;
  final double longitude;
  final double? speed;
  final double? accuracy;
  final DateTime timestamp;

  GPSData({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
      };
}
