-- CHANGE UK website database setup
-- Run in Supabase SQL Editor. Then create your own account on the site and mark it admin with the final UPDATE.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text,
  last_name text,
  dob date,
  membership_type text check (membership_type in ('adult','youth')),
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.memberships (
  user_id uuid primary key references auth.users(id) on delete cascade,
  membership_type text not null check (membership_type in ('adult','youth')),
  status text not null default 'active' check (status in ('active','paused','cancelled')),
  joined_at timestamptz not null default now()
);

create table if not exists public.site_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.policies (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text,
  summary text,
  detail text,
  quiz_question text,
  quiz_position int default 3 check (quiz_position between 1 and 5),
  sort_order int not null default 0,
  published boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.news (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text,
  published boolean not null default false,
  published_at timestamptz default now()
);

insert into public.site_settings(key,value) values
 ('stats','{"mps":0,"councillors":0,"councils":0}'::jsonb),
 ('hero_notice','{"text":"A different kind of political website."}'::jsonb)
on conflict (key) do nothing;

insert into public.policies(title,category,summary,detail,quiz_question,quiz_position,sort_order,published) values
 ('Cost of Living','Economy','Reduce pressure on household costs through targeted affordability measures.','A policy area focused on household costs, affordability and everyday living expenses.','Government should take further targeted action to reduce household living costs.',5,1,true),
 ('Bus Fares','Transport','Lower and simplify local bus fares, with a focus on reliable everyday travel.','A transport policy focused on fare affordability and access to local bus services.','Local bus fares should be reduced and made simpler.',5,2,true),
 ('University Tuition 18–21','Education','Remove university tuition fees for eligible learners aged 18–21.','An education policy proposing no university tuition fees for eligible students aged 18 to 21.','Eligible students aged 18–21 should not pay university tuition fees.',5,3,true),
 ('Managed Immigration','Immigration','Reduce the pace of immigration while maintaining managed legal routes.','An immigration policy focused on reducing overall pace while retaining managed legal routes.','The overall pace of immigration should be reduced.',5,4,true)
on conflict do nothing;

alter table public.profiles enable row level security;
alter table public.memberships enable row level security;
alter table public.site_settings enable row level security;
alter table public.policies enable row level security;
alter table public.news enable row level security;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select coalesce((select is_admin from public.profiles where id=auth.uid()),false)
$$;

-- PUBLIC READ
create policy "Public read settings" on public.site_settings for select using (true);
create policy "Public read published policies" on public.policies for select using (published=true or public.is_admin());
create policy "Public read published news" on public.news for select using (published=true or public.is_admin());

-- PROFILE / MEMBERSHIP
create policy "Users read own profile" on public.profiles for select using (id=auth.uid() or public.is_admin());
create policy "Users insert own profile" on public.profiles for insert with check (id=auth.uid());
create policy "Users update own profile" on public.profiles for update using (id=auth.uid()) with check (id=auth.uid());
create policy "Users read own membership" on public.memberships for select using (user_id=auth.uid() or public.is_admin());
create policy "Users insert own membership" on public.memberships for insert with check (user_id=auth.uid());
create policy "Users update own membership" on public.memberships for update using (user_id=auth.uid()) with check (user_id=auth.uid());

-- ADMIN CONTENT MANAGEMENT
create policy "Admin manage settings" on public.site_settings for all using (public.is_admin()) with check (public.is_admin());
create policy "Admin manage policies" on public.policies for all using (public.is_admin()) with check (public.is_admin());
create policy "Admin manage news" on public.news for all using (public.is_admin()) with check (public.is_admin());

-- Optional automatic profile creation from auth metadata
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,first_name,last_name,dob,membership_type)
  values(new.id,new.raw_user_meta_data->>'first_name',new.raw_user_meta_data->>'last_name',nullif(new.raw_user_meta_data->>'dob','')::date,new.raw_user_meta_data->>'membership_type')
  on conflict(id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- IMPORTANT: after signing up your own admin account, replace the email below and run this once.
-- update public.profiles set is_admin=true where id=(select id from auth.users where email='YOUR-ADMIN-EMAIL@example.com');
