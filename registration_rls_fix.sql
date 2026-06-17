-- =============================================
-- ClubIt Event Registration — RLS Fix
-- =============================================
-- Run this in your Supabase SQL Editor to fix
-- the RLS policies that block deleting registrations.
-- =============================================

-- Drop existing restrictive DELETE policy if any
DROP POLICY IF EXISTS "registration_delete" ON public.registrations;
DROP POLICY IF EXISTS "Users can delete their own registrations" ON public.registrations;

-- Recreate policy for DELETE
CREATE POLICY "registration_delete" ON public.registrations
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- While we are at it, ensure SELECT, INSERT, UPDATE are permissive
DROP POLICY IF EXISTS "registration_select" ON public.registrations;
CREATE POLICY "registration_select" ON public.registrations
    FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "registration_insert" ON public.registrations;
CREATE POLICY "registration_insert" ON public.registrations
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "registration_update" ON public.registrations;
CREATE POLICY "registration_update" ON public.registrations
    FOR UPDATE USING (auth.uid() IS NOT NULL);
