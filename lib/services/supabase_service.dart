import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _uuid = const Uuid();
  late SupabaseClient _client;

  bool _isInitialized = false;

  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    if (_isInitialized) {
      _client = Supabase.instance.client;
      print('Supabase already initialized');
      return;
    }
    
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      print('Supabase initialized successfully');
    } catch (e) {
      // If already initialized, get the instance
      try {
        _client = Supabase.instance.client;
        _isInitialized = true;
        print('Supabase was already initialized, using existing instance');
      } catch (e2) {
        print('Error initializing Supabase: $e2');
        rethrow;
      }
    }
  }

  SupabaseClient get client => _client;

  // Get current user ID
  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  // Generate session ID
  String generateSessionId() {
    return _uuid.v4();
  }

  // Upload Accelerometer Data
  Future<void> uploadAccelerometerData({
    required String userId,
    required String sessionId,
    required List<Map<String, dynamic>> dataList,
  }) async {
    if (dataList.isEmpty) return;

    final List<Map<String, dynamic>> records = dataList.map((data) {
      return {
        'user_id': userId,
        'session_id': sessionId,
        'timestamp': data['timestamp'],
        'x': data['x'],
        'y': data['y'],
        'z': data['z'],
      };
    }).toList();

    try {
      await _client.from('accelerometer_data').insert(records);
    } catch (e) {
      print('Error uploading accelerometer data: $e');
      rethrow;
    }
  }

  // Upload Gyroscope Data
  Future<void> uploadGyroscopeData({
    required String userId,
    required String sessionId,
    required List<Map<String, dynamic>> dataList,
  }) async {
    if (dataList.isEmpty) return;

    final List<Map<String, dynamic>> records = dataList.map((data) {
      return {
        'user_id': userId,
        'session_id': sessionId,
        'timestamp': data['timestamp'],
        'x': data['x'],
        'y': data['y'],
        'z': data['z'],
      };
    }).toList();

    try {
      await _client.from('gyroscope_data').insert(records);
    } catch (e) {
      print('Error uploading gyroscope data: $e');
      rethrow;
    }
  }

  // Upload Proximity Data
  Future<void> uploadProximityData({
    required String userId,
    required String sessionId,
    required List<Map<String, dynamic>> dataList,
  }) async {
    if (dataList.isEmpty) return;

    final List<Map<String, dynamic>> records = dataList.map((data) {
      return {
        'user_id': userId,
        'session_id': sessionId,
        'timestamp': data['timestamp'],
        'proximity_state': data['proximity_state'],
      };
    }).toList();

    try {
      await _client.from('proximity_data').insert(records);
    } catch (e) {
      print('Error uploading proximity data: $e');
      rethrow;
    }
  }

  // Upload GPS Data
  Future<void> uploadGPSData({
    required String userId,
    required String sessionId,
    required List<Map<String, dynamic>> dataList,
  }) async {
    if (dataList.isEmpty) return;

    final List<Map<String, dynamic>> records = dataList.map((data) {
      return {
        'user_id': userId,
        'session_id': sessionId,
        'timestamp': data['timestamp'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'speed': data['speed'],
        'accuracy': data['accuracy'],
      };
    }).toList();

    try {
      await _client.from('gps_data').insert(records);
    } catch (e) {
      print('Error uploading GPS data: $e');
      rethrow;
    }
  }
}
