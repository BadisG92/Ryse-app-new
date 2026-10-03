-- Où en est chaque personne dans l'onboarding : une ligne par compte et par
-- parcours, réécrite à chaque étape. Les compteurs d'usage disent combien de
-- gens s'en vont ; cette ligne dit où, sans passer par Firebase. Elle est
-- écrite à l'arrivée sur l'étape, pas au départ : une app tuée sans prévenir
-- laisse quand même sa dernière étape.

create table if not exists public.onboarding_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  mode text not null check (mode in ('full', 'coach_only')),
  step_id text not null,
  chapter int not null default 0,
  steps_seen int not null default 0,
  leaves int not null default 0,
  started_at timestamptz not null default now(),
  seen_at timestamptz not null default now(),
  left_at timestamptz,
  completed_at timestamptz,
  app_version text,
  platform text,
  primary key (user_id, mode)
);

create index if not exists idx_onboarding_progress_open
  on public.onboarding_progress (seen_at desc)
  where completed_at is null;

alter table public.onboarding_progress enable row level security;

-- Lecture de sa propre ligne seulement. L'écriture passe par onb_progress() :
-- les heures sont celles du serveur, pas celles du téléphone.
drop policy if exists onboarding_progress_select_own on public.onboarding_progress;
create policy onboarding_progress_select_own on public.onboarding_progress
  for select to authenticated using (auth.uid() = user_id);

-- 'view' : une étape arrive à l'écran.
-- 'left' : l'app passe en arrière-plan pendant l'onboarding.
-- 'done' : l'onboarding est terminé. La ligne est alors figée.
create or replace function public.onb_progress(
  p_mode text,
  p_event text,
  p_step text default null,
  p_chapter int default null,
  p_app_version text default null,
  p_platform text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null or p_mode is null or p_mode not in ('full', 'coach_only') then
    return;
  end if;

  if p_event = 'view' then
    if coalesce(p_step, '') = '' then
      return;
    end if;
    insert into onboarding_progress as o
      (user_id, mode, step_id, chapter, steps_seen, app_version, platform)
    values
      (v_user, p_mode, left(p_step, 40), coalesce(p_chapter, 0), 1,
       left(p_app_version, 24), left(p_platform, 12))
    on conflict (user_id, mode) do update set
      step_id = excluded.step_id,
      chapter = excluded.chapter,
      steps_seen = o.steps_seen + 1,
      seen_at = now(),
      app_version = coalesce(excluded.app_version, o.app_version),
      platform = coalesce(excluded.platform, o.platform)
    where o.completed_at is null;

  elsif p_event = 'left' then
    update onboarding_progress
       set left_at = now(), leaves = leaves + 1
     where user_id = v_user and mode = p_mode and completed_at is null;

  elsif p_event = 'done' then
    insert into onboarding_progress as o
      (user_id, mode, step_id, chapter, steps_seen, completed_at, app_version, platform)
    values
      (v_user, p_mode, left(coalesce(nullif(p_step, ''), 'done'), 40), coalesce(p_chapter, 0), 0, now(),
       left(p_app_version, 24), left(p_platform, 12))
    on conflict (user_id, mode) do update set
      completed_at = now(),
      seen_at = now()
    where o.completed_at is null;
  end if;
end;
$$;

revoke all on function public.onb_progress(text, text, text, int, text, text) from public, anon;
grant execute on function public.onb_progress(text, text, text, int, text, text) to authenticated;
