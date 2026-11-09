// Datos de conexión a Supabase (proyecto propio de Administración Merlo).
// Se obtienen en Supabase > Project Settings > API:
//   url: "Project URL"            -> https://xxxxxxxx.supabase.co
//   key: "Publishable key" (sb_publishable_...) o la "anon public" key.
// Esta clave es pública por diseño: solo permite leer; escribir exige iniciar sesión en el panel.
// Mientras url esté vacío, la web muestra los datos fijos de respaldo.
window.ADMI = {
  url: "",
  key: ""
};
