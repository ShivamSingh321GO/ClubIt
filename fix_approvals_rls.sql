-- =============================================
-- ClubIt Approvals RLS Fix & Verification
-- =============================================
-- Run this in your Supabase SQL Editor to ensure
-- all approval-related tables have proper RLS policies
-- that allow all authenticated users to read all data.
-- =============================================

-- 1. Drop any existing restrictive policies on approvals
DROP POLICY IF EXISTS "Allow read access to approvals" ON public.approvals;
DROP POLICY IF EXISTS "Allow all access to approvals" ON public.approvals;
DROP POLICY IF EXISTS "approvals_select" ON public.approvals;
DROP POLICY IF EXISTS "approvals_insert" ON public.approvals;
DROP POLICY IF EXISTS "approvals_update" ON public.approvals;
DROP POLICY IF EXISTS "approvals_delete" ON public.approvals;

-- 2. Drop any existing restrictive policies on budgets
DROP POLICY IF EXISTS "Allow read access to budgets" ON public.budgets;
DROP POLICY IF EXISTS "Allow all access to budgets" ON public.budgets;
DROP POLICY IF EXISTS "budgets_select" ON public.budgets;
DROP POLICY IF EXISTS "budgets_insert" ON public.budgets;
DROP POLICY IF EXISTS "budgets_update" ON public.budgets;
DROP POLICY IF EXISTS "budgets_delete" ON public.budgets;

-- 3. Drop any existing restrictive policies on resources
DROP POLICY IF EXISTS "Allow read access to resources" ON public.resources;
DROP POLICY IF EXISTS "Allow all access to resources" ON public.resources;
DROP POLICY IF EXISTS "resources_select" ON public.resources;
DROP POLICY IF EXISTS "resources_insert" ON public.resources;
DROP POLICY IF EXISTS "resources_update" ON public.resources;
DROP POLICY IF EXISTS "resources_delete" ON public.resources;

-- 4. Drop any existing restrictive policies on events
DROP POLICY IF EXISTS "Allow read access to events" ON public.events;
DROP POLICY IF EXISTS "Allow all access to events" ON public.events;
DROP POLICY IF EXISTS "events_select" ON public.events;
DROP POLICY IF EXISTS "events_insert" ON public.events;
DROP POLICY IF EXISTS "events_update" ON public.events;
DROP POLICY IF EXISTS "events_delete" ON public.events;

-- 5. Drop any existing restrictive policies on remarks
DROP POLICY IF EXISTS "Allow read access to remarks" ON public.remarks;
DROP POLICY IF EXISTS "Allow all access to remarks" ON public.remarks;

-- =============================================
-- Ensure RLS is enabled on all tables
-- =============================================
ALTER TABLE public.approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.remarks ENABLE ROW LEVEL SECURITY;

-- =============================================
-- Recreate permissive policies for ALL operations
-- =============================================

-- APPROVALS
CREATE POLICY "approvals_select" ON public.approvals
    FOR SELECT TO authenticated USING (true);
CREATE POLICY "approvals_insert" ON public.approvals
    FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "approvals_update" ON public.approvals
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "approvals_delete" ON public.approvals
    FOR DELETE TO authenticated USING (true);

-- BUDGETS
CREATE POLICY "budgets_select" ON public.budgets
    FOR SELECT TO authenticated USING (true);
CREATE POLICY "budgets_insert" ON public.budgets
    FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "budgets_update" ON public.budgets
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "budgets_delete" ON public.budgets
    FOR DELETE TO authenticated USING (true);

-- RESOURCES
CREATE POLICY "resources_select" ON public.resources
    FOR SELECT TO authenticated USING (true);
CREATE POLICY "resources_insert" ON public.resources
    FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "resources_update" ON public.resources
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "resources_delete" ON public.resources
    FOR DELETE TO authenticated USING (true);

-- EVENTS
CREATE POLICY "events_select" ON public.events
    FOR SELECT TO authenticated USING (true);
CREATE POLICY "events_insert" ON public.events
    FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "events_update" ON public.events
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "events_delete" ON public.events
    FOR DELETE TO authenticated USING (true);

-- REMARKS
CREATE POLICY "remarks_select" ON public.remarks
    FOR SELECT TO authenticated USING (true);
CREATE POLICY "remarks_insert" ON public.remarks
    FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "remarks_update" ON public.remarks
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "remarks_delete" ON public.remarks
    FOR DELETE TO authenticated USING (true);

-- =============================================
-- Verification: Check that policies were created
-- =============================================
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('approvals', 'budgets', 'resources', 'events', 'remarks')
ORDER BY tablename, policyname;
