import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:proximity_sensor/proximity_sensor.dart' as proximity;
import '../models/sensor_data.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<int>? _proximitySubscription;
  StreamSubscription<Position>? _gpsSubscription;
  
  final Function(AccelerometerData) onAccelerometerData;
  final Function(GyroscopeData) onGyroscopeData;
  final Function(ProximityData) onProximityData;
  final Function(GPSData) onGPSData;

  SensorService({
    required this.onAccelerometerData,
    required this.onGyroscopeData,
    required this.onProximityData,
    required this.onGPSData,
  });

  bool _isListening = false;

  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;

    // Start Accelerometer
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        onAccelerometerData(AccelerometerData(
          x: event.x,
          y: event.y,
          z: event.z,
          timestamp: DateTime.now(),
        ));
      },
      onError: (error) {
        print('Accelerometer error: $error');
      },
    );

    // Start Gyroscope
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        onGyroscopeData(GyroscopeData(
          x: event.x,
          y: event.y,
          z: event.z,
          timestamp: DateTime.now(),
        ));
      },
      onError: (error) {
        print('Gyroscope error: $error');
      },
    );

    // Start Proximity Sensor
    try {
      _proximitySubscription = proximity.ProximitySensor.events.listen(
        (int event) {
          // event is a bitmask: (event >> 0) & 1 gives near state
          // 0 = far, 1 = near
          final isNear = ((event >> 0) & 1) == 1;
          // Convert to our format: 0 = Near, 1 = Far
          final proximityState = isNear ? 0 : 1;
          onProximityData(ProximityData(
            proximityState: proximityState,
            timestamp: DateTime.now(),
          ));
        },
        onError: (error) {
          print('Proximity sensor error: $error');
        },
      );
    } catch (e) {
      print('Proximity sensor not available: $e');
    }

    // Start GPS
    await _startGPS();
  }

  Future<void> _startGPS() async {
    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    // Listen to GPS updates
    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (Position position) {
        onGPSData(GPSData(
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed,
          accuracy: position.accuracy,
          timestamp: DateTime.now(),
        ));
      },
      onError: (error) {
        print('GPS error: $error');
      },
    );
  }

  void stopListening() {
    _isListening = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _proximitySubscription?.cancel();
    _gpsSubscription?.cancel();
    
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _proximitySubscription = null;
    _gpsSubscription = null;
  }

  void dispose() {
    stopListening();
  }
}
