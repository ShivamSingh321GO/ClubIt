-- Add socials column to subgroups table
ALTER TABLE public.subgroups ADD COLUMN IF NOT EXISTS socials jsonb DEFAULT '{}'::jsonb;

-- Update Technojam socials
UPDATE public.subgroups
SET socials = '{"discord":"https://discord.gg/","facebook":"https://facebook.com/","linkedin":"https://linkedin.com/","instagram":"https://instagram.com/","whatsapp":"https://wa.me/"}'::jsonb
WHERE name = 'Technojam';

-- Update Lingofreaks socials
UPDATE public.subgroups
SET socials = '{"discord":"https://discord.gg/","facebook":"https://facebook.com/","linkedin":"https://linkedin.com/","instagram":"https://instagram.com/","whatsapp":"https://wa.me/"}'::jsonb
WHERE name = 'Lingofreaks';
