-- 1. Create public.events table
CREATE TABLE IF NOT EXISTS public.events (
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
    subgroup_id UUID REFERENCES public.subgroups(id) ON DELETE CASCADE,
    subgroup_ids UUID[] DEFAULT '{}'::UUID[],
    created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE SET NULL,
    category TEXT NOT NULL, -- e.g., 'workshop', 'technical', etc.
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'published'
    is_registration_open BOOLEAN DEFAULT true,
    registration_deadline TIMESTAMPTZ,
    registration_type TEXT DEFAULT 'individual',
    banner_image TEXT,
    agenda TEXT,
    registration_form JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create public.budgets table
CREATE TABLE IF NOT EXISTS public.budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    item_name TEXT NOT NULL,
    unit_price NUMERIC NOT NULL,
    quantity INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    added_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    remarks JSONB DEFAULT '[]'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ
);

-- 3. Create public.resources table
CREATE TABLE IF NOT EXISTS public.resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    cost NUMERIC,
    vendor_name TEXT,
    issued_at TIMESTAMPTZ,
    returned_at TIMESTAMPTZ,
    added_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    remarks JSONB DEFAULT '[]'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    type TEXT NOT NULL DEFAULT 'university', -- 'university', 'external'
    status TEXT NOT NULL DEFAULT 'pending' -- 'pending', 'approved', 'rejected', 'issued', 'returned'
);

-- 4. Create public.approvals table
CREATE TABLE IF NOT EXISTS public.approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL, -- 'event', 'budget', 'resource', 'venue'
    sender_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    receiver_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    approval_related_id UUID NOT NULL,
    remarks JSONB DEFAULT '[]'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'pending' -- 'pending', 'approved', 'rejected'
);

-- 5. Create public.remarks table
CREATE TABLE IF NOT EXISTS public.remarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    approval_id UUID NOT NULL REFERENCES public.approvals(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.users(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Create public.booked_slots table
CREATE TABLE IF NOT EXISTS public.booked_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    venue_id UUID NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    subgroup_id UUID REFERENCES public.subgroups(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Create public.registrations table
CREATE TABLE IF NOT EXISTS public.registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'confirmed', -- 'confirmed', 'cancelled', etc.
    answers JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Create public.attendance table
CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    entry_time TIMESTAMPTZ,
    exit_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- Row Level Security (RLS) policies
-- ================================================

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.remarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booked_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Allow select/read access to all authenticated users
CREATE POLICY "Allow read access to events" ON public.events FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read access to budgets" ON public.budgets FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read access to resources" ON public.resources FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read access to approvals" ON public.approvals FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read access to remarks" ON public.remarks FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read access to booked_slots" ON public.booked_slots FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read access to registrations" ON public.registrations FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read access to attendance" ON public.attendance FOR SELECT TO authenticated USING (true);

-- Allow all/write access to authenticated users
CREATE POLICY "Allow all access to events" ON public.events FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all access to budgets" ON public.budgets FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all access to resources" ON public.resources FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all access to approvals" ON public.approvals FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all access to remarks" ON public.remarks FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all access to booked_slots" ON public.booked_slots FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all access to registrations" ON public.registrations FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all access to attendance" ON public.attendance FOR ALL TO authenticated USING (true);
