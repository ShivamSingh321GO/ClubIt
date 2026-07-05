-- Create ENUM for entity types to ensure data integrity
CREATE TYPE approval_entity_type AS ENUM ('organization', 'group', 'subgroup');

-- Create ENUM for assignee roles
CREATE TYPE approval_assignee_role AS ENUM ('approver', 'viewer');

-- ==========================================
-- 1. Approval Flows Table
-- Defines if a category is enabled for an entity
-- ==========================================
CREATE TABLE public.approval_flows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type approval_entity_type NOT NULL,
    entity_id UUID NOT NULL, -- The ID of the Org, Group, or Subgroup
    category TEXT NOT NULL,  -- e.g., 'Events', 'Resources', 'Venue', 'Budget'
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Ensure we only have one flow configuration per category for a specific entity
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

CREATE TRIGGER update_approval_flows_modtime
BEFORE UPDATE ON public.approval_flows
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- ==========================================
-- 2. Approval Flow Assignees Table
-- Maps the users (approvers & viewers) to the flow
-- ==========================================
CREATE TABLE public.approval_flow_assignees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flow_id UUID NOT NULL REFERENCES public.approval_flows(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role_type approval_assignee_role NOT NULL,
    sequence_order INT, -- Used for 'approver' to define strict sequential order (1, 2, 3...)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Ensure a user isn't assigned twice to the exact same flow with the same role
    CONSTRAINT unique_flow_user_role UNIQUE (flow_id, user_id, role_type)
);

-- ==========================================
-- 3. Row Level Security (RLS)
-- ==========================================
ALTER TABLE public.approval_flows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approval_flow_assignees ENABLE ROW LEVEL SECURITY;

-- Allow read access to all authenticated users
CREATE POLICY "Allow authenticated users to read approval flows" 
ON public.approval_flows FOR SELECT 
TO authenticated USING (true);

CREATE POLICY "Allow authenticated users to read flow assignees" 
ON public.approval_flow_assignees FOR SELECT 
TO authenticated USING (true);

-- Allow insert/update/delete based on superadmin roles 
-- (You will need to adjust the USING clause based on how you identify admins in your DB)
CREATE POLICY "Allow admins to manage approval flows" 
ON public.approval_flows FOR ALL 
TO authenticated 
USING (true); -- REPLACE 'true' with your admin check condition

CREATE POLICY "Allow admins to manage flow assignees" 
ON public.approval_flow_assignees FOR ALL 
TO authenticated 
USING (true); -- REPLACE 'true' with your admin check condition
