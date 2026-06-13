-- 1. Create a public bucket for club-images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('club-images', 'club-images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Define Storage Security Policies (RLS) on storage.objects
CREATE POLICY "Public Read Access" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'club-images');

CREATE POLICY "Authenticated Upload Access" ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'club-images');

CREATE POLICY "Authenticated Delete Access" ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'club-images');

-- 3. Create the club_images table to track image metadata
CREATE TABLE public.club_images (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  club_id uuid NOT NULL,
  event_id uuid,
  type text NOT NULL DEFAULT 'image',
  title text NOT NULL,
  file_url text NOT NULL,
  uploaded_by uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT club_images_pkey PRIMARY KEY (id),
  CONSTRAINT club_images_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id) ON DELETE CASCADE,
  CONSTRAINT club_images_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id) ON DELETE CASCADE
);

-- 4. Enable Row Level Security (RLS) on public.club_images
ALTER TABLE public.club_images ENABLE ROW LEVEL SECURITY;

-- 5. Define policies for the public.club_images table
CREATE POLICY "Allow public select on club_images" ON public.club_images
  FOR SELECT USING (true);

CREATE POLICY "Allow authenticated insert on club_images" ON public.club_images
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow authenticated update on club_images" ON public.club_images
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Allow authenticated delete on club_images" ON public.club_images
  FOR DELETE TO authenticated USING (true);
