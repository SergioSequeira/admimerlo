# Panel de administración: permisos y sesión (26/11/2026)

Resuelve el error rojo "No se guardó: permission denied for table propiedades" y "No se pudieron leer las visitas: permission denied for table visitas" en https://admimerlo.com.ar/admin.

## Síntoma
- Al guardar una propiedad: `permission denied for table propiedades`.
- En Estadísticas: `permission denied for table visitas` y aviso de que faltaba `migracion-4-origen.sql`.

## Diagnóstico (en orden)
1. **Permisos de la base (GRANT).** Faltaban permisos de escritura para el rol `authenticated` y de lectura de `visitas` / `visitas_origen`. Se corrigieron (ver abajo).
2. **Migración 4.** Ya estaba corrida: existen `visitas_origen`, `registrar_visita(text)` y `registrar_click(text,text)`. Por eso `grant execute on function public.registrar_visita()` (sin argumentos) falla con `42883: function does not exist`. Y como el SQL Editor ejecuta el bloque en una transacción, un error en la última línea deshace todo lo anterior.
3. **Causa real del error persistente.** Con los permisos ya bien, el panel seguía fallando. En los logs de Supabase (Logs → API Gateway / explorer, fuente `edge_logs`) las peticiones `PATCH /rest/v1/propiedades` y `GET /rest/v1/visitas` salían con **401** y con `request.sb.apikey.authorization.prefix = sb_publishable_…`: el encabezado `Authorization` llevaba la clave pública y no el token de la sesión. Supabase lo trata como visitante anónimo (rol `anon`, que solo puede leer) y devuelve "permission denied". El login (`/auth/v1/token`) daba 200: la sesión se creaba, pero el cliente (supabase-js 2.119.2 desde jsDelivr `@2`) no la adjuntaba a los pedidos. No se pudo determinar por qué (el reloj de la PC o el almacenamiento del navegador son hipótesis sin verificar).
4. **Prueba directa en la base.** Simulando el rol `authenticated` con `app_metadata.role = admin`, un `UPDATE` sobre `propiedades` funciona (3 filas coincidentes, cambio deshecho). Es decir, base y políticas RLS estaban bien.

## Qué se cambió

### Base de datos (Supabase, proyecto `dtoccdasexzqifjskapu`)
```sql
grant usage on schema public to anon, authenticated;
grant select on public.propiedades, public.fotos, public.config to anon, authenticated;
grant insert, update, delete on public.propiedades, public.fotos, public.config to authenticated;
grant select on public.visitas to authenticated;
-- execute sobre todas las firmas de registrar_visita / registrar_click (bloque DO, tolerante a la firma)
revoke truncate, trigger, references on all tables in schema public from anon, authenticated;
```
- Estado final: `anon` solo `SELECT` en `config`, `fotos`, `propiedades`; `authenticated` `SELECT/INSERT/UPDATE/DELETE` en esas tres y `SELECT` en `visitas` y `visitas_origen`. `registrar_visita(text)` y `registrar_click(text,text)` ejecutables por `anon`.
- Se quitó `TRUNCATE` (y `TRIGGER`, `REFERENCES`) a `anon` y `authenticated`: `TRUNCATE` se salta las reglas RLS, así que con la clave pública se podían vaciar las tablas.
- Políticas RLS vigentes: lectura pública en `config`, `fotos`, `propiedades`; edición solo con `app_metadata.role = 'admin'` en el token; `visitas` y `visitas_origen` solo lectura para `authenticated`.
- Usuario del panel: `admimerlo@celeflor.com` (rol admin en `app_metadata`).

### Código (`admin.html`, commit `1de2a34` en `main`)
El cliente guarda el token de la sesión y lo envía siempre en `Authorization`:
- `var TOKEN=null;` y `createClient(C.url,C.key,{global:{fetch:…}})` que pone `Authorization: Bearer <TOKEN>` en cada pedido (datos, fotos y estadísticas).
- `TOKEN` se carga en `getSession()`, en `onAuthStateChange` y al terminar `signInWithPassword`.
- Vercel publicó el cambio solo (verificado en admimerlo.com.ar/admin.html).

## Cómo diagnosticar si vuelve a pasar
1. Supabase → Logs → Explorer: `select timestamp, event_message, log_attributes from logs where source='edge_logs' and event_message like '%401%' order by timestamp desc limit 5`.
2. Mirar `request.sb.apikey.authorization.prefix`: si dice `sb_publishable_…`, el panel no está mandando la sesión (problema de código/cliente). Si hay JWT y da 403, es de permisos (GRANT) o RLS.
3. Para permisos: `select table_name, grantee, privilege_type from information_schema.role_table_grants where table_schema='public' and grantee in ('anon','authenticated');`
4. Recordar: un error `permission denied for table …` con 401 = rol `anon`; con 403 = rol `authenticated` sin GRANT.

## Pendientes y avisos
- `supabase.sql` del repo no incluye los GRANT de escritura: si se reinstala la base desde cero hay que correr el bloque de arriba.
- Supabase `@2` sin versión fija en jsDelivr puede cambiar de comportamiento; si se quiere estabilidad, fijar una versión en `admin.html` e `index.html`.
- Chacabuco 455: revisar que el campo "Condiciones propias" no tenga restos de prueba (había un "1" suelto) antes de publicar.
