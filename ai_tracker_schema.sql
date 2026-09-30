-- AI 조사/출처 기능 추가 스키마
create table if not exists public.company_sources (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  title text not null,
  url text,
  domain text,
  note text,
  source_type text not null default 'AI 조사',
  published_at date,
  checked_at date not null default current_date,
  is_new boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique(company_id, url)
);

create table if not exists public.ai_updates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  searched_at date not null default current_date,
  category text,
  title text not null,
  summary text,
  source_urls text[] default '{}',
  created_at timestamptz not null default now()
);

alter table public.company_sources enable row level security;
alter table public.ai_updates enable row level security;

drop policy if exists "sources read scoped" on public.company_sources;
create policy "sources read scoped" on public.company_sources for select to authenticated using (
  exists(select 1 from public.companies c where c.id=company_id)
);
drop policy if exists "sources admin write" on public.company_sources;
create policy "sources admin write" on public.company_sources for all to authenticated
using (public.my_role()='admin') with check (public.my_role()='admin');

drop policy if exists "ai updates read scoped" on public.ai_updates;
create policy "ai updates read scoped" on public.ai_updates for select to authenticated using (
  exists(select 1 from public.companies c where c.id=company_id)
);
drop policy if exists "ai updates admin write" on public.ai_updates;
create policy "ai updates admin write" on public.ai_updates for all to authenticated
using (public.my_role()='admin') with check (public.my_role()='admin');
