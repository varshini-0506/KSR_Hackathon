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

-- Insert 4 Default Users (All at same location for testing geofencing)
-- Location: Bangalore, India (Brigade Road area)
-- When users login, they will start at the same location and can test by moving
INSERT INTO users (email, phone, name, latitude, longitude, is_online) VALUES
('user1@gmail.com', '+911234567890', 'Alice Johnson', 12.9716, 77.5946, false),
('user2@gmail.com', '+911234567891', 'Bob Smith', 12.9716, 77.5946, false),
('user3@gmail.com', '+911234567892', 'Charlie Brown', 12.9716, 77.5946, false),
('user4@gmail.com', '+911234567893', 'Diana Prince', 12.9716, 77.5946, false);

-- Disable RLS for development (enable later with proper policies)
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Or enable RLS with policies (for production):
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Users can view all users" ON users FOR SELECT TO authenticated USING (true);
-- CREATE POLICY "Users can update their own data" ON users FOR UPDATE TO authenticated USING (auth.uid() = id);
