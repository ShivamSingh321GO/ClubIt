-- Create subgroup_links table linked to subgroups
CREATE TABLE IF NOT EXISTS public.subgroup_links (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  subgroup_id uuid NOT NULL,
  name character varying NOT NULL,
  url character varying NOT NULL,
  uploaded_by character varying NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT subgroup_links_pkey PRIMARY KEY (id),
  CONSTRAINT subgroup_links_subgroup_id_fkey FOREIGN KEY (subgroup_id) REFERENCES public.subgroups(id) ON DELETE CASCADE
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.subgroup_links ENABLE ROW LEVEL SECURITY;

-- 1. Allow public select (anyone can view subgroup links)
CREATE POLICY "Allow public select on subgroup_links" ON public.subgroup_links
    FOR SELECT TO public USING (true);

-- 2. Allow authenticated insert
CREATE POLICY "Allow authenticated insert on subgroup_links" ON public.subgroup_links
    FOR INSERT TO authenticated WITH CHECK (true);

-- 3. Allow authenticated update
CREATE POLICY "Allow authenticated update on subgroup_links" ON public.subgroup_links
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- 4. Allow authenticated delete
CREATE POLICY "Allow authenticated delete on subgroup_links" ON public.subgroup_links
    FOR DELETE TO authenticated USING (true);

-- Seed subgroup links data mapped to Technojam subgroup: c24465ff-6359-47d2-9aad-a0689e25c3a1
INSERT INTO public.subgroup_links (id, subgroup_id, name, url, uploaded_by, created_at) VALUES 
('e23e421d-c82a-47b3-95f0-ed6ea745aa39', 'c24465ff-6359-47d2-9aad-a0689e25c3a1', 'Something', 'https://something.com', 'TechnoJam Sub Group Lead', '2026-07-05 23:15:51.079454+05:30')
ON CONFLICT (id) DO NOTHING;
