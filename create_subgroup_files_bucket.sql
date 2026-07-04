-- 1. Create a public bucket for subgroup-files
INSERT INTO storage.buckets (id, name, public) 
VALUES ('subgroup-files', 'subgroup-files', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Define Storage Security Policies (RLS) on storage.objects for subgroup-files
CREATE POLICY "Public Read Access for Subgroup Files" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'subgroup-files');

CREATE POLICY "Authenticated Upload Access for Subgroup Leads" 
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id = 'subgroup-files');

CREATE POLICY "Delete Access for Subgroup Leads" 
ON storage.objects FOR DELETE 
TO authenticated 
USING (bucket_id = 'subgroup-files');
