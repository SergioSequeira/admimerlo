-- Administración Merlo — precio de Chacabuco ($485.000, vigente al 24/11/2026).
-- Pegar en Supabase > SQL Editor > New query > Run. Se puede correr más de una vez.
update public.propiedades
   set precio = '485000',
       precio_fecha = '2026-11-24',
       ajuste = coalesce(nullif(ajuste, ''), 'Ajuste trimestral por IPC')
 where slug = 'chacabuco';
