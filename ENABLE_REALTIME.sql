-- Enable Supabase Realtime for Users Table
-- Run this in Supabase SQL Editor

-- Enable Realtime for users table (for location updates)
ALTER PUBLICATION supabase_realtime ADD TABLE users;

-- Optional: Enable Realtime for sensor data tables
ALTER PUBLICATION supabase_realtime ADD TABLE accelerometer_data;
ALTER PUBLICATION supabase_realtime ADD TABLE gyroscope_data;
ALTER PUBLICATION supabase_realtime ADD TABLE proximity_data;
ALTER PUBLICATION supabase_realtime ADD TABLE gps_data;

-- Verify Realtime is enabled
-- Run this query to see which tables have Realtime enabled:
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';

-- You should see 'users' and other tables in the results
