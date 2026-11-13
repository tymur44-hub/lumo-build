-- Присутствие игроков в партии (кто сейчас в игре) и быстрые реакции во время игры
create table if not exists lm_game_presence (
  game_id uuid not null references lm_games(id) on delete cascade,
  user_id uuid not null,
  seen_at timestamptz,
  react text,
  react_at timestamptz,
  primary key (game_id, user_id)
);
alter table lm_game_presence enable row level security;
