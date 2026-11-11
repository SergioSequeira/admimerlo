-- Administración Merlo — base de datos del panel de administración
-- Pegar este archivo completo en Supabase > SQL Editor > New query > Run.
-- Se puede volver a correr: no borra datos existentes.

create extension if not exists pgcrypto;

-- ---------- Tablas ----------
create table if not exists public.propiedades (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null,
  titulo      text not null,
  etiqueta    text default 'Merlo centro',
  ambientes   text,
  descripcion text,
  precio      text,          -- texto libre: "$ 450.000" / vacío = "consultar"
  ajuste      text,          -- ej: "Ajuste trimestral por ICL"
  condiciones text,          -- condiciones propias de esta propiedad (opcional)
  youtube     text,          -- link al video de YouTube (opcional)
  disponible  boolean not null default true,
  orden       integer not null default 0,
  creado      timestamptz not null default now(),
  actualizado timestamptz not null default now()
);

create table if not exists public.fotos (
  id           uuid primary key default gen_random_uuid(),
  propiedad_id uuid not null references public.propiedades(id) on delete cascade,
  url          text not null,
  orden        integer not null default 0,
  creado       timestamptz not null default now()
);
create index if not exists fotos_propiedad_idx on public.fotos(propiedad_id, orden);

-- Textos generales de la web (una fila por clave)
create table if not exists public.config (
  clave text primary key,
  valor text
);

-- actualizado = now() en cada cambio
create or replace function public.set_actualizado() returns trigger
language plpgsql as $$ begin new.actualizado = now(); return new; end $$;
drop trigger if exists propiedades_actualizado on public.propiedades;
create trigger propiedades_actualizado before update on public.propiedades
  for each row execute function public.set_actualizado();

-- ---------- Seguridad (RLS) ----------
-- Público: solo lectura. Usuario logueado en el panel: todo.
alter table public.propiedades enable row level security;
alter table public.fotos       enable row level security;
alter table public.config      enable row level security;

drop policy if exists "publico lee propiedades" on public.propiedades;
create policy "publico lee propiedades" on public.propiedades
  for select to anon, authenticated using (true);
drop policy if exists "admin edita propiedades" on public.propiedades;
create policy "admin edita propiedades" on public.propiedades
  for all to authenticated using (true) with check (true);

drop policy if exists "publico lee fotos" on public.fotos;
create policy "publico lee fotos" on public.fotos
  for select to anon, authenticated using (true);
drop policy if exists "admin edita fotos" on public.fotos;
create policy "admin edita fotos" on public.fotos
  for all to authenticated using (true) with check (true);

drop policy if exists "publico lee config" on public.config;
create policy "publico lee config" on public.config
  for select to anon, authenticated using (true);
drop policy if exists "admin edita config" on public.config;
create policy "admin edita config" on public.config
  for all to authenticated using (true) with check (true);

-- ---------- Storage: bucket público "fotos" ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos', 'fotos', true, 8388608, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true;

drop policy if exists "publico ve fotos" on storage.objects;
create policy "publico ve fotos" on storage.objects
  for select to anon, authenticated using (bucket_id = 'fotos');
drop policy if exists "admin sube fotos" on storage.objects;
create policy "admin sube fotos" on storage.objects
  for insert to authenticated with check (bucket_id = 'fotos');
drop policy if exists "admin cambia fotos" on storage.objects;
create policy "admin cambia fotos" on storage.objects
  for update to authenticated using (bucket_id = 'fotos');
drop policy if exists "admin borra fotos" on storage.objects;
create policy "admin borra fotos" on storage.objects
  for delete to authenticated using (bucket_id = 'fotos');

-- ---------- Datos iniciales (lo que hoy está en la web) ----------
insert into public.propiedades (slug, titulo, etiqueta, descripcion, orden) values
 ('rosas',      'Rosas 757',           'Merlo centro',  'Edificio con balcones sobre la calle y entrada amplia con piso de porcelanato. Departamentos con cocina equipada y buena luz natural.', 1),
 ('avellaneda', 'Avellaneda 600',      'Merlo centro',  'Departamentos en un edificio con ingreso por pasillo y galería. Ambientes luminosos con ventilador de techo.', 2),
 ('chacabuco',  'Chacabuco 400-500',   'Merlo centro',  'Complejo de ladrillo a la vista con jardín al frente. Departamentos con pisos de madera y porcelanato, y balcón.', 3),
 ('mendoza',    'Mendoza 630, chalet', 'Casa en Merlo', 'Chalet de ladrillo con jardín, parrilla y galería. Cocina con mesada de granito y ambientes amplios con ventanas al verde.', 4)
on conflict (slug) do nothing;

-- Las 5 fotos actuales de cada propiedad (están en la carpeta img/ del sitio)
insert into public.fotos (propiedad_id, url, orden)
select p.id, 'img/' || p.slug || '-' || n || '.jpg', n
from public.propiedades p, generate_series(0, 4) as n
where not exists (select 1 from public.fotos f where f.propiedad_id = p.id);

insert into public.config (clave, valor) values
 ('whatsapp',     '5491160151357'),
 ('intro_titulo', 'Departamentos y casas para alquilar'),
 ('intro_texto',  'Mirá las fotos y consultá disponibilidad y costos por WhatsApp. Te pasamos también videos de cada propiedad.'),
 ('condiciones',  '')
on conflict (clave) do nothing;

-- Mejoras de la ficha y preguntas frecuentes: ver migracion-2-mejoras.sql (correrlo después de este archivo).
