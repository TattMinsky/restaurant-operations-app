-- Gold Star multi-location access and activity audit schema
-- Run in Supabase SQL Editor as project owner. Safe to run once; uses IF NOT EXISTS.
create table if not exists public.app_locations (
 id text primary key check (id in ('western-hills','groesbeck','alexandria')),
 slug text unique not null,
 name text not null,
 active boolean not null default true
);
insert into public.app_locations(id,slug,name) values
 ('western-hills','western-hills','Western Hills'),
 ('groesbeck','groesbeck','Groesbeck'),
 ('alexandria','alexandria','Alexandria')
on conflict (id) do update set slug=excluded.slug,name=excluded.name;

create table if not exists public.app_user_access (
 user_id uuid primary key references auth.users(id) on delete cascade,
 role text not null check (role in ('corporate','gm','shift_lead')),
 location_id text references public.app_locations(id),
 active boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint corporate_no_location check ((role='corporate' and location_id is null) or (role<>'corporate' and location_id is not null))
);
create table if not exists public.app_activity_records (
 id bigint generated always as identity primary key,
 location_id text not null references public.app_locations(id),
 actor_id uuid not null references auth.users(id),
 event_type text not null,
 payload jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create index if not exists app_activity_location_created_idx on public.app_activity_records(location_id,created_at desc);
create index if not exists app_activity_actor_idx on public.app_activity_records(actor_id,created_at desc);

create or replace function public.app_is_corporate() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.app_user_access a where a.user_id=auth.uid() and a.active and a.role='corporate') $$;
create or replace function public.app_can_access_location(p_location text) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.app_user_access a where a.user_id=auth.uid() and a.active and (a.role='corporate' or a.location_id=p_location)) $$;
create or replace function public.app_can_manage_location(p_location text) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.app_user_access a where a.user_id=auth.uid() and a.active and (a.role='corporate' or (a.role='gm' and a.location_id=p_location))) $$;
create or replace function public.app_can_manage_access(target_user uuid, target_role text, target_location text) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.app_user_access me where me.user_id=auth.uid() and me.active and (me.role='corporate' or (me.role='gm' and target_role='shift_lead' and target_location=me.location_id and exists(select 1 from public.app_user_access them where them.user_id=target_user and them.role='shift_lead' and them.location_id=me.location_id)))) $$;
revoke all on function public.app_is_corporate() from public;
revoke all on function public.app_can_access_location(text) from public;
revoke all on function public.app_can_manage_location(text) from public;
revoke all on function public.app_can_manage_access(uuid,text,text) from public;
grant execute on function public.app_is_corporate() to authenticated;
grant execute on function public.app_can_access_location(text) to authenticated;
grant execute on function public.app_can_manage_location(text) to authenticated;
grant execute on function public.app_can_manage_access(uuid,text,text) to authenticated;

alter table public.app_locations enable row level security;
alter table public.app_user_access enable row level security;
alter table public.app_activity_records enable row level security;
drop policy if exists "authenticated can read active locations" on public.app_locations;
create policy "authenticated can read active locations" on public.app_locations for select to authenticated using (active=true);
drop policy if exists "users read own access or corporate reads all" on public.app_user_access;
create policy "users read own access or corporate reads all" on public.app_user_access for select to authenticated using (user_id=auth.uid() or public.app_is_corporate());
drop policy if exists "corporate manages access" on public.app_user_access;
create policy "corporate manages access" on public.app_user_access for all to authenticated using (public.app_is_corporate()) with check (public.app_is_corporate());
drop policy if exists "gm manages shift leads at own location" on public.app_user_access;
create policy "gm manages shift leads at own location" on public.app_user_access for insert to authenticated with check (public.app_can_manage_location(location_id) and role='shift_lead' and exists(select 1 from public.app_user_access me where me.user_id=auth.uid() and me.role='gm' and me.location_id=location_id));
drop policy if exists "members read location activity" on public.app_activity_records;
create policy "members read location activity" on public.app_activity_records for select to authenticated using (public.app_can_access_location(location_id));
drop policy if exists "signed in users create own activity" on public.app_activity_records;
create policy "signed in users create own activity" on public.app_activity_records for insert to authenticated with check (actor_id=auth.uid() and public.app_can_access_location(location_id));
drop policy if exists "corporate and gm update activity" on public.app_activity_records;
create policy "corporate and gm update activity" on public.app_activity_records for update to authenticated using (public.app_can_manage_location(location_id)) with check (public.app_can_manage_location(location_id));
drop policy if exists "corporate and gm delete activity" on public.app_activity_records;
create policy "corporate and gm delete activity" on public.app_activity_records for delete to authenticated using (public.app_can_manage_location(location_id));
grant select on public.app_locations, public.app_user_access, public.app_activity_records to authenticated;
grant insert,update,delete on public.app_user_access to authenticated;
grant insert,select,update,delete on public.app_activity_records to authenticated;
grant usage,select on sequence public.app_activity_records_id_seq to authenticated;

-- Bootstrap the existing project owner as Corporate. This uses the known existing Auth user ID.
insert into public.app_user_access(user_id,role,location_id,active)
values ('efdf695f-ade6-4697-bd17-5265de1c4d7c','corporate',null,true)
on conflict (user_id) do update set role='corporate',location_id=null,active=true,updated_at=now();

-- To add a manager after creating/inviting them under Authentication > Users, run one of:
-- insert into public.app_user_access(user_id,role,location_id) values ('AUTH-USER-UUID','gm','western-hills');
-- insert into public.app_user_access(user_id,role,location_id) values ('AUTH-USER-UUID','shift_lead','groesbeck');
-- Corporate accounts use role='corporate' and location_id=NULL.
