-- Верификация по документу: фото документа и селфи с кодом хранятся в закрытом хранилище до решения
alter table lm_verify_requests drop constraint if exists lm_verify_requests_status_check;
alter table lm_verify_requests add constraint lm_verify_requests_status_check
  check (status in ('collect','pending','approved','rejected','cancelled'));
alter table lm_verify_requests add column if not exists code text;
alter table lm_verify_requests add column if not exists doc_path text;
alter table lm_verify_requests add column if not exists selfie_path text;

insert into storage.buckets (id, name, public, file_size_limit)
values ('lm-verify', 'lm-verify', false, 15728640)
on conflict (id) do update set public = false;

-- Поиск людей — только по юзернейму (@…), по началу адреса. Каналы и группы — как раньше.
create or replace function public.lm_search(q text)
 returns table(kind text, id uuid, name text, username text, avatar_url text, color integer, extra text)
 language sql stable security definer set search_path to 'public'
as $function$
  with s as (select lower(regexp_replace(btrim(coalesce(q,'')), '^@+', '')) u, btrim(coalesce(q,'')) t)
  (select 'user', p.id, p.name, p.username, case when lm_priv_ok(p.id,'photo',auth.uid()) then p.avatar_url end, p.color,
     case when lm_priv_ok(p.id,'bio',auth.uid()) then p.bio else '' end
   from lm_profiles p, s
   where char_length(s.u) >= 3 and s.u ~ '^[a-z0-9_]+$' and p.username is not null
     and lower(p.username) like s.u || '%'
   order by (lower(p.username) = s.u) desc, char_length(p.username)
   limit 20)
  union all
  (select c.type, c.id, c.title, c.username, c.avatar_url, c.color,
     (select count(*)::text from lm_members x where x.chat_id = c.id) from lm_chats c, s
    where c.is_public and char_length(s.t) >= 1 and (c.username ilike '%'||s.u||'%' or c.title ilike '%'||s.t||'%') limit 20);
$function$;
