# M0 — Autenticación y Perfiles

## Contexto
Este módulo gestiona el acceso a la app. El asesor de negocios inicia sesión con su código de empleado y contraseña. No existe registro propio: las cuentas son creadas únicamente por el Administrador. La sesión persiste entre días y se invalida al cerrar sesión o por inactividad prolongada.

---

## HU-01 · Login del asesor de negocios

**Historia:** Como asesor de negocios, quiero iniciar sesión con mi código de empleado y contraseña, para acceder únicamente a las funciones que corresponden a mi perfil desde el dispositivo móvil.

**Criterios de aceptación:**
- El formulario solicita código de empleado (numérico) y contraseña con opción mostrar/ocultar.
- Al autenticar correctamente, la sesión persiste. El asesor no repite login cada día.
- Al superar 5 intentos fallidos, el acceso se bloquea 30 minutos con cuenta regresiva visible.
- La sesión expira si el dispositivo permanece inactivo más de 8 horas.
- No es posible navegar al interior de la app sin haberse autenticado.

**Story points:** 5 | **Perfil:** Operador (asesor de negocios y auxiliar de créditos en campo)

### RF-01 — Formulario de login
- Campo de código de empleado con teclado numérico.
- Campo de contraseña con alternancia ver/ocultar.
- Botón "Ingresar" y enlace "Problemas para ingresar".
- No existe registro propio; cuentas creadas solo por el Administrador.

### RF-02 — Autenticación contra Supabase Auth
- Convertir código de empleado en identificador de correo interno para autenticar contra Supabase Auth.
- Almacenar el token de sesión de forma segura y encriptada en el dispositivo.
- Usar el paquete `flutter_secure_storage` para el almacenamiento del JWT.

### RF-03 — Persistencia y renovación de sesión
- Al relanzar la app con sesión vigente, navegar directamente al Dashboard sin pasar por login.
- Renovar el token automáticamente antes de que expire.

### RF-04 — Bloqueo por intentos fallidos
- Contador local que incrementa en cada error de autenticación.
- Al llegar a 5 errores: deshabilitar el botón con temporizador visible de 30 minutos.
- El bloqueo persiste aunque se cierre y reabra la app.

---

## HU-02 · Perfiles de acceso diferenciados

**Historia:** Como administrador de agencia, quiero que cada usuario vea solo las funciones correspondientes a su perfil, para mantener el control de acceso y evitar operaciones no autorizadas.

**Criterios de aceptación:**
- El sistema maneja cuatro perfiles: Operador, Super Operador, Supervisor y Administrador.
- Operador accede a: Cartera, Ruta, Ficha, Solicitud y Documentos.
- Supervisor accede adicionalmente a: Reportes, Reasignación de tareas y Monitor en mapa.
- Administrador accede a todo, incluyendo gestión de usuarios y configuración.
- El perfil se obtiene del token de sesión y no puede modificarse desde el dispositivo.

**Story points:** 3

### RF-05 — Menú lateral adaptativo por perfil
- El menú lateral muestra únicamente las opciones habilitadas para el perfil autenticado.
- Las opciones no autorizadas **no aparecen**; no se muestran deshabilitadas.

### RF-06 — Roles y sus capacidades

| Perfil | Capacidades principales |
|---|---|
| Operador | Captura de tareas en campo. Solo móvil. |
| Super Operador | Operador + jefe de comité en campo. Acceso a reportes de supervisión web. |
| Supervisor | Administrador de agencia. Gestiona tareas, visualiza reportes y reasigna. |
| Administrador | Todo lo anterior más gestión de usuarios, formularios y configuración. |

---

## HU-03 · Cierre de sesión y borrado de datos sensibles

**Historia:** Como asesor de negocios, quiero cerrar sesión desde el menú lateral, para que mis datos de cartera no sean accesibles si otra persona toma el dispositivo.

**Criterios de aceptación:**
- El menú lateral siempre muestra la opción "Cerrar sesión".
- Al confirmar: se invalida el token en el servidor y se eliminan sesión y cartera en caché local.
- La app navega a la pantalla de login sin posibilidad de volver atrás.
- Si existen solicitudes pendientes de envío, se muestra aviso: _"Tienes X solicitudes sin sincronizar. ¿Cerrar de todas formas?"_

**Story points:** 3

### RF-07 — Flujo de cierre de sesión
Secuencia al confirmar logout:
1. Invalidar token en Supabase.
2. Borrar token local.
3. Borrar tablas de cartera y fichas en caché.
4. Navegar a login limpiando el historial de navegación.

### RF-08 — Advertencia de documentos pendientes
- Antes de cerrar sesión, consultar la cola de solicitudes con `pendiente_sync = true`.
- Si el conteo es mayor a cero, mostrar diálogo de confirmación con el número exacto de registros pendientes.

---

## Estructura de datos relevante

**Tabla: `asesores_negocio`**

| Campo | Tipo | Descripción |
|---|---|---|
| id | UUID (PK) | Identificador único |
| user_id | UUID (FK → auth.users) | Vínculo con Supabase Auth |
| codigo_empleado | VARCHAR(10) UNIQUE | Código de empleado |
| nombres | VARCHAR(100) | Nombres del asesor |
| apellidos | VARCHAR(100) | Apellidos del asesor |
| agencia_id | UUID (FK → agencias) | Agencia a la que pertenece |
| perfil | VARCHAR(20) | operador / super_operador / supervisor / administrador |
| token_fcm | TEXT | Token de dispositivo para notificaciones push |
| activo | BOOLEAN | Si el asesor está habilitado |

> **Restricción:** `user_id` es UNIQUE — un usuario de Supabase Auth corresponde a un solo asesor.

---

## Notas de implementación

- **Paquete de autenticación:** `supabase_flutter ^2.5.0`
- **Almacenamiento seguro del token:** `flutter_secure_storage ^9.2.2`
- **Arquitectura:** El `AuthRepository` decide si el token local sigue vigente antes de intentar renovarlo en Supabase.
- **Navegación:** Usar `GoRouter` con redirección automática a `/login` cuando no hay sesión activa. Limpiar el stack de navegación al hacer logout para que el botón "Atrás" no regrese al interior de la app.
- El perfil del asesor se lee del JWT y se inyecta en un `StateNotifier` global accesible desde cualquier módulo.
