-- PeakForm AI — run this in Supabase Dashboard → SQL Editor → New query → Run

-- ---------------------------------------------------------------------------
-- 1. Profiles table (one row per user)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  email text,
  avatar_url text,
  sport text,
  units text default 'Imperial (lbs, ft)',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Profiles: users can read own row"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Profiles: users can insert own row"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Profiles: users can update own row"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create profile when someone signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Athlete'),
    new.email
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 2. Workout sessions (for AI coach / CV results later)
-- ---------------------------------------------------------------------------
create table if not exists public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  sport text,
  duration_minutes int,
  pose_score numeric(5, 2),
  feedback jsonb,
  started_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.workout_sessions enable row level security;

create policy "Workouts: users can read own sessions"
  on public.workout_sessions for select
  using (auth.uid() = user_id);

create policy "Workouts: users can insert own sessions"
  on public.workout_sessions for insert
  with check (auth.uid() = user_id);

create policy "Workouts: users can update own sessions"
  on public.workout_sessions for update
  using (auth.uid() = user_id);

create policy "Workouts: users can delete own sessions"
  on public.workout_sessions for delete
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 3. Storage bucket for profile avatars
--    Also create bucket "avatars" in Dashboard → Storage → New bucket (public)
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "Avatars: users can upload own folder"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Avatars: users can update own folder"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Avatars: users can delete own folder"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Avatars: public read"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- ---------------------------------------------------------------------------
-- 4. Scheduled games (user-managed game schedule)
-- ---------------------------------------------------------------------------
create table if not exists public.scheduled_games (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  opponent_name text not null,
  game_at timestamptz not null,
  is_home boolean not null default true,
  user_team_name text not null default 'My Team',
  created_at timestamptz not null default now()
);

alter table public.scheduled_games enable row level security;

create policy "Games: users can read own games"
  on public.scheduled_games for select
  using (auth.uid() = user_id);

create policy "Games: users can insert own games"
  on public.scheduled_games for insert
  with check (auth.uid() = user_id);

create policy "Games: users can update own games"
  on public.scheduled_games for update
  using (auth.uid() = user_id);

create policy "Games: users can delete own games"
  on public.scheduled_games for delete
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 5. Nutrition logs (barcode scans + daily meal tracking)
-- ---------------------------------------------------------------------------
create table if not exists public.nutrition_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  logged_at timestamptz not null default now(),
  product_name text not null,
  barcode text,
  calories numeric(8, 2),
  protein_g numeric(8, 2),
  fat_g numeric(8, 2),
  carbs_g numeric(8, 2),
  serving_size text,
  servings numeric(4, 2) not null default 1,
  source text not null default 'barcode',
  image_url text,
  created_at timestamptz not null default now()
);

alter table public.nutrition_logs enable row level security;

create policy "Nutrition: users can read own logs"
  on public.nutrition_logs for select
  using (auth.uid() = user_id);

create policy "Nutrition: users can insert own logs"
  on public.nutrition_logs for insert
  with check (auth.uid() = user_id);

create policy "Nutrition: users can update own logs"
  on public.nutrition_logs for update
  using (auth.uid() = user_id);

create policy "Nutrition: users can delete own logs"
  on public.nutrition_logs for delete
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 6. Profile training preferences (sports + intensity + onboarding flag)
-- Run this whole section in order if your profiles table is older.
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists sports text[] default array['Basic Workout']::text[];

alter table public.profiles
  add column if not exists training_intensity text default 'Serious';

alter table public.profiles
  add column if not exists training_location text default 'Home';

alter table public.profiles
  add column if not exists sports_setup_completed boolean default false;

-- Backfill legacy single sport column into sports array.
update public.profiles
set sports = array[sport]::text[]
where sport is not null
  and sport <> ''
  and (sports is null or sports = '{}'::text[]);

-- Existing accounts already past onboarding (run AFTER sports column exists).
update public.profiles
set sports_setup_completed = true
where sports_setup_completed is distinct from true
  and (
    (sports is not null and sports <> '{}'::text[])
    or (sport is not null and sport <> '')
  );

-- ---------------------------------------------------------------------------
-- 7. Body metrics for Growth Hub
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists height_inches numeric;

alter table public.profiles
  add column if not exists weight_lbs numeric;

alter table public.profiles
  add column if not exists body_fat_percent numeric;

alter table public.profiles
  add column if not exists muscle_mass_lbs numeric;

alter table public.profiles
  add column if not exists prev_height_inches numeric;

alter table public.profiles
  add column if not exists prev_weight_lbs numeric;

alter table public.profiles
  add column if not exists prev_body_fat_percent numeric;

alter table public.profiles
  add column if not exists prev_muscle_mass_lbs numeric;