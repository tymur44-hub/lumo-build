-- Копия ключа шифрования без пароля: у каждого пользователя свой случайный ключ обёртки,
-- который выдаётся только ему самому после входа. Прямого доступа к таблице нет (RLS без политик).
create table if not exists lm_wrap_keys(
  user_id uuid primary key references auth.users(id) on delete cascade,
  k text not null,
  created_at timestamptz not null default now()
);
alter table lm_wrap_keys enable row level security;
revoke all on lm_wrap_keys from anon, authenticated;

create or replace function lm_wrap_key() returns text
language plpgsql security definer set search_path to 'public' as $$
declare v text;
begin
  if auth.uid() is null then raise exception 'Нужен вход'; end if;
  select k into v from lm_wrap_keys where user_id = auth.uid();
  if v is null then
    insert into lm_wrap_keys(user_id, k) values (auth.uid(), encode(extensions.gen_random_bytes(32), 'base64'))
    on conflict (user_id) do nothing;
    select k into v from lm_wrap_keys where user_id = auth.uid();
  end if;
  return v;
end $$;
revoke all on function lm_wrap_key() from public, anon;
grant execute on function lm_wrap_key() to authenticated;
