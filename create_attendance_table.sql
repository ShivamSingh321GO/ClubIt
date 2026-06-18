CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL,
    user_id UUID NOT NULL,
    entry_time TIMESTAMP WITH TIME ZONE,
    exit_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add an index for faster lookups by event and user
CREATE INDEX idx_attendance_event_user ON attendance(event_id, user_id);

-- Enable RLS
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read attendance
CREATE POLICY "Enable read access for all users" ON attendance FOR SELECT USING (true);

-- Allow authenticated users to insert their own attendance
CREATE POLICY "Enable insert for authenticated users" ON attendance FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow authenticated users to update their own attendance (for exit time)
CREATE POLICY "Enable update for users based on user_id" ON attendance FOR UPDATE USING (auth.uid() = user_id);
