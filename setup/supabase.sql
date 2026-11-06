begin;

create table if not exists public.lab_students (
  id bigint generated always as identity primary key,
  name text not null check (char_length(btrim(name)) between 1 and 100),
  major text not null check (char_length(btrim(major)) between 1 and 120),
  "gradYear" integer not null check ("gradYear" between 1900 and 2200)
);

alter table public.lab_students enable row level security;
revoke all on public.lab_students from anon, authenticated;
grant select, insert (name, major, "gradYear") on public.lab_students to authenticated;
grant usage on sequence public.lab_students_id_seq to authenticated;
drop policy if exists lab_students_read on public.lab_students;
create policy lab_students_read on public.lab_students for select to authenticated using (true);
drop policy if exists lab_students_insert on public.lab_students;
create policy lab_students_insert on public.lab_students for insert to authenticated with check (true);

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'lab_students'
  ) then
    alter publication supabase_realtime add table public.lab_students;
  end if;
end
$$;

commit;
