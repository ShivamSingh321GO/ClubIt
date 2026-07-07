-- 1. Create public.group_events table for group-wide/council-level events
CREATE TABLE IF NOT EXISTS public.group_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    number_of_volunteers INTEGER DEFAULT 0,
    number_of_registrations INTEGER DEFAULT 0,
    max_participants INTEGER DEFAULT 100,
    location TEXT NOT NULL,
    subgroup_id UUID, -- Nullable and constraint-free to avoid relation-not-found issues
    subgroup_ids UUID[] DEFAULT '{}'::UUID[], -- Associated subgroups for target scoping
    created_by UUID NOT NULL, -- Constraint-free to prevent foreign key ordering errors
    category TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'published', -- Group events default to published directly
    is_registration_open BOOLEAN DEFAULT true,
    registration_deadline TIMESTAMPTZ,
    registration_type TEXT DEFAULT 'individual',
    banner_image TEXT,
    agenda TEXT,
    registration_form JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Drop rigid foreign keys referencing public.events(id) on dependent tables
-- We use a DO block to check if each table exists before attempting to drop the constraints.
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'registrations') THEN
        ALTER TABLE public.registrations DROP CONSTRAINT IF EXISTS registrations_event_id_fkey;
    END IF;
    
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'attendance') THEN
        ALTER TABLE public.attendance DROP CONSTRAINT IF EXISTS attendance_event_id_fkey;
    END IF;
    
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'booked_slots') THEN
        ALTER TABLE public.booked_slots DROP CONSTRAINT IF EXISTS booked_slots_event_id_fkey;
    END IF;
    
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'approvals') THEN
        ALTER TABLE public.approvals DROP CONSTRAINT IF EXISTS approvals_event_id_fkey;
    END IF;
    
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'budgets') THEN
        ALTER TABLE public.budgets DROP CONSTRAINT IF EXISTS budgets_event_id_fkey;
    END IF;
    
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'resources') THEN
        ALTER TABLE public.resources DROP CONSTRAINT IF EXISTS resources_event_id_fkey;
    END IF;
END $$;

-- 3. Configure Row Level Security (RLS) policies for group_events
ALTER TABLE public.group_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read access to group_events" ON public.group_events FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow all access to group_events" ON public.group_events FOR ALL TO authenticated USING (true);
