-- Winter Arc 2026 : la série de 90 jours, calculée par la base.
--
-- Une journée est tenue quand elle a au moins deux repas notés (deux
-- meal_type différents) et l'objectif d'eau atteint. Ce qui est noté pour une
-- journée compte jusqu'au lendemain midi, heure locale ; passé ce délai la
-- journée est figée dans arc_days et ne bouge plus, même si l'objectif d'eau
-- change ou si une entrée est supprimée.
--
-- La série court à partir du 1er octobre 2026. Un joker est gagné à 30 et à
-- 60 jours de série (deux au plus) et sauve automatiquement une journée
-- ratée ; une journée ratée sans joker remet la série à zéro. Une série
-- commencée au plus tard le 21 décembre qui atteint 90 jours gagne un an
-- d'abonnement (arc_rewards, remis à la main pour cette saison).
--
-- Le téléphone ne décide de rien : il lit arc_state(). C'est aussi arc_state()
-- qui écrit users.streak_count, pour que la flamme et l'arc soient une seule
-- série partout (coach, notifications, accueil).

create table if not exists public.arc_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  tz text not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.arc_days (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  status text not null check (status in ('held', 'missed')),
  trained boolean not null default false,
  meals smallint not null,
  water_ml integer not null,
  water_goal integer not null,
  tz text not null,
  finalized_at timestamptz not null default now(),
  primary key (user_id, day)
);

create table if not exists public.arc_rewards (
  user_id uuid not null references auth.users(id) on delete cascade,
  season text not null,
  streak_start date not null,
  won_on date not null,
  created_at timestamptz not null default now(),
  delivered_at timestamptz,
  delivery_note text,
  primary key (user_id, season)
);

alter table public.arc_members enable row level security;
alter table public.arc_days enable row level security;
alter table public.arc_rewards enable row level security;

-- Lecture seule pour le propriétaire ; seules les fonctions ci-dessous écrivent.
drop policy if exists "arc_members: read own" on public.arc_members;
create policy "arc_members: read own" on public.arc_members
  for select using (auth.uid() = user_id);
drop policy if exists "arc_days: read own" on public.arc_days;
create policy "arc_days: read own" on public.arc_days
  for select using (auth.uid() = user_id);
drop policy if exists "arc_rewards: read own" on public.arc_rewards;
create policy "arc_rewards: read own" on public.arc_rewards
  for select using (auth.uid() = user_id);

-- Index pour lire une journée d'un utilisateur sans parcourir toute la table.
create index if not exists idx_food_entries_user_consumed_at
  on public.food_entries (user_id, consumed_at);
create index if not exists idx_workout_session_summaries_user_date
  on public.workout_session_summaries (user_id, session_date);

-- La marche : une lettre par journée depuis p_from.
--   h tenue · t tenue avec séance · m ratée · p en cours (aujourd'hui, ou hier
--   avant midi) : une journée en cours ne casse rien et ne compte pas encore.
-- Rend la série, ses cases (h, t, j pour un joker, p), les jokers en stock, la
-- meilleure série, la date de victoire et la dernière coupure.
create or replace function public.arc_walk(p_from date, p_codes text, p_last_start date)
returns jsonb
language plpgsql
immutable
set search_path = public, pg_temp
as $$
declare
  i int;
  c text;
  d date;
  v_streak int := 0;
  v_start date := null;
  v_cells text := '';
  v_jokers int := 0;
  v_best int := 0;
  v_won date := null;
  v_won_start date := null;
  v_last_valid date := null;
  v_break_day date := null;
  v_break_lost int := 0;
  v_last_joker date := null;
