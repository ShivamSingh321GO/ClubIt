-- Create a new storage bucket for event images
insert into storage.buckets (id, name, public)
values ('event-images', 'event-images', true)
on conflict (id) do nothing;

-- Drop existing policies if any
drop policy if exists "Authenticated users can upload" on storage.objects;
drop policy if exists "Public Access For Events" on storage.objects;

-- Create policy for uploading images
create policy "Authenticated users can upload"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'event-images' );

-- Create policy for public access to images
create policy "Public Access For Events"
on storage.objects for select
to public
using ( bucket_id = 'event-images' );
