-- Поиск: незнакомых людей — только по юзернейму (@…, с начала); своих контактов — ещё и по имени и по подписи
create or replace function public.lm_search(q text)
 returns table(kind text, id uuid, name text, username text, avatar_url text, color integer, extra text)
 language sql stable security definer set search_path to 'public'
as $function$
  with s as (select lower(regexp_replace(btrim(coalesce(q,'')), '^@+', '')) u, btrim(coalesce(q,'')) t)
  (select 'user', p.id, p.name, p.username, case when lm_priv_ok(p.id,'photo',auth.uid()) then p.avatar_url end, p.color,
     case when lm_priv_ok(p.id,'bio',auth.uid()) then p.bio else '' end
   from lm_profiles p
   cross join s
   left join lm_contacts k on k.owner_id = auth.uid() and k.contact_id = p.id
   where (char_length(s.u) >= 3 and s.u ~ '^[a-z0-9_]+$' and p.username is not null and lower(p.username) like s.u || '%')
      or (k.contact_id is not null and char_length(s.t) >= 1
          and (p.name ilike '%'||s.t||'%' or k.alias ilike '%'||s.t||'%' or lower(coalesce(p.username,'')) like '%'||s.u||'%'))
   order by (k.contact_id is not null) desc, (lower(p.username) = s.u) desc, char_length(coalesce(p.username,''))
   limit 20)
  union all
  (select c.type, c.id, c.title, c.username, c.avatar_url, c.color,
     (select count(*)::text from lm_members x where x.chat_id = c.id) from lm_chats c, s
    where c.is_public and char_length(s.t) >= 1 and (c.username ilike '%'||s.u||'%' or c.title ilike '%'||s.t||'%') limit 20);
$function$;
