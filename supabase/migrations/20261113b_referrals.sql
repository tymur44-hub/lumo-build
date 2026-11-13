-- Приглашения: новый человек указывает, кто его позвал, — оба получают по 25 люменов
create table if not exists lm_referrals (
  invitee uuid primary key references auth.users(id) on delete cascade,
  inviter uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table lm_referrals enable row level security;

create or replace function public.lm_claim_referral(p_username text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare me uuid := auth.uid(); inv uuid; made timestamptz; n int; bonus constant int := 25;
begin
  if me is null then raise exception 'not authenticated'; end if;
  select created_at into made from lm_profiles where id = me;
  if made is null or made < now() - interval '7 days' then
    return jsonb_build_object('ok', false, 'error', 'Пригласившего можно указать только в первую неделю после регистрации');
  end if;
  if exists (select 1 from lm_referrals where invitee = me) then
    return jsonb_build_object('ok', false, 'error', 'Пригласивший уже указан');
  end if;
  select id into inv from lm_profiles
   where lower(username) = lower(regexp_replace(btrim(coalesce(p_username,'')), '^@+', '')) and not coalesce(is_bot,false) and not coalesce(banned,false);
  if inv is null then return jsonb_build_object('ok', false, 'error', 'Пользователь не найден'); end if;
  if inv = me then return jsonb_build_object('ok', false, 'error', 'Нельзя пригласить самого себя'); end if;
  select count(*) into n from lm_referrals where inviter = inv;
  insert into lm_referrals(invitee, inviter) values (me, inv);
  insert into lm_wallets(user_id, balance) values (me, bonus) on conflict (user_id) do update set balance = lm_wallets.balance + bonus;
  insert into lm_ledger(user_id, delta, kind, ref_user) values (me, bonus, 'referral', inv);
  if n < 100 then   -- пригласившему — не больше чем за 100 человек
    insert into lm_wallets(user_id, balance) values (inv, bonus) on conflict (user_id) do update set balance = lm_wallets.balance + bonus;
    insert into lm_ledger(user_id, delta, kind, ref_user) values (inv, bonus, 'referral', me);
  end if;
  return jsonb_build_object('ok', true, 'bonus', bonus);
end $$;

create or replace function public.lm_my_referrals()
returns jsonb language sql stable security definer set search_path to 'public' as $$
  select jsonb_build_object(
    'invited', (select count(*) from lm_referrals where inviter = auth.uid()),
    'earned', coalesce((select sum(delta) from lm_ledger where user_id = auth.uid() and kind = 'referral'), 0),
    'invited_by', (select p.username from lm_referrals r join lm_profiles p on p.id = r.inviter where r.invitee = auth.uid()),
    'can_claim', (select created_at > now() - interval '7 days' from lm_profiles where id = auth.uid())
                 and not exists (select 1 from lm_referrals where invitee = auth.uid()));
$$;
revoke all on function public.lm_claim_referral(text) from public, anon;
grant execute on function public.lm_claim_referral(text) to authenticated;
revoke all on function public.lm_my_referrals() from public, anon;
grant execute on function public.lm_my_referrals() to authenticated;
