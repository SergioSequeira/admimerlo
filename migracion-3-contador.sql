-- Administración Merlo — contador de visitas.
-- Pegar en Supabase > SQL Editor > New query > Run. Se puede correr más de una vez sin romper nada.

-- Una fila por día con la cantidad de visitas de ese día (hora de Argentina).
create table if not exists public.visitas (
  dia   date primary key,
  total integer not null default 0
);

alter table public.visitas enable row level security;

-- Nadie anónimo puede leer ni escribir la tabla directamente; solo el panel (usuario logueado) puede ver las estadísticas.
drop policy if exists "admin lee visitas" on public.visitas;
create policy "admin lee visitas" on public.visitas
  for select to authenticated using (true);

-- Función que usa la web: suma una visita (si contar = true) y devuelve el total acumulado.
create or replace function public.registrar_visita(contar boolean default true)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  t bigint;
begin
  if contar then
    insert into public.visitas (dia, total)
    values ((now() at time zone 'America/Argentina/Buenos_Aires')::date, 1)
    on conflict (dia) do update set total = public.visitas.total + 1;
  end if;
  select coalesce(sum(total), 0) into t from public.visitas;
  return t;
end;
$$;

revoke all on function public.registrar_visita(boolean) from public;
grant execute on function public.registrar_visita(boolean) to anon, authenticated;
