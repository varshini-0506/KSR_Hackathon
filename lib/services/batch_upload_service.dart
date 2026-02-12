import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_database_service.dart';
import 'supabase_service.dart';

class BatchUploadService {
  static final BatchUploadService _instance = BatchUploadService._internal();
  factory BatchUploadService() => _instance;
  BatchUploadService._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService();
  final SupabaseService _supabase = SupabaseService();
  Timer? _uploadTimer;
  bool _isRunning = false;
  String? _currentSessionId;
  String? _currentUserId;

  Future<void> start({
    required String userId,
    required String sessionId,
  }) async {
    if (_isRunning) return;

    _currentUserId = userId;
    _currentSessionId = sessionId;

    // Save session info
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_session_id', sessionId);
    await prefs.setString('current_user_id', userId);

    _isRunning = true;

    // Upload immediately on start
    await _uploadBatch();

    // Then upload every 10 seconds
    _uploadTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _uploadBatch();
    });
  }

  Future<void> stop() async {
    _isRunning = false;
    _uploadTimer?.cancel();
    _uploadTimer = null;

    // Final upload before stopping
    await _uploadBatch();

    // Clear session info
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_session_id');
    await prefs.remove('current_user_id');
  }

  Future<void> _uploadBatch() async {
    if (_currentUserId == null || _currentSessionId == null) {
      // Try to restore from preferences
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('current_user_id');
      _currentSessionId = prefs.getString('current_session_id');
      
      if (_currentUserId == null || _currentSessionId == null) {
        print('No user ID or session ID available for upload');
        return;
      }
    }

    try {
      // Get all buffered data
      final accelerometerData = await _localDb.getAllAccelerometerData();
      final gyroscopeData = await _localDb.getAllGyroscopeData();
      final proximityData = await _localDb.getAllProximityData();
      final gpsData = await _localDb.getAllGPSData();

      // Upload to Supabase
      if (accelerometerData.isNotEmpty) {
        await _supabase.uploadAccelerometerData(
          userId: _currentUserId!,
          sessionId: _currentSessionId!,
          dataList: accelerometerData,
        );
        // Delete uploaded data
        final ids = accelerometerData.map((e) => e['id'] as int).toList();
        await _localDb.deleteAccelerometerData(ids);
      }

      if (gyroscopeData.isNotEmpty) {
        await _supabase.uploadGyroscopeData(
          userId: _currentUserId!,
          sessionId: _currentSessionId!,
          dataList: gyroscopeData,
        );
        final ids = gyroscopeData.map((e) => e['id'] as int).toList();
        await _localDb.deleteGyroscopeData(ids);
      }

      if (proximityData.isNotEmpty) {
        await _supabase.uploadProximityData(
          userId: _currentUserId!,
          sessionId: _currentSessionId!,
          dataList: proximityData,
        );
        final ids = proximityData.map((e) => e['id'] as int).toList();
        await _localDb.deleteProximityData(ids);
      }

      if (gpsData.isNotEmpty) {
        await _supabase.uploadGPSData(
          userId: _currentUserId!,
          sessionId: _currentSessionId!,
          dataList: gpsData,
        );
        final ids = gpsData.map((e) => e['id'] as int).toList();
        await _localDb.deleteGPSData(ids);
      }

      print('Batch upload completed: ${accelerometerData.length} accel, ${gyroscopeData.length} gyro, ${proximityData.length} proximity, ${gpsData.length} GPS');
    } catch (e) {
      print('Error in batch upload: $e');
      // Data remains in local DB for retry
    }
  }

  void dispose() {
    stop();
  }
}
