alter table lm_members add column if not exists reactions_seen_at timestamptz not null default now();
create index if not exists lm_reactions_chat_time on lm_reactions(chat_id, created_at desc);

-- непросмотренные реакции других людей на мои сообщения: по каждому чату последняя реакция и их количество
create or replace function lm_unseen_reactions()
returns table(chat_id uuid, emoji text, at timestamptz, cnt int, message_id bigint)
language sql stable security definer set search_path to 'public' as $$
  with r as (
    select x.chat_id, x.user_id, x.emoji, x.created_at, x.message_id from lm_reactions x
    union all
    select x.chat_id, x.user_id, x.emoji, x.created_at, x.message_id from lm_reactions_extra x
  ), u as (
    select r.* from lm_members m
    join r on r.chat_id = m.chat_id and r.created_at > m.reactions_seen_at and r.user_id <> auth.uid()
    join lm_messages msg on msg.id = r.message_id and msg.sender_id = auth.uid() and not msg.deleted
    where m.user_id = auth.uid()
  )
  select distinct on (u.chat_id) u.chat_id, u.emoji, u.created_at, (count(*) over (partition by u.chat_id))::int, u.message_id
  from u order by u.chat_id, u.created_at desc;
$$;

-- открыл чат — реакции просмотрены
create or replace function lm_seen_reactions(p_chat uuid)
returns void language sql security definer set search_path to 'public' as $$
  update lm_members set reactions_seen_at = now() where chat_id = p_chat and user_id = auth.uid();
$$;
grant execute on function lm_unseen_reactions() to authenticated;
grant execute on function lm_seen_reactions(uuid) to authenticated;
