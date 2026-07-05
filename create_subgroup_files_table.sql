-- 1. Create the public storage bucket for subgroup-files if not already created
INSERT INTO storage.buckets (id, name, public) 
VALUES ('subgroup-files', 'subgroup-files', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Define Storage Security Policies (RLS) on storage.objects for subgroup-files
CREATE POLICY "Public Read Access for Subgroup Files" 
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'subgroup-files');

CREATE POLICY "Authenticated Upload Access for Subgroup Leads" 
ON storage.objects FOR INSERT TO authenticated 
WITH CHECK (bucket_id = 'subgroup-files');

CREATE POLICY "Delete Access for Subgroup Leads" 
ON storage.objects FOR DELETE TO authenticated 
USING (bucket_id = 'subgroup-files');


-- 3. Create subgroup_files metadata table
CREATE TABLE IF NOT EXISTS public.subgroup_files (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  subgroup_id uuid NOT NULL,
  name character varying NOT NULL,
  size character varying NOT NULL,
  uploaded_by character varying NOT NULL,
  file_url text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT subgroup_files_pkey PRIMARY KEY (id),
  CONSTRAINT subgroup_files_subgroup_id_fkey FOREIGN KEY (subgroup_id) REFERENCES public.subgroups(id) ON DELETE CASCADE
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.subgroup_files ENABLE ROW LEVEL SECURITY;

-- 1. Allow public select (anyone can view subgroup files)
CREATE POLICY "Allow public select on subgroup_files" ON public.subgroup_files
    FOR SELECT TO public USING (true);

-- 2. Allow authenticated insert
CREATE POLICY "Allow authenticated insert on subgroup_files" ON public.subgroup_files
    FOR INSERT TO authenticated WITH CHECK (true);

-- 3. Allow authenticated update
CREATE POLICY "Allow authenticated update on subgroup_files" ON public.subgroup_files
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- 4. Allow authenticated delete
CREATE POLICY "Allow authenticated delete on subgroup_files" ON public.subgroup_files
    FOR DELETE TO authenticated USING (true);

-- Seed subgroup files data mapped to Technojam: c24465ff-6359-47d2-9aad-a0689e25c3a1
INSERT INTO public.subgroup_files (id, subgroup_id, name, size, uploaded_by, file_url, created_at) VALUES 
('82b0f5c6-6344-439d-b113-72c0d0d2793e', 'c24465ff-6359-47d2-9aad-a0689e25c3a1', 'Kamakshi_Chat_Testing_Participants_Numbers_Jun_17_145841.csv', '225 bytes', 'Aryan', 'https://cinczbuomasxdspvvhcd.supabase.co/storage/v1/object/public/subgroup-files/c24465ff-6359-47d2-9aad-a0689e25c3a1/82b0f5c6-6344-439d-b113-72c0d0d2793e_Kamakshi_Chat_Testing_Participants_Numbers_Jun_17_145841.csv', '2026-06-17 09:39:23.087+05:30'), 
('d5b2f5a5-328f-4644-94c6-8ef73213faed', 'c24465ff-6359-47d2-9aad-a0689e25c3a1', 'Andy.png', '18.8 MB', 'Kavya', 'https://cinczbuomasxdspvvhcd.supabase.co/storage/v1/object/public/subgroup-files/c24465ff-6359-47d2-9aad-a0689e25c3a1/d5b2f5a5-328f-4644-94c6-8ef73213faed_Andy.png', '2026-06-13 15:28:49.912+05:30')
ON CONFLICT (id) DO NOTHING;
