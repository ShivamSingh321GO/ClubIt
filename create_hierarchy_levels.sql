CREATE TABLE public.hierarchy_levels (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id UUID NOT NULL,
    level_number INT NOT NULL,
    level_name VARCHAR(255) NOT NULL,
    is_enabled BOOLEAN DEFAULT true,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT hierarchy_levels_org_level_key UNIQUE (organization_id, level_number)
);

-- Note: Since the app currently doesn't enforce a specific organization structure, 
-- you might want to insert a default set of rows right now so the app has something to load.
-- Here is an optional query to insert the default 5 levels for a dummy organization ID.
-- Replace the UUIDs with your actual org/superadmin IDs if you have them.

/*
INSERT INTO public.hierarchy_levels (organization_id, level_number, level_name, is_enabled) VALUES
('00000000-0000-0000-0000-000000000000', 1, 'Groups', true),
('00000000-0000-0000-0000-000000000000', 2, 'Subgroups', true),
('00000000-0000-0000-0000-000000000000', 3, 'Nested Subgroups', true),
('00000000-0000-0000-0000-000000000000', 4, 'Teams', false),
('00000000-0000-0000-0000-000000000000', 5, 'Level 5', false);
*/
