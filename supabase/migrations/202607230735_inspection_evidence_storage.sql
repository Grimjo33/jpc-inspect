insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('inspection-evidence','inspection-evidence',false,10485760,array['image/jpeg','image/png','application/pdf'])
on conflict (id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

create policy "authenticated read inspection evidence" on storage.objects for select to authenticated using (bucket_id = 'inspection-evidence');
create policy "authenticated upload own inspection evidence" on storage.objects for insert to authenticated with check (bucket_id = 'inspection-evidence' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "owners update inspection evidence" on storage.objects for update to authenticated using (bucket_id = 'inspection-evidence' and owner_id = (select auth.uid())::text) with check (bucket_id = 'inspection-evidence' and owner_id = (select auth.uid())::text);
create policy "owners delete inspection evidence" on storage.objects for delete to authenticated using (bucket_id = 'inspection-evidence' and owner_id = (select auth.uid())::text);
