create extension if not exists pgcrypto;
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text,
  role text not null check (role in ('admin','editor','viewer')) default 'viewer',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(), name text not null, biz text, status text not null default 'active', period text, region text, people text, project text,
  dealer text, owner_name text, last_contact date, next_action_date date, reason text, next_action text,
  created_by uuid references public.profiles(id), updated_by uuid references public.profiles(id), created_at timestamptz default now(), updated_at timestamptz default now()
);
create table if not exists public.history (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id) on delete cascade,
  event_date date, event_type text, content text not null, created_by uuid references public.profiles(id), created_at timestamptz default now()
);
create or replace function public.my_role() returns text language sql stable security definer set search_path=public as $$ select role from public.profiles where id=auth.uid() and is_active=true $$;
alter table public.profiles enable row level security; alter table public.companies enable row level security; alter table public.history enable row level security;
create policy "profiles read authenticated" on public.profiles for select to authenticated using (public.my_role() is not null);
create policy "companies read" on public.companies for select to authenticated using (public.my_role() is not null);
create policy "companies insert editor" on public.companies for insert to authenticated with check (public.my_role() in ('admin','editor'));
create policy "companies update editor" on public.companies for update to authenticated using (public.my_role() in ('admin','editor')) with check (public.my_role() in ('admin','editor'));
create policy "companies delete admin" on public.companies for delete to authenticated using (public.my_role()='admin');
create policy "history read" on public.history for select to authenticated using (public.my_role() is not null);
create policy "history insert editor" on public.history for insert to authenticated with check (public.my_role() in ('admin','editor'));
create policy "history update editor" on public.history for update to authenticated using (public.my_role() in ('admin','editor')) with check (public.my_role() in ('admin','editor'));
create policy "history delete admin" on public.history for delete to authenticated using (public.my_role()='admin');
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
drop trigger if exists companies_touch on public.companies; create trigger companies_touch before update on public.companies for each row execute function public.touch_updated_at();

-- Dealer portal extension
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check check (role in ('admin','dealer'));
alter table public.companies add column if not exists dealer_visible boolean not null default false;
create table if not exists public.dealer_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references auth.users(id) on delete cascade,
  dealer_name text unique not null,
  dealer_code text unique not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.dealer_accounts enable row level security;
create or replace function public.my_dealer_name() returns text language sql stable security definer set search_path=public as $$ select dealer_name from public.dealer_accounts where user_id=auth.uid() and is_active=true $$;

drop policy if exists "companies read" on public.companies;
create policy "companies read scoped" on public.companies for select to authenticated using (
  public.my_role()='admin' or (public.my_role()='dealer' and dealer_visible=true and dealer=public.my_dealer_name())
);
drop policy if exists "companies insert editor" on public.companies;
drop policy if exists "companies update editor" on public.companies;
create policy "companies insert admin" on public.companies for insert to authenticated with check (public.my_role()='admin');
create policy "companies update admin_or_dealer" on public.companies for update to authenticated using (
  public.my_role()='admin' or (public.my_role()='dealer' and dealer_visible=true and dealer=public.my_dealer_name())
) with check (
  public.my_role()='admin' or (public.my_role()='dealer' and dealer_visible=true and dealer=public.my_dealer_name())
);
drop policy if exists "history read" on public.history;
create policy "history read scoped" on public.history for select to authenticated using (
  exists(select 1 from public.companies c where c.id=company_id)
);
drop policy if exists "history insert editor" on public.history;
create policy "history insert admin_or_dealer" on public.history for insert to authenticated with check (
  public.my_role()='admin' or (public.my_role()='dealer' and exists(select 1 from public.companies c where c.id=company_id and c.dealer_visible=true and c.dealer=public.my_dealer_name()))
);
create policy "dealer accounts admin read" on public.dealer_accounts for select to authenticated using (public.my_role()='admin');
