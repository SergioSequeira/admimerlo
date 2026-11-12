-- Administración Merlo — contador de visitas.
-- Pegar en Supabase > SQL Editor > New query > Run. Se puede correr más de una vez sin romper nada.

-- Una fila por día con la cantidad de visitas de ese día (hora de Argentina).
create table if not exists public.visitas (
  dia   date primary key,
  total integer not null default 0
);

alter table public.visitas enable row level security;

-- Permiso de lectura para el panel (usuario logueado). Sin este GRANT, Supabase devuelve "permission denied" aunque exista la política.
grant select on public.visitas to authenticated;

-- Nadie anónimo puede leer ni escribir la tabla directamente; solo el panel (usuario logueado) puede ver las estadísticas.
drop policy if exists "admin lee visitas" on public.visitas;
create policy "admin lee visitas" on public.visitas
  for select to authenticated using (true);

-- Función que usa la web: suma una visita al día de hoy. No devuelve nada (el total solo se ve en el panel).
drop function if exists public.registrar_visita(boolean);
create or replace function public.registrar_visita()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.visitas (dia, total)
  values ((now() at time zone 'America/Argentina/Buenos_Aires')::date, 1)
  on conflict (dia) do update set total = public.visitas.total + 1;
end;
$$;

revoke all on function public.registrar_visita() from public;
grant execute on function public.registrar_visita() to anon, authenticated;
