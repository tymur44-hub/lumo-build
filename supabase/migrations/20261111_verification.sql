-- Галочка для каналов и групп + заявки на верификацию через @bot_verification
alter table lm_chats add column if not exists verified boolean not null default false;

create table if not exists lm_verify_requests(
  id bigserial primary key,
  user_id uuid not null references lm_profiles(id) on delete cascade,
  kind text not null check (kind in ('user','chat')),
  target_id uuid not null,
  chat_id uuid,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  decided_by uuid,
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
alter table lm_verify_requests enable row level security;
revoke all on lm_verify_requests from anon, authenticated;

-- в списке чатов галочка канала/группы приходит в том же поле, что и у собеседника (peer_verified)
do $$ declare d text; begin
  d := pg_get_functiondef('lm_chats_v2'::regproc);
  if position('coalesce(p.verified, c.verified, false)' in d) = 0 then
    d := replace(d, 'coalesce(p.verified, false)', 'coalesce(p.verified, c.verified, false)');
    execute d;
  end if;
end $$;

-- администрация может поставить или снять галочку каналу/группе
create or replace function lm_admin_chat_verify(cid uuid, v boolean) returns void
language plpgsql security definer set search_path to 'public' as $$
begin
  if not exists (select 1 from lm_staff where user_id = auth.uid() and role in ('owner','admin')) then raise exception 'Нет прав'; end if;
  update lm_chats set verified = v where id = cid;
end $$;
revoke all on function lm_admin_chat_verify(uuid, boolean) from public, anon;
grant execute on function lm_admin_chat_verify(uuid, boolean) to authenticated;

-- бот, созданный 7 ноября без записи в lm_bots (ошибка в BotFather), — возвращаем владельцу
insert into lm_bots(id, owner_id, token, description)
select p.id, '9b17b8bf-d87e-4df0-83db-ead8ab4fae13', left(replace(p.id::text,'-',''),10) || ':' || encode(extensions.gen_random_bytes(24),'hex'), ''
from lm_profiles p where p.id = '04e45730-c4fe-4c95-abc7-1d5c39da1723' and p.is_bot
on conflict (id) do nothing;

-- Видео-аватарки (Premium): видео до 10 с, обложка — обычная аватарка
alter table lm_profiles add column if not exists avatar_video text;

create or replace function lm_set_avatar_video(p_video text, p_cover text default null) returns void
language plpgsql security definer set search_path to 'public' as $$
begin
  if auth.uid() is null then raise exception 'Нужен вход'; end if;
  if p_video is not null and not lm_is_premium(auth.uid()) then raise exception 'Видео-аватарка доступна с Lumo Premium'; end if;
  update lm_profiles set avatar_video = p_video, avatar_url = coalesce(p_cover, avatar_url) where id = auth.uid();
end $$;
revoke all on function lm_set_avatar_video(text, text) from public, anon;
grant execute on function lm_set_avatar_video(text, text) to authenticated;

create or replace function lm_avatar_videos(p_ids uuid[]) returns table(id uuid, avatar_url text, video text)
language sql stable security definer set search_path to 'public' as $$
  select p.id, p.avatar_url, p.avatar_video from lm_profiles p
  where p.id = any(p_ids) and p.avatar_video is not null and p.avatar_url is not null
    and lm_is_premium(p.id) and lm_priv_ok(p.id, 'photo', auth.uid());
$$;
revoke all on function lm_avatar_videos(uuid[]) from public, anon;
grant execute on function lm_avatar_videos(uuid[]) to authenticated;
