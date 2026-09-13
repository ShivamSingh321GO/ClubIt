-- =============================================
-- Fix RLS Policies for public.organizations Table
-- =============================================
-- Run this script in your Supabase SQL Editor.
-- This ensures authenticated users (and admin dashboard)
-- can SELECT and UPDATE organization feature modules.
-- =============================================

-- 1. Ensure RLS is enabled
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- 2. Drop any existing restrictive policies
DROP POLICY IF EXISTS "Allow read access to organizations" ON public.organizations;
DROP POLICY IF EXISTS "Allow update access to organizations" ON public.organizations;
DROP POLICY IF EXISTS "Allow all access to organizations" ON public.organizations;
DROP POLICY IF EXISTS "organizations_select" ON public.organizations;
DROP POLICY IF EXISTS "organizations_insert" ON public.organizations;
DROP POLICY IF EXISTS "organizations_update" ON public.organizations;
DROP POLICY IF EXISTS "organizations_delete" ON public.organizations;

-- 3. Create permissive policies for organizations table
CREATE POLICY "organizations_select" ON public.organizations
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "organizations_insert" ON public.organizations
    FOR INSERT TO authenticated, anon WITH CHECK (true);

CREATE POLICY "organizations_update" ON public.organizations
    FOR UPDATE TO authenticated, anon USING (true) WITH CHECK (true);

CREATE POLICY "organizations_delete" ON public.organizations
    FOR DELETE TO authenticated, anon USING (true);

-- 4. Enable Supabase Realtime for organizations table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'organizations'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.organizations;
    END IF;
END $$;

-- 5. Verification: Check that policies exist
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'organizations'
ORDER BY policyname;
