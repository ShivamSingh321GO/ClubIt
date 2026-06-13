-- 1. Create a public bucket for userProfile-images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('userProfile-images', 'userProfile-images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Define Storage Security Policies (RLS) on storage.objects for this specific bucket
CREATE POLICY "Public Read Access for User Profile Images" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'userProfile-images');

CREATE POLICY "Authenticated Upload Access for User Profile Images" ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'userProfile-images');

CREATE POLICY "Authenticated Update Access for User Profile Images" ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'userProfile-images');

CREATE POLICY "Authenticated Delete Access for User Profile Images" ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'userProfile-images');
