-- Quick Fix: Set all users online for testing
-- Run this in Supabase SQL Editor to make other users online

-- Set all users to online
UPDATE users 
SET is_online = true 
WHERE name IN ('User2', 'User3', 'User4');

-- Verify the change
SELECT 
    name, 
    email, 
    is_online, 
    latitude, 
    longitude,
    ROUND(latitude::numeric, 6) as lat_rounded,
    ROUND(longitude::numeric, 6) as lon_rounded
FROM users 
ORDER BY name;

-- Alternative: Set specific user online
-- UPDATE users SET is_online = true WHERE email = 'user2@gmail.com';

-- Alternative: Set all users online
-- UPDATE users SET is_online = true;

-- Alternative: Set all users offline except one
-- UPDATE users SET is_online = false WHERE email != 'user1@gmail.com';
-- UPDATE users SET is_online = true WHERE email = 'user1@gmail.com';
