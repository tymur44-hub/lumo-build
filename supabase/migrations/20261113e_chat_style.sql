-- Оформление канала или группы (как профиль): цвет шапки, узор вокруг аватара, эмодзи-статус рядом с названием
alter table public.lm_chats add column if not exists profile_bg int;
alter table public.lm_chats add column if not exists profile_pattern text;
alter table public.lm_chats add column if not exists emoji_status text;

create or replace function public.lm_set_chat_style(p_chat uuid, p_bg int, p_pattern text, p_status text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from lm_members where chat_id = p_chat and user_id = auth.uid() and role in ('owner','admin')) then
    raise exception 'Оформление меняют только администраторы';
  end if;
  if p_bg is not null and (p_bg < 0 or p_bg > 30) then raise exception 'Неверный цвет'; end if;
  if p_pattern is not null and length(p_pattern) > 64 then raise exception 'Неверный узор'; end if;
  if p_status is not null and length(p_status) > 120 then raise exception 'Неверный статус'; end if;
  update lm_chats set profile_bg = p_bg, profile_pattern = nullif(p_pattern, ''), emoji_status = nullif(p_status, '')
  where id = p_chat and type in ('channel','group');
end $$;
revoke all on function public.lm_set_chat_style(uuid, int, text, text) from public, anon;
grant execute on function public.lm_set_chat_style(uuid, int, text, text) to authenticated;
