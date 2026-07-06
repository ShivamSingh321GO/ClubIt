-- Drop existing tasks table if it exists
DROP TABLE IF EXISTS public.tasks CASCADE;

-- Create the new tasks table based on the new generic structure
CREATE TABLE public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subgroup_id UUID NOT NULL,
    target_subgroup_id UUID,
    event_id UUID,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    assigned_by UUID NOT NULL,
    assigned_by_role TEXT NOT NULL,
    assigned_to UUID NOT NULL,
    assigned_to_role TEXT NOT NULL,
    delegated_to_id UUID,
    deadline TIMESTAMPTZ NOT NULL,
    priority TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger to auto-update updated_at on modification
CREATE OR REPLACE FUNCTION update_tasks_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_tasks_modtime ON public.tasks;
CREATE TRIGGER update_tasks_modtime
    BEFORE UPDATE ON public.tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_tasks_modified_column();

-- Enable Row Level Security
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies for now (can be tightened later)
CREATE POLICY "Enable read access for all authenticated users" 
ON public.tasks FOR SELECT 
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Enable insert for authenticated users" 
ON public.tasks FOR INSERT 
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Enable update for authenticated users" 
ON public.tasks FOR UPDATE 
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Enable delete for authenticated users" 
ON public.tasks FOR DELETE 
USING (auth.uid() IS NOT NULL);
