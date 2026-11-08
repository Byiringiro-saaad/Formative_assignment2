-- Public-read bucket for incident photos, images only, max 5 MB.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('incident-photos', 'incident-photos', true, 5242880, array['image/jpeg','image/png','image/webp','image/heic'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

-- True only for a valid Firebase ID token from our project, belonging to a
-- verified ALU account (the same check as the Firestore rules).
create or replace function public.is_campus_firebase_user() returns boolean
language sql stable as $$
  select coalesce(auth.jwt() ->> 'iss', '') = 'https://securetoken.google.com/campus-incidents-saad-b5923'
     and coalesce(auth.jwt() ->> 'aud', '') = 'campus-incidents-saad-b5923'
     and coalesce(auth.jwt() ->> 'sub', '') <> ''
     and coalesce(auth.jwt() ->> 'email_verified', 'false') = 'true'
     and lower(coalesce(auth.jwt() ->> 'email', '')) ~ '@(alustudent|alueducation)\.com$'
$$;

drop policy if exists "campus: firebase users upload to own folder" on storage.objects;
create policy "campus: firebase users upload to own folder" on storage.objects
  for insert to anon, authenticated
  with check (
    bucket_id = 'incident-photos'
    and public.is_campus_firebase_user()
    and (storage.foldername(name))[1] = auth.jwt() ->> 'sub'
  );

drop policy if exists "campus: firebase users delete own photos" on storage.objects;
create policy "campus: firebase users delete own photos" on storage.objects
  for delete to anon, authenticated
  using (
    bucket_id = 'incident-photos'
    and public.is_campus_firebase_user()
    and (storage.foldername(name))[1] = auth.jwt() ->> 'sub'
  );

drop policy if exists "campus: firebase users list own photos" on storage.objects;
create policy "campus: firebase users list own photos" on storage.objects
  for select to anon, authenticated
  using (
    bucket_id = 'incident-photos'
    and public.is_campus_firebase_user()
    and (storage.foldername(name))[1] = auth.jwt() ->> 'sub'
  );
