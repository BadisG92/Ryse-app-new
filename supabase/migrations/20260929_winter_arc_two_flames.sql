-- Deux flammes : la flamme normale garde sa règle (une activité par jour) et
-- n'est plus écrasée par l'arc. arc_state() ne touche plus users.streak_count.

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

