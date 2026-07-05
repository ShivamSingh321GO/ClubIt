-- Create activities table linked to subgroups
CREATE TABLE IF NOT EXISTS public.activities (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  type character varying NOT NULL,
  title character varying NOT NULL,
  description text NOT NULL,
  date timestamp with time zone NOT NULL,
  location character varying,
  subgroup_id uuid NOT NULL,
  posted_by uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT activities_pkey PRIMARY KEY (id),
  CONSTRAINT activities_subgroup_id_fkey FOREIGN KEY (subgroup_id) REFERENCES public.subgroups(id) ON DELETE CASCADE,
  CONSTRAINT activities_posted_by_fkey FOREIGN KEY (posted_by) REFERENCES public.users(id) ON DELETE CASCADE
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- 1. Allow public select (anyone can view activities)
CREATE POLICY "Allow public select on activities" ON public.activities
    FOR SELECT TO public USING (true);

-- 2. Allow authenticated insert
CREATE POLICY "Allow authenticated insert on activities" ON public.activities
    FOR INSERT TO authenticated WITH CHECK (true);

-- 3. Allow authenticated update
CREATE POLICY "Allow authenticated update on activities" ON public.activities
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- 4. Allow authenticated delete
CREATE POLICY "Allow authenticated delete on activities" ON public.activities
    FOR DELETE TO authenticated USING (true);

-- Seed activities data mapped to current subgroup and user IDs
-- Technojam: c24465ff-6359-47d2-9aad-a0689e25c3a1 (Lead ID: 4d07b6e7-a5a3-4287-aeb9-3a1a1557472c)
-- Lingofreaks: f5969367-1d64-446f-baad-5d094e069a23 (Lead ID: ded15c57-cbea-443d-826a-f0e636c84421)
INSERT INTO public.activities (id, type, title, description, date, location, subgroup_id, posted_by, created_at) VALUES 
('2b58713e-0899-4621-adba-65e2b5614686', 'Announcement', 'Club Update', 'Hey Everyone! Thank you for being a part of our club. We have some exciting activities and opportunities coming soon. Keep checking the app for updates and don''t miss out on upcoming events. Looking forward to seeing your active participation!', '2026-06-17 04:30:54.976+05:30', null, 'c24465ff-6359-47d2-9aad-a0689e25c3a1', '4d07b6e7-a5a3-4287-aeb9-3a1a1557472c', '2026-06-17 04:31:38.534+05:30'), 
('4ae74456-cb49-4d79-bc58-bd2a4b769afe', 'Announcement', '🎉 Welcome to the Club!', 'We are delighted to have you as part of our community. This platform will be used to share updates, events, opportunities, and important announcements. Stay connected, stay engaged, and let''s make this club a great place for everyone!', '2026-06-17 04:34:45.117+05:30', null, 'f5969367-1d64-446f-baad-5d094e069a23', 'ded15c57-cbea-443d-826a-f0e636c84421', '2026-06-17 04:35:10.472+05:30'), 
('80ec79ac-fbb7-4579-8586-c3fe478a2232', 'Meeting', 'Core Committee Sync', 'Weekly sync to discuss logistics.', '2026-04-27 04:43:15.345157+05:30', 'Conference Room A', 'c24465ff-6359-47d2-9aad-a0689e25c3a1', '4d07b6e7-a5a3-4287-aeb9-3a1a1557472c', '2026-04-27 02:43:15.345157+05:30'), 
('d0740d9b-cf04-44f5-8053-3d00a1894873', 'Meeting', 'Team meeting', 'We have arranged a meeting to discuss the upcoming events and plans for the club. All members are requested to join and share their ideas and suggestions.', '2026-06-20 03:49:00+05:30', null, 'c24465ff-6359-47d2-9aad-a0689e25c3a1', '4d07b6e7-a5a3-4287-aeb9-3a1a1557472c', '2026-06-17 03:49:34.825+05:30')
ON CONFLICT (id) DO NOTHING;
