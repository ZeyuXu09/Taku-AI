-- Run this ONLY if you already created scheduled_games with a profiles foreign key
-- and saving games fails with a foreign key error.

alter table public.scheduled_games
  drop constraint if exists scheduled_games_user_id_fkey;

alter table public.scheduled_games
  add constraint scheduled_games_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;
