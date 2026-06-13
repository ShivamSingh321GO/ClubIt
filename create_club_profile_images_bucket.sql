-- 1. Create a public bucket for club-profile-images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('clubProfile-images', 'clubProfile-images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Define Storage Security Policies (RLS) on storage.objects for this specific bucket
CREATE POLICY "Public Read Access for Club Profile Images" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'clubProfile-images');

CREATE POLICY "Authenticated Upload Access for Club Profile Images" ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'clubProfile-images');

CREATE POLICY "Authenticated Update Access for Club Profile Images" ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'clubProfile-images');

CREATE POLICY "Authenticated Delete Access for Club Profile Images" ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'clubProfile-images');
