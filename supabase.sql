-- Les d'Amours ❤️ — Supabase setup
-- 1) Create a Supabase project.
-- 2) In Authentication > Providers, enable Email.
-- 3) Run this whole script in SQL Editor.
-- 4) Enable Realtime for public.household_state if it is not already enabled.

create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (household_id,user_id)
);

create table if not exists public.household_state (
  household_id uuid primary key references public.households(id) on delete cascade,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create index if not exists household_members_user_idx on public.household_members(user_id);

alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.household_state enable row level security;

create or replace function public.is_household_member(hid uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.household_members where household_id=hid and user_id=auth.uid());
$$;

drop policy if exists "members can read their households" on public.households;
create policy "members can read their households" on public.households for select to authenticated using (public.is_household_member(id));

drop policy if exists "members can read membership" on public.household_members;
create policy "members can read membership" on public.household_members for select to authenticated using (user_id=auth.uid() or public.is_household_member(household_id));

drop policy if exists "members can read state" on public.household_state;
create policy "members can read state" on public.household_state for select to authenticated using (public.is_household_member(household_id));

drop policy if exists "members can write state" on public.household_state;
create policy "members can write state" on public.household_state for all to authenticated using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));

-- Create a new couple/household. Returns the 8-character sharing code.
create or replace function public.create_household()
returns table(id uuid, code text)
language plpgsql security definer set search_path=public as $$
declare h uuid; c text;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if exists(select 1 from public.household_members where user_id=auth.uid()) then
    select hm.household_id,h.code into h,c from public.household_members hm join public.households h on h.id=hm.household_id where hm.user_id=auth.uid() limit 1;
    return query select h,c; return;
  end if;
  c := upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
  insert into public.households(code) values(c) returning households.id into h;
  insert into public.household_members(household_id,user_id) values(h,auth.uid());
  insert into public.household_state(household_id,state) values(h,'{}'::jsonb);
  return query select h,c;
end $$;

grant execute on function public.create_household() to authenticated;

-- Join with the sharing code. This does not expose other household rows to the caller.
create or replace function public.join_household(join_code text)
returns table(id uuid, code text)
language plpgsql security definer set search_path=public as $$
declare h uuid; c text;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  select households.id,households.code into h,c from public.households where households.code=upper(trim(join_code));
  if h is null then raise exception 'code introuvable'; end if;
  if exists(select 1 from public.household_members where user_id=auth.uid()) then raise exception 'ce compte a déjà un foyer'; end if;
  insert into public.household_members(household_id,user_id) values(h,auth.uid()) on conflict do nothing;
  return query select h,c;
end $$;

grant execute on function public.join_household(text) to authenticated;

-- Realtime can listen to this table. If your project requires it, run:
-- alter publication supabase_realtime add table public.household_state;


-- Active la diffusion Realtime des modifications pour les deux téléphones.
do $$ begin
  if not exists (
    select 1
    from pg_publication_rel pr
    join pg_class c on c.oid=pr.prrelid
    join pg_namespace n on n.oid=c.relnamespace
    where pr.prpubid=(select oid from pg_publication where pubname='supabase_realtime')
      and n.nspname='public' and c.relname='household_state'
  ) then
    execute 'alter publication supabase_realtime add table public.household_state';
  end if;
end $$;