begin
  for i in 0 .. coalesce(length(p_codes), 0) - 1 loop
    c := substr(p_codes, i + 1, 1);
    d := p_from + i;
    if c in ('h', 't') then
      if v_streak = 0 then
        v_start := d;
        v_cells := '';
      end if;
      v_streak := v_streak + 1;
      v_cells := v_cells || c;
      v_last_valid := d;
      if v_streak % 30 = 0 and v_streak < 90 then
        v_jokers := least(v_jokers + 1, 2);
      end if;
    elsif c = 'p' then
      if v_streak > 0 then
        v_cells := v_cells || 'p';
      end if;
    else
      if v_streak > 0 and v_jokers > 0 then
        v_jokers := v_jokers - 1;
        v_streak := v_streak + 1;
        v_cells := v_cells || 'j';
        v_last_valid := d;
        v_last_joker := d;
        if v_streak % 30 = 0 and v_streak < 90 then
          v_jokers := least(v_jokers + 1, 2);
        end if;
      elsif v_streak > 0 then
        v_break_day := d;
        v_break_lost := v_streak;
        v_streak := 0;
        v_start := null;
        v_cells := '';
        v_jokers := 0;
      end if;
    end if;
    v_best := greatest(v_best, v_streak);
    if v_won is null and v_streak = 90 and v_start <= p_last_start then
      v_won := d;
      v_won_start := v_start;
    end if;
  end loop;

  return jsonb_build_object(
    'streak', v_streak,
    'streak_start', v_start,
    'cells', v_cells,
    'jokers', v_jokers,
    'best', v_best,
    'won_on', v_won,
    'won_start', v_won_start,
    'last_valid', v_last_valid,
    'last_break', case when v_break_day is null then null
                  else jsonb_build_object('day', v_break_day, 'lost', v_break_lost) end,
    'last_joker', v_last_joker
  );
end;
$$;

