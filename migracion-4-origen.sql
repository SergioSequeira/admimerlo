-- Administración Merlo — origen del tráfico y clics de contacto.
-- Pegar en Supabase > SQL Editor > New query > Run. Se puede correr más de una vez sin romper nada.
-- Supabase puede avisar "destructive operation" por los DROP FUNCTION: son solo de las funciones del contador. Confirmar.

-- Una fila por día + origen + tipo de evento. tipo: 'visita', 'whatsapp' (clic en WhatsApp) o 'llamar' (clic en llamar).
create table if not exists public.visitas_origen (
  dia    date    not null,
  origen text    not null,
  tipo   text    not null check (tipo in ('visita','whatsapp','llamar')),
  total  integer not null default 0,
  primary key (dia, origen, tipo)
);

alter table public.visitas_origen enable row level security;
grant select on public.visitas_origen to authenticated;

-- Solo el panel (usuario logueado) puede leer; el público no lee ni escribe la tabla directamente.
drop policy if exists "admin lee visitas_origen" on public.visitas_origen;
create policy "admin lee visitas_origen" on public.visitas_origen
  for select to authenticated using (true);

-- Reemplaza la función anterior (sin parámetros). Con el parámetro opcional, las páginas viejas que llaman sin él siguen funcionando.
-- Los orígenes están limitados a una lista fija: cualquier otro texto se guarda como 'otro' (así nadie puede llenar la tabla de basura).
drop function if exists public.registrar_visita();
drop function if exists public.registrar_visita(text);
create or replace function public.registrar_visita(p_origen text default 'directo')
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dia    date := (now() at time zone 'America/Argentina/Buenos_Aires')::date;
  v_origen text := lower(coalesce(p_origen, 'directo'));
begin
  if v_origen <> all (array['directo','google','google_negocio','facebook','instagram','whatsapp','mercadolibre','zonaprop','argenprop','youtube','mardelfrentealmar','qr']) then
    v_origen := 'otro';
  end if;

  insert into public.visitas (dia, total) values (v_dia, 1)
  on conflict (dia) do update set total = public.visitas.total + 1;

  insert into public.visitas_origen (dia, origen, tipo, total) values (v_dia, v_origen, 'visita', 1)
  on conflict (dia, origen, tipo) do update set total = public.visitas_origen.total + 1;
end;
$$;

revoke all on function public.registrar_visita(text) from public;
grant execute on function public.registrar_visita(text) to anon, authenticated;

-- Clic en un botón de contacto (WhatsApp o llamar), con el origen de esa visita.
drop function if exists public.registrar_click(text, text);
create or replace function public.registrar_click(p_origen text default 'directo', p_tipo text default 'whatsapp')
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dia    date := (now() at time zone 'America/Argentina/Buenos_Aires')::date;
  v_origen text := lower(coalesce(p_origen, 'directo'));
  v_tipo   text := lower(coalesce(p_tipo, ''));
begin
  if v_tipo not in ('whatsapp','llamar') then return; end if;
  if v_origen <> all (array['directo','google','google_negocio','facebook','instagram','whatsapp','mercadolibre','zonaprop','argenprop','youtube','mardelfrentealmar','qr']) then
    v_origen := 'otro';
  end if;

  insert into public.visitas_origen (dia, origen, tipo, total) values (v_dia, v_origen, v_tipo, 1)
  on conflict (dia, origen, tipo) do update set total = public.visitas_origen.total + 1;
end;
$$;

revoke all on function public.registrar_click(text, text) from public;
grant execute on function public.registrar_click(text, text) to anon, authenticated;

-- Que la API vea las funciones nuevas enseguida.
notify pgrst, 'reload schema';
