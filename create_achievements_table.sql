-- Create achievements table linked to subgroups
CREATE TABLE IF NOT EXISTS public.achievements (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  subgroup_id uuid NOT NULL,
  title character varying NOT NULL,
  description text NOT NULL,
  type character varying NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT achievements_pkey PRIMARY KEY (id),
  CONSTRAINT achievements_subgroup_id_fkey FOREIGN KEY (subgroup_id) REFERENCES public.subgroups(id) ON DELETE CASCADE
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

-- 1. Allow public select (anyone can view achievements)
CREATE POLICY "Allow public select on achievements" ON public.achievements
    FOR SELECT TO public USING (true);

-- 2. Allow authenticated insert
CREATE POLICY "Allow authenticated insert on achievements" ON public.achievements
    FOR INSERT TO authenticated WITH CHECK (true);

-- 3. Allow authenticated update
CREATE POLICY "Allow authenticated update on achievements" ON public.achievements
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- 4. Allow authenticated delete
CREATE POLICY "Allow authenticated delete on achievements" ON public.achievements
    FOR DELETE TO authenticated USING (true);

-- Seed achievements data mapped to current subgroup IDs
-- Technojam: c24465ff-6359-47d2-9aad-a0689e25c3a1
-- Lingofreaks: f5969367-1d64-446f-baad-5d094e069a23
INSERT INTO public.achievements (id, subgroup_id, title, description, type, created_at) VALUES 
('4f788f0f-e038-40cd-8d53-919519bf8b31', 'c24465ff-6359-47d2-9aad-a0689e25c3a1', 'Global Recognition', 'Our Club was in news on BBC yesterday', 'recognition', '2026-06-13 17:42:32.158+05:30'), 
('9ce604d9-f051-4a3f-8791-fdf5ed0f7278', 'c24465ff-6359-47d2-9aad-a0689e25c3a1', 'Best club of the Year', 'In 2026 , Our club was awarded with the best club of the year. Thanks to everyone who worked for it.', 'award', '2026-06-13 16:56:15.349+05:30'), 
('d30183dc-add1-4774-8b0b-4b567c418471', 'f5969367-1d64-446f-baad-5d094e069a23', 'Highest number of Members', 'Out club LF has been declared as the highest number of active members in recent survey.', 'milestone', '2026-06-13 17:19:17.904+05:30'), 
('d514c247-1956-4759-a165-32eaefb0c549', 'c24465ff-6359-47d2-9aad-a0689e25c3a1', 'Best limitless club', 'Hey', 'recognition', '2026-06-13 17:46:21.831+05:30')
ON CONFLICT (id) DO NOTHING;
