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
