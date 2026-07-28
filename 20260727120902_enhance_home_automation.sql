/*
# Home Automation Enhancements

1. New Tables
- `profiles` — per-user profile with role (admin/family/member/guest), phone number, face recognition enrollment.
- `sos_alerts` — emergency SOS button events with location and status.

2. Modified Tables
- `devices` — add columns: device_id (hardware ID for ESP32/Arduino), protocol (mqtt/http), mqtt_topic, firmware_version, last_seen, qr_token (for QR pairing).
- `sensors` — add columns: unit, min_value, max_value for live data charting.

3. Security
- RLS enabled on all new tables, owner-scoped via auth.uid().
- Profiles use ON DELETE CASCADE to auth.users.

4. Notes
- Roles drive UI access: admin (full), family (control + view), member (control), guest (view only).
- QR token allows pairing a physical ESP32/Arduino device via QR code scan.
- MQTT topic field enables IoT integration with MQTT brokers.
*/

CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id uuid NOT NULL DEFAULT auth.uid(),
  full_name text NOT NULL DEFAULT 'User',
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('admin','family','member','guest')),
  phone text,
  phone_verified boolean NOT NULL DEFAULT false,
  face_enrolled boolean NOT NULL DEFAULT false,
  notifications_enabled boolean NOT NULL DEFAULT true,
  sms_enabled boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_profile" ON profiles;
CREATE POLICY "select_own_profile" ON profiles FOR SELECT TO authenticated USING (auth.uid() = id);
DROP POLICY IF EXISTS "insert_own_profile" ON profiles;
CREATE POLICY "insert_own_profile" ON profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "update_own_profile" ON profiles;
CREATE POLICY "update_own_profile" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Add device_id column if not exists
DO $$ BEGIN
  ALTER TABLE devices ADD COLUMN IF NOT EXISTS device_id text;
  ALTER TABLE devices ADD COLUMN IF NOT EXISTS protocol text DEFAULT 'mqtt';
  ALTER TABLE devices ADD COLUMN IF NOT EXISTS mqtt_topic text;
  ALTER TABLE devices ADD COLUMN IF NOT EXISTS firmware_version text;
  ALTER TABLE devices ADD COLUMN IF NOT EXISTS last_seen timestamptz;
  ALTER TABLE devices ADD COLUMN IF NOT EXISTS qr_token text;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Add sensor columns if not exist
DO $$ BEGIN
  ALTER TABLE sensors ADD COLUMN IF NOT EXISTS unit text DEFAULT '';
  ALTER TABLE sensors ADD COLUMN IF NOT EXISTS min_value numeric;
  ALTER TABLE sensors ADD COLUMN IF NOT EXISTS max_value numeric;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS sos_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  location text,
  message text NOT NULL DEFAULT 'Emergency SOS triggered',
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','resolved')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE sos_alerts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_sos" ON sos_alerts;
CREATE POLICY "select_own_sos" ON sos_alerts FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "insert_own_sos" ON sos_alerts;
CREATE POLICY "insert_own_sos" ON sos_alerts FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "update_own_sos" ON sos_alerts;
CREATE POLICY "update_own_sos" ON sos_alerts FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
