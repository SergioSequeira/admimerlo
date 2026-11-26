-- Ejecutar en Supabase si el panel recibe permission denied para visitas_origen.
-- Conserva las políticas de seguridad de filas existentes.
grant select on table public.visitas_origen to authenticated;

select has_table_privilege('authenticated', 'public.visitas_origen', 'select') as puede_leer_origen;
