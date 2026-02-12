# Supabase Setup Guide - Step by Step

This guide will walk you through setting up Supabase and connecting it to your Vigil app.

## Step 1: Create a Supabase Account and Project

1. Go to [https://supabase.com](https://supabase.com)
2. Click **"Start your project"** or **"Sign Up"**
3. Sign up with GitHub, Google, or email
4. Once logged in, click **"New Project"**
5. Fill in the project details:
   - **Name**: `vigil-app` (or any name you prefer)
   - **Database Password**: Create a strong password (save this!)
   - **Region**: Choose the closest region to your users
   - **Pricing Plan**: Free tier is fine for development
6. Click **"Create new project"**
7. Wait 2-3 minutes for the project to be set up

## Step 2: Get Your Supabase Credentials

1. In your Supabase project dashboard, click on **"Settings"** (gear icon) in the left sidebar
2. Click on **"API"** in the settings menu
3. You'll see two important values:
   - **Project URL**: Something like `https://xxxxxxxxxxxxx.supabase.co`
   - **anon/public key**: A long string starting with `eyJ...`
4. **Copy both values** - you'll need them in Step 4

## Step 3: Create the Database Tables

1. In your Supabase dashboard, click on **"SQL Editor"** in the left sidebar
2. Click **"New query"**
3. Copy and paste the following SQL code:

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

4. Click **"Run"** button (or press Ctrl+Enter)
5. You should see "Success. No rows returned" - this means tables were created successfully!

## Step 4: Set Up Row Level Security (RLS) - Optional but Recommended

For now, we'll disable RLS to make testing easier. Later you can enable it with proper policies.

1. In SQL Editor, run this query:

```sql
-- Disable RLS for development (enable later with proper policies)
ALTER TABLE accelerometer_data DISABLE ROW LEVEL SECURITY;
ALTER TABLE gyroscope_data DISABLE ROW LEVEL SECURITY;
ALTER TABLE proximity_data DISABLE ROW LEVEL SECURITY;
ALTER TABLE gps_data DISABLE ROW LEVEL SECURITY;
```

**Note**: For production, you should enable RLS and create proper policies. See the advanced section below.

## Step 5: Configure Your Flutter App

1. Open `lib/config/supabase_config.dart` in your project
2. Replace the placeholder values with your actual Supabase credentials:

```dart
class SupabaseConfig {
  // Replace with your actual Supabase credentials
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';

  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL' && 
           supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
  }
}
```

**Example:**
```dart
static const String supabaseUrl = 'https://abcdefghijklmnop.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYxNjIzOTAyMiwiZXhwIjoxOTMxODE1MDIyfQ.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
```

## Step 6: Test the Connection

1. Run your app:
   ```bash
   flutter pub get
   flutter run
   ```

2. Log in and navigate to the Home page
3. Check the console/logs - you should see:
   - "Sensor collection started successfully"
   - "Batch upload completed: X accel, Y gyro, Z proximity, W GPS"

4. Go back to Supabase dashboard → **"Table Editor"**
5. Click on `accelerometer_data` table
6. After 10 seconds, you should see data appearing!

## Step 7: Verify Data is Being Stored

1. In Supabase dashboard, go to **"Table Editor"**
2. Click on each table:
   - `accelerometer_data`
   - `gyroscope_data`
   - `proximity_data`
   - `gps_data`
3. You should see rows of data with:
   - `user_id` (UUID)
   - `session_id` (UUID)
   - `timestamp`
   - Sensor-specific data (x, y, z for accelerometer/gyroscope, etc.)

## Troubleshooting

### Issue: "Supabase not configured" error
- **Solution**: Make sure you've updated `supabase_config.dart` with your actual credentials

### Issue: "Error uploading data" in console
- **Solution**: 
  1. Check your internet connection
  2. Verify Supabase URL and key are correct
  3. Make sure tables were created successfully
  4. Check if RLS is disabled (for development)

### Issue: No data appearing in tables
- **Solution**:
  1. Wait at least 10 seconds (batch upload interval)
  2. Check console logs for errors
  3. Verify sensors are available on your device
  4. Check if location permissions are granted

### Issue: Permission errors
- **Solution**: 
   - Android: Check `AndroidManifest.xml` has location permissions
   - iOS: Add location permissions to `Info.plist`

## Advanced: Enable Row Level Security (For Production)

When you're ready for production, enable RLS with proper policies:

```sql
-- Enable RLS
ALTER TABLE accelerometer_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE gyroscope_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE proximity_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE gps_data ENABLE ROW LEVEL SECURITY;

-- Create policies (if using Supabase Auth)
CREATE POLICY "Users can insert their own data"
ON accelerometer_data FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Repeat for other tables...
```

## Quick Reference

- **Supabase Dashboard**: [https://app.supabase.com](https://app.supabase.com)
- **SQL Editor**: Dashboard → SQL Editor
- **Table Editor**: Dashboard → Table Editor
- **API Settings**: Dashboard → Settings → API
- **Config File**: `lib/config/supabase_config.dart`

## Next Steps

Once connected:
1. ✅ Data will automatically collect every 10 seconds
2. ✅ You can query data in Supabase SQL Editor
3. ✅ You can view data in Table Editor
4. ✅ You can create dashboards and analytics

Happy coding! 🚀