-- Le calcul complet pour un utilisateur à un instant donné. Interne : le
-- téléphone passe par arc_state(), qui fixe l'utilisateur et l'heure.
create or replace function public.arc_compute(
  p_user uuid,
  p_tz text,
  p_now timestamptz,
  p_persist boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  c_season constant text := 'winter-2026';
  c_opens constant date := date '2026-10-01';
  c_last_start constant date := date '2026-12-21';
  c_ends constant date := date '2027-03-20';
  v_tz text;
  v_saved_tz text;
  v_goal int;
  v_created timestamptz;
  v_today date;
  v_from date;
  v_codes text := '';
  v_code text;
  v_held boolean;
  v_today_obj jsonb := null;
  v_grace jsonb := null;
  v_walk jsonb;
  v_streak int;
  v_start date;
  v_won date;
  v_phase text;
  r record;
begin
  if p_user is null then
    return null;
  end if;

  select coalesce(u.daily_water_goal, 2000), u.created_at
    into v_goal, v_created
    from users u where u.id = p_user;
  if not found then
    return null;
  end if;

  select m.tz into v_saved_tz from arc_members m where m.user_id = p_user;
  if p_tz is not null and exists (select 1 from pg_timezone_names where name = p_tz) then
    v_tz := p_tz;
    if p_persist and v_saved_tz is distinct from p_tz then
      insert into arc_members (user_id, tz) values (p_user, p_tz)
      on conflict (user_id) do update set tz = excluded.tz, updated_at = now();
    end if;
  else
    v_tz := coalesce(v_saved_tz, 'UTC');
  end if;

  v_today := (p_now at time zone v_tz)::date;
  v_phase := case when v_today < c_opens then 'soon'
                  when v_today > c_ends then 'ended'
                  else 'open' end;

  if v_today < c_opens then
    return jsonb_build_object(
      'phase', v_phase, 'season', c_season, 'today', v_today, 'tz', v_tz,
      'opens', c_opens, 'last_start', c_last_start, 'ends', c_ends,
      'streak', 0, 'cells', '', 'jokers', 0, 'best', 0, 'eligible', true);
  end if;

  v_from := greatest(c_opens, coalesce((v_created at time zone v_tz)::date, c_opens));
  if v_from > v_today then
    v_from := v_today;
  end if;

  for r in
    with days as (
      select g::date as day,
             -- consumed_at porte l'heure murale du téléphone, relue comme UTC
             -- (voir RyzeDates.wall) : la journée se borne donc en UTC.
             (g::date)::timestamp at time zone 'UTC' as day_start,
             ((g::date + 1)::timestamp) at time zone 'UTC' as day_end,
             -- created_at, lui, est un vrai instant : l'échéance aussi.
             ((g::date + 1)::timestamp + interval '12 hours') at time zone v_tz as deadline
      from generate_series(v_from, v_today, interval '1 day') g
    )
    select dd.day, dd.deadline, a.status as fin_status, a.trained as fin_trained,
      case when a.status is null then (
        select count(distinct f.meal_type) from food_entries f
        where f.user_id = p_user
          and f.consumed_at >= dd.day_start and f.consumed_at < dd.day_end
          and f.created_at < dd.deadline
      ) end as meals,
      case when a.status is null then (
        select coalesce(sum(w.amount), 0) from water_entries w
        where w.user_id = p_user
          and w.consumed_at >= dd.day_start and w.consumed_at < dd.day_end
          and w.created_at < dd.deadline
      ) end as water,
      case when a.status is null then (
        exists (select 1 from workout_session_summaries s
                where s.user_id = p_user and s.session_date = dd.day)
        or exists (select 1 from cardio_sessions cs
                   where cs.user_id = p_user and cs.is_completed
                     and cs.session_date = dd.day)
        or exists (select 1 from hiit_sessions hs
                   where hs.user_id = p_user and hs.is_completed
                     and hs.start_time >= dd.day_start and hs.start_time < dd.day_end)
      ) end as trained
    from days dd
    left join arc_days a on a.user_id = p_user and a.day = dd.day
    order by dd.day
  loop
    if r.fin_status is not null then
      v_code := case when r.fin_status = 'held'
                     then (case when r.fin_trained then 't' else 'h' end)
                     else 'm' end;
    else
      v_held := r.meals >= 2 and r.water >= v_goal;
      if p_now >= r.deadline then
        if p_persist then
          insert into arc_days (user_id, day, status, trained, meals, water_ml, water_goal, tz)
          values (p_user, r.day, case when v_held then 'held' else 'missed' end,
                  coalesce(r.trained, false), r.meals, r.water, v_goal, v_tz)
          on conflict (user_id, day) do nothing;
        end if;
        v_code := case when v_held then (case when r.trained then 't' else 'h' end) else 'm' end;
      else
        v_code := case when v_held then (case when r.trained then 't' else 'h' end) else 'p' end;
        if r.day = v_today then
          v_today_obj := jsonb_build_object(
            'held', v_held, 'meals', r.meals, 'water_ml', r.water,
            'water_goal', v_goal, 'trained', coalesce(r.trained, false));
        elsif not v_held then
          v_grace := jsonb_build_object(
            'day', r.day, 'meals', r.meals, 'water_ml', r.water,
            'water_goal', v_goal, 'deadline', r.deadline);
        end if;
      end if;
    end if;
    v_codes := v_codes || v_code;
  end loop;

  v_walk := arc_walk(v_from, v_codes, c_last_start);
  v_streak := (v_walk->>'streak')::int;
  v_start := (v_walk->>'streak_start')::date;
  v_won := (v_walk->>'won_on')::date;

  if p_persist then
    if v_won is not null then
      insert into arc_rewards (user_id, season, streak_start, won_on)
      values (p_user, c_season, (v_walk->>'won_start')::date, v_won)
      on conflict (user_id, season) do nothing;
    end if;

    -- Une seule série dans l'app : la flamme suit l'arc.
    update users
       set streak_count = v_streak,
           streak_last_date = (v_walk->>'last_valid')::date
     where id = p_user
       and (streak_count is distinct from v_streak
            or streak_last_date is distinct from (v_walk->>'last_valid')::date);
  end if;

  return v_walk - 'won_start' || jsonb_build_object(
    'phase', v_phase,
    'season', c_season,
    'today', v_today,
    'tz', v_tz,
    'opens', c_opens,
    'last_start', c_last_start,
    'ends', c_ends,
    'today_status', v_today_obj,
    'grace', v_grace,
    'eligible', v_won is null and v_phase = 'open'
                and coalesce(v_start, v_today) <= c_last_start
  );
end;
$$;

-- Ce que le téléphone appelle : son propre arc, maintenant.
create or replace function public.arc_state(p_tz text default null)
returns jsonb
language sql
security definer
set search_path = public, pg_temp
as $$
  select public.arc_compute(auth.uid(), p_tz, now(), true);
$$;

revoke all on function public.arc_compute(uuid, text, timestamptz, boolean) from public, anon, authenticated;
revoke all on function public.arc_state(text) from public, anon;
grant execute on function public.arc_state(text) to authenticated;
grant execute on function public.arc_walk(date, text, date) to authenticated;
