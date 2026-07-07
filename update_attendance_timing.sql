-- 1. Add timing_status column with Check Constraint to public.attendance table
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS timing_status TEXT CHECK (timing_status IN ('before', 'during', 'after', 'unknown'));

-- 2. Create the trigger function to dynamically compute timing_status on insert
CREATE OR REPLACE FUNCTION public.populate_attendance_timing_status()
RETURNS TRIGGER AS $$
DECLARE
    v_start_date TIMESTAMPTZ;
    v_end_date TIMESTAMPTZ;
    v_check_time TIMESTAMPTZ;
BEGIN
    -- Use entry_time if set, otherwise default to created_at or current time
    v_check_time := COALESCE(NEW.entry_time, NEW.created_at, NOW());
    
    -- Try to find the event in the public.events table
    SELECT start_date, end_date INTO v_start_date, v_end_date
    FROM public.events
    WHERE id = NEW.event_id;
    
    -- If not found, try to find the event in the public.group_events table
    IF v_start_date IS NULL THEN
        SELECT start_date, end_date INTO v_start_date, v_end_date
        FROM public.group_events
        WHERE id = NEW.event_id;
    END IF;
    
    -- Set status based on comparison of check_time and event timing bounds
    IF v_start_date IS NOT NULL THEN
        IF v_check_time < v_start_date THEN
            NEW.timing_status := 'before';
        ELSIF v_check_time >= v_start_date AND v_check_time <= v_end_date THEN
            NEW.timing_status := 'during';
        ELSE
            NEW.timing_status := 'after';
        END IF;
    ELSE
        NEW.timing_status := 'unknown';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Associate the trigger function with the public.attendance table
DROP TRIGGER IF EXISTS trg_populate_attendance_timing_status ON public.attendance;

CREATE TRIGGER trg_populate_attendance_timing_status
BEFORE INSERT ON public.attendance
FOR EACH ROW
EXECUTE FUNCTION public.populate_attendance_timing_status();
