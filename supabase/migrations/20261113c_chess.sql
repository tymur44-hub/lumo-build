-- Шахматы среди игр вдвоём
alter table lm_games drop constraint if exists lm_games_kind_check;
alter table lm_games add constraint lm_games_kind_check check (kind = any (array['ttt','checkers','sea','chess']));
