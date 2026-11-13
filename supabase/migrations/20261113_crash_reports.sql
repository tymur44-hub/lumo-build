-- Отчёты о падениях приложений: устройство само присылает, что сломалось
create table if not exists lm_crash_reports (
  id bigserial primary key,
  user_id uuid default auth.uid(),
  platform text not null check (platform in ('ios','android','web')),
  app_version text,
  os_version text,
  device text,
  message text,
  stack text,
  happened_at timestamptz,
  created_at timestamptz not null default now()
);
alter table lm_crash_reports enable row level security;
drop policy if exists crash_insert on lm_crash_reports;
create policy crash_insert on lm_crash_reports for insert to authenticated with check (user_id = auth.uid());
grant insert on lm_crash_reports to authenticated;
grant usage on sequence lm_crash_reports_id_seq to authenticated;
create index if not exists lm_crash_reports_created on lm_crash_reports(created_at desc);
