-- Quick Fix: Set User2 location near User1 for testing
-- This simulates User2 being physically close to User1

-- Get User1's current location first
SELECT name, latitude, longitude, is_online 
FROM users 
WHERE name = 'User1';

-- Expected output: User1 is around Lat=11.36, Lon=77.83

-- Option 1: Set User2 very close to User1 (within 5 meters)
UPDATE users 
SET 
    latitude = 11.360100,  -- Very close to User1's 11.360053
    longitude = 77.827400, -- Very close to User1's 77.827360
    is_online = true,
    last_location_update = NOW()
WHERE name = 'User2';

-- Option 2: Set User2 exactly at User1's location (for testing)
-- UPDATE users 
-- SET 
--     latitude = (SELECT latitude FROM users WHERE name = 'User1'),
--     longitude = (SELECT longitude FROM users WHERE name = 'User1'),
--     is_online = true,
--     last_location_update = NOW()
-- WHERE name = 'User2';

-- Option 3: Set User2 at a specific nearby location (15 meters away)
-- UPDATE users 
-- SET 
--     latitude = 11.360200,  -- ~15m north of User1
--     longitude = 77.827360,
--     is_online = true,
--     last_location_update = NOW()
-- WHERE name = 'User2';

-- Verify the update
SELECT 
    name, 
    ROUND(latitude::numeric, 6) as lat,
    ROUND(longitude::numeric, 6) as lon,
    is_online,
    last_location_update
FROM users 
WHERE name IN ('User1', 'User2')
ORDER BY name;

-- Calculate distance between User1 and User2
-- (Rough approximation: 1 degree ≈ 111 km)
SELECT 
    ROUND(
        SQRT(
            POW((u1.latitude - u2.latitude) * 111000, 2) + 
            POW((u1.longitude - u2.longitude) * 111000, 2)
        )::numeric, 2
    ) as distance_meters
FROM 
    (SELECT latitude, longitude FROM users WHERE name = 'User1') u1,
    (SELECT latitude, longitude FROM users WHERE name = 'User2') u2;

-- Expected result after fix: < 10 meters
