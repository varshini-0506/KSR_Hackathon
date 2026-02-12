import 'package:uuid/uuid.dart';
import 'sensor_service.dart';
import 'local_database_service.dart';
import 'batch_upload_service.dart';
import 'supabase_service.dart';
import '../models/sensor_data.dart';

class SensorManager {
  static final SensorManager _instance = SensorManager._internal();
  factory SensorManager() => _instance;
  SensorManager._internal();

  final _uuid = const Uuid();
  SensorService? _sensorService;
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final BatchUploadService _batchUpload = BatchUploadService();
  final SupabaseService _supabase = SupabaseService();

  String? _currentSessionId;
  String? _currentUserId;
  bool _isRunning = false;

  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await _supabase.initialize(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );
  }

  Future<void> startSensorCollection({String? userId, String? sessionId}) async {
    if (_isRunning) return;

    // Get or create user ID
    _currentUserId = userId ?? _supabase.getCurrentUserId() ?? _uuid.v4();
    
    // Generate session ID
    _currentSessionId = sessionId ?? _uuid.v4();

    _isRunning = true;

    // Initialize sensor service
    _sensorService = SensorService(
      onAccelerometerData: (data) => _localDb.insertAccelerometerData(data),
      onGyroscopeData: (data) => _localDb.insertGyroscopeData(data),
      onProximityData: (data) => _localDb.insertProximityData(data),
      onGPSData: (data) => _localDb.insertGPSData(data),
    );

    // Start listening to sensors
    await _sensorService!.startListening();

    // Start batch upload service (uploads every 10 seconds)
    await _batchUpload.start(
      userId: _currentUserId!,
      sessionId: _currentSessionId!,
    );

    print('Sensor collection started - Session: $_currentSessionId');
  }

  Future<void> stopSensorCollection() async {
    if (!_isRunning) return;

    _isRunning = false;
    _sensorService?.stopListening();
    await _batchUpload.stop();

    print('Sensor collection stopped');
  }

  String? getCurrentSessionId() => _currentSessionId;
  String? getCurrentUserId() => _currentUserId;
  bool get isRunning => _isRunning;

  void dispose() {
    stopSensorCollection();
    _sensorService?.dispose();
    _batchUpload.dispose();
  }
}
