-- Ejecutar en el SQL Editor del proyecto AdmiMerlo.
-- Mantiene las políticas de seguridad de filas existentes.
begin;
grant select on table public.propiedades to authenticated;
grant update (orden) on table public.propiedades to authenticated;
commit;

select has_table_privilege('authenticated', 'public.propiedades', 'select') as puede_leer,
       has_column_privilege('authenticated', 'public.propiedades', 'orden', 'update') as puede_editar_orden;
