-- 1. Create enum types if they do not exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'approval_entity_type') THEN
        CREATE TYPE approval_entity_type AS ENUM ('organization', 'group', 'subgroup');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'approval_assignee_role') THEN
        CREATE TYPE approval_assignee_role AS ENUM ('approver', 'viewer');
    END IF;
END$$;

-- 2. Create approval_flows configuration table
CREATE TABLE IF NOT EXISTS public.approval_flows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type approval_entity_type NOT NULL,
    entity_id UUID NOT NULL,
    category TEXT NOT NULL, -- e.g., 'Events', 'Resources', 'Venue', 'Budget'
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_entity_category UNIQUE (entity_type, entity_id, category)
);

-- Trigger to auto-update updated_at on modification
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_approval_flows_modtime ON public.approval_flows;
CREATE TRIGGER update_approval_flows_modtime
BEFORE UPDATE ON public.approval_flows
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 3. Create approval_flow_assignees table
CREATE TABLE IF NOT EXISTS public.approval_flow_assignees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flow_id UUID NOT NULL REFERENCES public.approval_flows(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role_type approval_assignee_role NOT NULL,
    sequence_order INT, -- Used for 'approver' to define strict sequential order (1, 2, 3...)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_flow_user_role UNIQUE (flow_id, user_id, role_type)
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.approval_flows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approval_flow_assignees ENABLE ROW LEVEL SECURITY;

-- 5. Define policies (allow reads to all authenticated users, allow full access to authenticated users to manage configurations)
DROP POLICY IF EXISTS "Allow authenticated users to read approval flows" ON public.approval_flows;
CREATE POLICY "Allow authenticated users to read approval flows" 
ON public.approval_flows FOR SELECT 
TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to read flow assignees" ON public.approval_flow_assignees;
CREATE POLICY "Allow authenticated users to read flow assignees" 
ON public.approval_flow_assignees FOR SELECT 
TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow admins to manage approval flows" ON public.approval_flows;
CREATE POLICY "Allow admins to manage approval flows" 
ON public.approval_flows FOR ALL 
TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow admins to manage flow assignees" ON public.approval_flow_assignees;
CREATE POLICY "Allow admins to manage flow assignees" 
ON public.approval_flow_assignees FOR ALL 
TO authenticated USING (true);
