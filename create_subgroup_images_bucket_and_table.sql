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
