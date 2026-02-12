# Sensor Data Collection Setup

This document explains how to set up sensor data collection and storage in Supabase.

## Architecture

```
Phone Sensors
   ↓
Flutter Sensor Listeners (stream)
   ↓
Local buffer (SQLite)
   ↓
Batch upload (every 10 seconds)
   ↓
Supabase Tables (Postgres)
```

## Setup Instructions

### 1. Configure Supabase Credentials

Edit `lib/config/supabase_config.dart` and add your Supabase credentials:

```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

### 2. Create Supabase Tables

Run these SQL commands in your Supabase SQL Editor:

```sql
-- Accelerometer Data Table
CREATE TABLE accelerometer_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  session_id UUID NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  x DOUBLE PRECISION NOT NULL,
  y DOUBLE PRECISION NOT NULL,
  z DOUBLE PRECISION NOT NULL
);

CREATE INDEX idx_accel_user_session 
ON accelerometer_data (user_id, session_id);

-- Gyroscope Data Table
CREATE TABLE gyroscope_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  session_id UUID NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  x DOUBLE PRECISION NOT NULL,
  y DOUBLE PRECISION NOT NULL,
  z DOUBLE PRECISION NOT NULL
);

CREATE INDEX idx_gyro_user_session 
ON gyroscope_data (user_id, session_id);

-- Proximity Sensor Data Table
CREATE TABLE proximity_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  session_id UUID NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  proximity_state INTEGER NOT NULL
);

CREATE INDEX idx_proximity_user_session 
ON proximity_data (user_id, session_id);

-- GPS Data Table
CREATE TABLE gps_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  session_id UUID NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  speed DOUBLE PRECISION,
  accuracy DOUBLE PRECISION
);

CREATE INDEX idx_gps_user_session 
ON gps_data (user_id, session_id);
```

### 3. Set Up Row Level Security (RLS)

In Supabase, enable RLS and create policies:

```sql
-- Enable RLS
ALTER TABLE accelerometer_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE gyroscope_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE proximity_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE gps_data ENABLE ROW LEVEL SECURITY;

-- Create policies (adjust based on your auth setup)
CREATE POLICY "Users can insert their own data"
ON accelerometer_data FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own data"
ON gyroscope_data FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own data"
ON proximity_data FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own data"
ON gps_data FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);
```

### 4. Install Dependencies

Run:
```bash
flutter pub get
```

### 5. Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 6. iOS Permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to provide safety monitoring</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to provide safety monitoring</string>
```

## How It Works

1. **Sensor Collection**: When the user logs in and reaches the home page, sensor collection automatically starts.

2. **Local Buffering**: All sensor data is stored locally in SQLite database (`sensor_data.db`).

3. **Batch Upload**: Every 10 seconds, the app:
   - Reads all buffered data from SQLite
   - Uploads to Supabase in batches
   - Deletes uploaded data from local database

4. **Session Management**: Each app session gets a unique `session_id` (UUID) that groups all sensor data together.

## Data Flow

- **Accelerometer**: X, Y, Z values collected continuously
- **Gyroscope**: X, Y, Z rotation values collected continuously
- **Proximity**: State (0 = Near, 1 = Far) collected on changes
- **GPS**: Latitude, longitude, speed, accuracy collected every 10 meters or when location changes

## Monitoring

Check Supabase dashboard to see incoming sensor data. Data is organized by:
- `user_id`: Unique identifier for each user
- `session_id`: Groups all data from a single app session
- `timestamp`: When the data was collected

## Troubleshooting

1. **No data appearing**: Check Supabase credentials in `supabase_config.dart`
2. **Permission errors**: Ensure location permissions are granted
3. **Upload failures**: Check internet connection and Supabase RLS policies
4. **Sensor not available**: Some devices may not have all sensors (proximity sensor is optional)
