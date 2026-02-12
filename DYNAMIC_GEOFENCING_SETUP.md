# Dynamic Geofencing Setup Guide

This guide explains how to set up dynamic geofencing with live user locations.

## Step 1: Create Users Table in Supabase

1. Go to your Supabase Dashboard → SQL Editor
2. Run the SQL from `SUPABASE_USERS_TABLE.sql`:

```sql
-- Users Table for Dynamic Geofencing
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- GPS Location Fields
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  speed DOUBLE PRECISION,
  accuracy DOUBLE PRECISION,
  last_location_update TIMESTAMPTZ,
  -- User Status
  is_online BOOLEAN DEFAULT false,
  session_id UUID
);

CREATE INDEX idx_users_location ON users (latitude, longitude);
CREATE INDEX idx_users_online ON users (is_online);
CREATE INDEX idx_users_session ON users (session_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to auto-update updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert 4 Default Users
INSERT INTO users (email, phone, name, latitude, longitude, is_online) VALUES
('user1@vigil.com', '+911234567890', 'Alice Johnson', 12.9716, 77.5946, false),
('user2@vigil.com', '+911234567891', 'Bob Smith', 12.9352, 77.6245, false),
('user3@vigil.com', '+911234567892', 'Charlie Brown', 12.9141, 77.6412, false),
('user4@vigil.com', '+911234567893', 'Diana Prince', 12.9279, 77.6271, false);

-- Disable RLS for development
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
```

This creates:
- ✅ Users table with GPS location fields
- ✅ 4 default users (Alice, Bob, Charlie, Diana)
- ✅ Indexes for fast queries
- ✅ Auto-update timestamp trigger

## Step 2: Configure Supabase Credentials

Make sure you've updated `lib/config/supabase_config.dart` with your Supabase URL and anon key.

## Step 3: How It Works

### Login Flow:
1. User enters phone/email on login page
2. `UserAuthService` checks if user exists in Supabase
3. If exists → marks as online, starts location updates
4. If new → creates user, marks as online, starts location updates
5. Location updates every 5-10 seconds automatically

### Location Updates:
- **Frequency**: Every 7 seconds (randomized between 5-10)
- **Updates**: Latitude, longitude, speed, accuracy, last_location_update
- **Status**: Sets `is_online = true` when active

### Geofence View:
- Shows all users on a map
- **Blue dot** = Current user (You)
- **Green dot** = Online users
- **Gray dot** = Offline users
- **Green circle** = Safety zone (dynamic, adapts to nearby users)
- **Blue lines** = Network connections (users within 5km)

### Real-time Updates:
- Uses Supabase Realtime to listen for user location changes
- Map refreshes every 5 seconds
- Shows live distance calculations

## Step 4: Testing

1. **Login as User 1**:
   - Phone: `+911234567890` or Email: `user1@vigil.com`
   - Click "Send OTP"
   - Go to Home → Location updates start automatically

2. **View Geofence**:
   - Open drawer menu → "Geofence View"
   - You'll see:
     - Your location (blue dot)
     - Other users' locations
     - Network connections
     - Safety zone circle

3. **Test with Multiple Devices**:
   - Login as different users on different devices
   - Watch locations update in real-time
   - See network connections form between nearby users

## Step 5: Default Users

You can login with any of these:

| Name | Phone | Email |
|------|-------|-------|
| Alice Johnson | +911234567890 | user1@vigil.com |
| Bob Smith | +911234567891 | user2@vigil.com |
| Charlie Brown | +911234567892 | user3@vigil.com |
| Diana Prince | +911234567893 | user4@vigil.com |

## Features

✅ **Live Location Updates**: GPS updates every 5-10 seconds  
✅ **Real-time Sync**: Uses Supabase Realtime  
✅ **Network Visualization**: Shows connections between users  
✅ **Dynamic Safety Zone**: Adapts based on nearby users  
✅ **Online/Offline Status**: Shows who's active  
✅ **Distance Calculation**: Shows distance to each user  

## Troubleshooting

### No users showing:
- Check Supabase table was created
- Verify default users were inserted
- Check Supabase credentials

### Location not updating:
- Grant location permissions
- Check internet connection
- Verify user is logged in

### Map not displaying:
- Check if users have latitude/longitude values
- Verify Supabase connection
- Check console for errors

## Next Steps

After this is working, we can add:
- Trusted circle filtering
- Geofence alerts
- Movement pattern analysis
- Emergency detection based on geofence violations
