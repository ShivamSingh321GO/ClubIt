-- 1. Create a public bucket for club-files
INSERT INTO storage.buckets (id, name, public) 
VALUES ('club-files', 'club-files', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Define Storage Security Policies (RLS) on storage.objects for club-files
CREATE POLICY "Public Read Access for Club Files" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'club-files');

CREATE POLICY "Authenticated Upload Access for Club Leads" 
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id = 'club-files');

CREATE POLICY "Delete Access for Club Leads" 
ON storage.objects FOR DELETE 
TO authenticated 
USING (bucket_id = 'club-files');
