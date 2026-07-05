-- 1. Create a public bucket for subgroup-images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('subgroup-images', 'subgroup-images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Define Storage Security Policies (RLS) on storage.objects
CREATE POLICY "Public Read Access" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'subgroup-images');

CREATE POLICY "Authenticated Upload Access" ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'subgroup-images');

CREATE POLICY "Authenticated Delete Access" ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'subgroup-images');

-- 3. Create the subgroup_images table to track image metadata
CREATE TABLE public.subgroup_images (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  subgroup_id uuid NOT NULL,
  event_id uuid,
  type text NOT NULL DEFAULT 'image',
  title text NOT NULL,
  file_url text NOT NULL,
  uploaded_by uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT subgroup_images_pkey PRIMARY KEY (id),
  CONSTRAINT subgroup_images_subgroup_id_fkey FOREIGN KEY (subgroup_id) REFERENCES public.subgroups(id) ON DELETE CASCADE,
  CONSTRAINT subgroup_images_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id) ON DELETE CASCADE
);

-- 4. Enable Row Level Security (RLS) on public.subgroup_images
ALTER TABLE public.subgroup_images ENABLE ROW LEVEL SECURITY;

-- 5. Define policies for the public.subgroup_images table
CREATE POLICY "Allow public select on subgroup_images" ON public.subgroup_images
  FOR SELECT USING (true);

CREATE POLICY "Allow authenticated insert on subgroup_images" ON public.subgroup_images
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow authenticated update on subgroup_images" ON public.subgroup_images
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Allow authenticated delete on subgroup_images" ON public.subgroup_images
  FOR DELETE TO authenticated USING (true);

-- Seed subgroup images data mapped to current project details
-- Technojam Subgroup: c24465ff-6359-47d2-9aad-a0689e25c3a1
-- Uploaded by: 4d07b6e7-a5a3-4287-aeb9-3a1a1557472c
INSERT INTO public.subgroup_images (id, subgroup_id, event_id, type, title, file_url, uploaded_by, created_at) VALUES 
('00586f45-b84e-451a-9978-69145af98351', 'c24465ff-6359-47d2-9aad-a0689e25c3a1', null, 'image', 'Sports', 'https://cinczbuomasxdspvvhcd.supabase.co/storage/v1/object/public/subgroup-images/C24465FF-6359-47D2-9AAD-A0689e25c3a1/00586F45-B84E-451A-9978-69145AF98351.jpg', '4d07b6e7-a5a3-4287-aeb9-3a1a1557472c', '2026-06-25 08:20:28.533+05:30'), 
('02774278-3348-469d-8d13-8b3f39e4d0c4', 'c24465ff-6359-47d2-9aad-a0689e25c3a1', null, 'image', 'Knob', 'https://cinczbuomasxdspvvhcd.supabase.co/storage/v1/object/public/subgroup-images/C24465FF-6359-47D2-9AAD-A0689e25c3a1/02774278-3348-469D-8D13-8B3F39E4D0C4.jpg', '4d07b6e7-a5a3-4287-aeb9-3a1a1557472c', '2026-06-25 08:16:57.807+05:30'), 
('3abb8eff-dc95-4501-87f7-fedfbfb853c6', 'c24465ff-6359-47d2-9aad-a0689e25c3a1', null, 'image', 'Knob', 'https://cinczbuomasxdspvvhcd.supabase.co/storage/v1/object/public/subgroup-images/C24465FF-6359-47D2-9AAD-A0689e25c3a1/3ABB8EFF-DC95-4501-87F7-FEDFBFB853C6.jpg', '4d07b6e7-a5a3-4287-aeb9-3a1a1557472c', '2026-06-25 08:17:05.179+05:30'), 
('518e346e-9e99-489a-9ae5-1e4c060c32d9', 'c24465ff-6359-47d2-9aad-a0689e25c3a1', null, 'image', 'Knob', 'https://cinczbuomasxdspvvhcd.supabase.co/storage/v1/object/public/subgroup-images/C24465FF-6359-47D2-9AAD-A0689e25c3a1/518E346E-9E99-489A-9AE5-1E4C060C32D9.jpg', '4d07b6e7-a5a3-4287-aeb9-3a1a1557472c', '2026-06-25 08:17:00.783+05:30')
ON CONFLICT (id) DO NOTHING;
