create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, department, role)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'full_name',''), split_part(coalesce(new.email,''),'@',1), 'Pengguna'),
    nullif(new.raw_user_meta_data->>'department',''),
    case when lower(coalesce(new.email,'')) = 'rahmat.wira.dafitra@jambiprimacoal.co.id' then 'admin'::public.app_role else 'viewer'::public.app_role end
  )
  on conflict (id) do update set full_name = excluded.full_name, updated_at = now();
  return new;
end;
$$;
revoke all on function public.handle_new_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
