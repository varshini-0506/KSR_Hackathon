# How to Enable Supabase Realtime

## Important: Realtime is NOT in Replication Section

The "Replication" section is for **read replicas** and external data pipelines, NOT for enabling Realtime.

## Correct Way to Enable Realtime

### Option 1: Enable via SQL (Recommended)

1. Go to **SQL Editor** in Supabase Dashboard
2. Run this SQL command:

```sql
-- Enable Realtime for users table
ALTER PUBLICATION supabase_realtime ADD TABLE users;
```

3. Verify it's enabled:
```sql
-- Check which tables have Realtime enabled
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
```

You should see `users` in the list.

### Option 2: Enable via Supabase Dashboard (if available)

1. Go to **Database** → **Publications** (not Replication!)
2. Click on `supabase_realtime` publication
3. Add the `users` table to the publication

### Option 3: Enable for All Tables (if needed)

If you want Realtime for all tables:

```sql
-- Enable Realtime for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE users, accelerometer_data, gyroscope_data, proximity_data, gps_data;
```

## Verify Realtime is Working

After enabling, test it:

1. Open your app's Geofence View
2. Check console logs - you should see:
   ```
   ✅ Successfully subscribed to realtime updates
   ```
3. Update a user's location in Supabase Table Editor
4. The app should update immediately without refresh

## Troubleshooting

### If SQL command fails:
- Make sure you're using the SQL Editor (not Realtime section)
- Check that the table `users` exists
- Verify you have the correct permissions

### If Realtime still doesn't work:
1. Check Supabase project settings
2. Verify your Supabase plan supports Realtime (Free tier supports it)
3. Check network/firewall settings
4. Try restarting the Realtime connection in your app

## Quick SQL Script

Run this in SQL Editor to enable Realtime for all your tables:

```sql
-- Enable Realtime for users table (for location updates)
ALTER PUBLICATION supabase_realtime ADD TABLE users;

-- Enable Realtime for sensor data tables (optional)
ALTER PUBLICATION supabase_realtime ADD TABLE accelerometer_data;
ALTER PUBLICATION supabase_realtime ADD TABLE gyroscope_data;
ALTER PUBLICATION supabase_realtime ADD TABLE proximity_data;
ALTER PUBLICATION supabase_realtime ADD TABLE gps_data;

-- Verify
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';
```

## What This Does

- **Enables Realtime**: Allows your Flutter app to listen to database changes
- **Instant Updates**: When any user's location changes, all connected devices get notified immediately
- **No Polling Needed**: Eliminates the need to constantly query the database

## After Enabling

Your app will automatically:
- ✅ Receive real-time updates when user locations change
- ✅ Update the geofence map instantly
- ✅ Sync across all devices in real-time
- ✅ Reduce database queries (more efficient)

Run the SQL command and your Realtime will be enabled! 🚀
