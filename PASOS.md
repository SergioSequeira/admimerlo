# Puesta en marcha del panel de administración

La web (`index.html`) y el panel (`admin.html`) ya están subidos. Falta conectar la base de datos. Son 4 pasos, una sola vez, unos 15 minutos.

## 1. Crear el proyecto en Supabase (cuenta nueva)

1. Entrar a https://supabase.com con el mail que quieras usar para esta cuenta nueva (no el de shoppylandia / Mardelfrentealmar).
2. **New project** → nombre `admimerlo`, región **South America (São Paulo)**, plan Free. Anotar la contraseña de la base (no se usa en el panel, pero Supabase la pide).
3. Esperar 1-2 minutos a que el proyecto quede "Active".

## 2. Crear las tablas

1. En el menú izquierdo: **SQL Editor** → **New query**.
2. Pegar el contenido completo del archivo `supabase.sql` de este repo y tocar **Run**.
3. Tiene que decir "Success". Eso crea las tablas, las reglas de seguridad, el espacio de fotos y carga las 4 propiedades actuales.

## 3. Crear tu usuario del panel

1. **Authentication** → **Users** → **Add user** → **Create new user**.
2. Poner tu email y una contraseña fuerte. Tildar **Auto Confirm User**.
3. Con ese email y contraseña vas a entrar al panel. Se pueden crear más usuarios después (por ejemplo para Flavia).

## 4. Conectar la web con la base

1. **Project Settings** → **API**. Copiar:
   - **Project URL** (algo como `https://abcdefgh.supabase.co`)
   - **Publishable key** (`sb_publishable_...`). Si solo aparece la "anon public" key, sirve igual.
2. Pasármelos por el chat, o editarlos vos en GitHub: abrir `config.js` en https://github.com/SergioSequeira/admimerlo, lápiz, completar `url` y `key`, **Commit changes**.
3. Vercel vuelve a publicar solo en un minuto.

Listo. El panel queda en **https://admimerlo.com.ar/admin**.

---

## Cómo se usa el panel

- **Propiedades**: elegí una de la lista para editar título, etiqueta, ambientes, descripción, precio, ajuste, condiciones propias y link de YouTube. "Guardar cambios" impacta en la web al instante.
- **Fotos**: aparecen abajo del formulario. "Agregar fotos" o arrastrar; se achican solas antes de subir. ◀ ▶ ordenan, ★ hace portada, ✕ borra.
- **Ocultar una unidad alquilada**: destildar "Visible en la web" y guardar. No se borra, se puede volver a mostrar.
- **Orden en la web**: flechas ▲▼ en la lista.
- **Textos generales**: WhatsApp, título y texto de portada, y el bloque de **condiciones generales de alquiler** que aparece al final de la web.
- **Nueva propiedad**: botón "+ Nueva propiedad", completar, guardar, y recién ahí subir fotos.

## Seguridad

- La clave de `config.js` es pública por diseño: solo permite **leer**. Para escribir hay que estar logueado; eso lo controlan las reglas (RLS) creadas por `supabase.sql`.
- No publicar nunca la clave `service_role` ni la contraseña de la base.
- Si perdés la contraseña del panel: Supabase → Authentication → Users → tu usuario → "Send password recovery" o "Reset password".

## Límites del plan gratuito de Supabase

- 1 GB de almacenamiento de fotos (a ~300 KB por foto son más de 3.000 fotos).
- El proyecto se **pausa si pasa 7 días sin uso**; las visitas a la web cuentan como uso, pero si la web queda sin visitas una semana hay que entrar al panel de Supabase y tocar "Restore". Mientras está pausado la web muestra los datos de respaldo fijos (las 4 propiedades originales, sin precios).

## Mejoras de la ficha (paso extra, una sola vez)

Correr `migracion-2-mejoras.sql` en Supabase > SQL Editor. Habilita en el panel: superficie, expensas, estado (Reservado), ubicación para el mapa y "precio vigente al...", y carga las preguntas frecuentes iniciales (editables en Textos generales). Hasta que se corra, la web funciona igual sin esos datos.

---

## Contador de visitas y estadísticas (12/11/2026)

La web cuenta las visitas sin mostrarlas al público. Los números se ven solo en el panel: **https://admimerlo.com.ar/admin → pestaña "Estadísticas"** (hay que estar logueado).

### Qué hay en el repo
- `index.html`: al cargar, llama una vez por sesión del navegador a la función `registrar_visita()` de Supabase. Recargar la página no vuelve a contar (se usa `sessionStorage`). Si Supabase no responde, no pasa nada y la web funciona igual.
- `admin.html`: pestaña **Estadísticas** con total acumulado, hoy, últimos 7 días, últimos 30 días, gráfico de barras de 30 días y tabla día por día.
- `migracion-3-contador.sql`: crea la tabla `visitas` y la función `registrar_visita()`. Se puede correr más de una vez sin romper nada.

### Cómo funciona la base
- Tabla `public.visitas (dia date primary key, total integer)`: una fila por día, con el día en hora de Argentina.
- Seguridad (RLS) activada: el público **no puede leer ni escribir** la tabla; solo un usuario logueado (el panel) puede leerla.
- Función `registrar_visita()` (`security definer`, no devuelve nada): suma 1 al día de hoy. Es lo único que puede ejecutar un visitante anónimo, por eso no puede ver ni alterar los números.

### Estado
- SQL corrido el 12/11/2026 en el proyecto Supabase `dtoccdasexzqifjskapu` (SQL Editor, consulta "Contador diario de visitas (Argentina)"). Verificado: función creada, 1 política, RLS activo, el anónimo puede ejecutar la función pero no leer la tabla.
- Las estadísticas empiezan en 0 desde ese día (no hay historial anterior).

### Límites a tener en cuenta
- No cuenta personas únicas: quien vuelve otro día o desde otro navegador suma de nuevo.
- Algunos robots y buscadores que ejecutan JavaScript también pueden sumar.
- Si el proyecto de Supabase se pausa por 7 días sin uso, no se registran visitas hasta restaurarlo.

### Cómo volver a instalarlo (si se recrea el proyecto de Supabase)
1. Supabase → SQL Editor → New query → pegar `migracion-3-contador.sql` → Run (confirmar el aviso de "operaciones destructivas": son solo `drop ... if exists` del propio contador).
2. Entrar a la web y después a `/admin` → Estadísticas: tiene que aparecer 1 visita hoy.
