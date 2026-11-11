-- Administración Merlo — mejoras de la ficha (superficie, expensas, estado, mapa, fecha de precio) y preguntas frecuentes.
-- Pegar en Supabase > SQL Editor > New query > Run. Se puede correr más de una vez sin romper nada.

alter table public.propiedades add column if not exists superficie    text;  -- ej: "45 m²"
alter table public.propiedades add column if not exists expensas      text;  -- ej: "$ 60.000 aprox."
alter table public.propiedades add column if not exists estado        text not null default 'disponible'; -- 'disponible' | 'reservado'
alter table public.propiedades add column if not exists mapa          text;  -- dirección para el mapa (vacío = usa el título + Merlo)
alter table public.propiedades add column if not exists precio_fecha  date;  -- "precio vigente al ..."

-- La fecha del precio arranca hoy para las que ya tienen precio cargado
update public.propiedades set precio_fecha = current_date where precio is not null and precio <> '' and precio_fecha is null;

-- Preguntas frecuentes (solo con datos ya publicados en las condiciones; editables desde el panel > Textos generales)
insert into public.config (clave, valor) values
 ('faq', E'¿Cómo coordino una visita?\nEscribinos por WhatsApp y coordinamos tu visita en el día.\n\n¿Qué incluyen las expensas?\nCubren impuestos, luz del consorcio y limpieza. No incluyen la luz de la unidad.\n\n¿Cómo se actualiza el alquiler?\nEl valor se actualiza cada trimestre según IPC.\n\n¿Cuánto es la seña?\nLa seña mínima es de $200.000 y se descuenta del total.\n\n¿Dónde quedan las propiedades?\nEn el centro de Merlo, cerca de la estación y de la municipalidad. Los departamentos tienen parque para tu mascota.'),
 ('resenas_url', '')
on conflict (clave) do nothing;
