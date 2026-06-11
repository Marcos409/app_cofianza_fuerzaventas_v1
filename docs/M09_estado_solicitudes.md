# M9 — Estado de Solicitudes

## Contexto
El asesor ve en un tablero visual el estado actualizado de todas sus solicitudes activas, agrupadas por etapa. Las tarjetas se mueven automáticamente de pestaña cuando cambia el estado (Realtime). También puede ver el detalle completo de cada solicitud, incluyendo la línea de tiempo del proceso, y generar un PDF de estado para compartir con el cliente por WhatsApp.

---

## HU-27 · Ver tablero de estado de todas mis solicitudes activas

**Historia:** Como asesor de negocios, quiero ver el estado actualizado de todas mis solicitudes en un tablero visual, para saber en qué etapa está cada expediente y si necesito actuar.

**Criterios de aceptación:**
- Pestañas por estado: **Enviadas / En comité / Aprobadas / Desembolsadas / Rechazadas**.
- Cada pestaña muestra el conteo de solicitudes en ese estado.
- Las tarjetas se mueven automáticamente a la pestaña correcta cuando cambia el estado.
- Filtro por rango de fechas y monto disponible.

**Story points:** 8

### RF-68 — Pestañas con contadores actualizados en tiempo real
- La suscripción Realtime de Supabase actualiza los contadores de cada pestaña.
- Al llegar un cambio de estado, reubicar la tarjeta a la pestaña correspondiente con una **animación de transición**.
- Los contadores se recalculan automáticamente tras cada reubicación.

**Mapeo de estados a pestañas:**

| Estado en BD | Pestaña |
|---|---|
| enviado | Enviadas |
| recibido_comite / en_evaluacion | En comité |
| aprobado / condicionado | Aprobadas |
| desembolsado | Desembolsadas |
| rechazado | Rechazadas |

### RF-69 — Tarjeta de solicitud en el tablero
Cada tarjeta muestra:
- Nombre del cliente.
- Monto solicitado formateado.
- Días transcurridos desde el envío.
- Nombre del analista asignado (si aplica).
- Etiqueta de estado con color correspondiente.

---

## HU-28 · Ver detalle completo de una solicitud enviada

**Historia:** Como asesor de negocios, quiero ver todos los detalles de una solicitud enviada incluyendo el historial de cambios, para responder preguntas del cliente sobre el estado de su expediente.

**Criterios de aceptación:**
- Muestra: datos del solicitante, condiciones del crédito, miniaturas de documentos, línea de tiempo del proceso con marcas de tiempo.
- La línea de tiempo muestra etapas futuras en gris con línea punteada.
- El botón "Compartir estado" genera un PDF de una página enviable por WhatsApp.
- El asesor puede agregar notas internas (privadas, no visibles al cliente).

**Story points:** 5

### RF-70 — Línea de tiempo del proceso
Componente vertical que muestra cada evento con:
- Ícono de estado (completado / activo / pendiente).
- Descripción de la acción.
- Responsable (sistema o nombre del analista).
- Marca de tiempo.

Las **etapas futuras** se dibujan con línea punteada y color gris.

**Secuencia de etapas:**
1. Solicitud enviada
2. Recibida en comité
3. En evaluación
4. Decisión del comité (Aprobado / Condicionado / Rechazado)
5. Desembolso (si aplica)

### RF-71 — Generación de PDF de estado para compartir
Generar un documento PDF de una página usando el paquete `pdf ^3.11.1` con:
- Logo de la institución.
- Datos del cliente (nombre, documento censurado).
- Condiciones del crédito solicitado (monto, plazo, cuota estimada).
- Estado actual con fecha.
- Código QR de seguimiento.

Compartir con `printing ^5.13.2` para abrir el diálogo de compartir del sistema (WhatsApp, correo, etc.).

### RF-72 — Notas internas del asesor
- Campo de texto con máximo 500 caracteres.
- Las notas se guardan en la tabla `solicitudes_notas_internas`.
- Solo el **asesor autor** y el **supervisor de la agencia** pueden verlas.
- El cliente nunca tiene acceso a estas notas.

---

## HU-29 · Recibir notificación de aprobación o rechazo

**Historia:** Como asesor de negocios, quiero recibir un mensaje inmediato cuando el comité decide sobre una solicitud, para comunicarme con el cliente lo antes posible.

**Criterios de aceptación:**
- Las notificaciones se agrupan por asesor en el panel de notificaciones del dispositivo.
- Al deslizar una notificación, se marca como leída en el sistema.
- Ver M8 RF-66 y RF-67 para el contenido y comportamiento de las notificaciones.

**Story points:** 3

### RF-73 — Firebase Cloud Messaging para notificaciones remotas
- Integración con Firebase Cloud Messaging usando el paquete `firebase_messaging ^15.1.3`.
- El token FCM del dispositivo se guarda en el campo `token_fcm` de la tabla `asesores_negocio` al iniciar sesión.
- El servidor dispara el mensaje push cuando cambia el estado de la solicitud en Supabase.

### RF-74 — Agrupación de notificaciones en el dispositivo
- Las notificaciones del mismo asesor se agrupan bajo un mismo grupo en el panel de notificaciones de Android.
- Resumen expandible que muestra todas las solicitudes con cambio de estado reciente.
- Implementar con el parámetro `groupKey` de `flutter_local_notifications`.

---

## Estructura de datos relevante

**Tabla: `solicitudes_notas_internas`**

| Campo | Tipo | Descripción |
|---|---|---|
| id | UUID (PK) | Identificador único |
| solicitud_id | UUID (FK → solicitudes_credito) | Solicitud asociada |
| asesor_id | UUID (FK → asesores_negocio) | Asesor que escribió la nota |
| contenido | TEXT | Texto de la nota (máximo 500 caracteres) |
| created_at | TIMESTAMPTZ | Fecha de creación |

---

## Notas de implementación

- **Paquetes relevantes:** `supabase_flutter`, `firebase_messaging ^15.1.3`, `flutter_local_notifications ^17.2.2`, `pdf ^3.11.1`, `printing ^5.13.2`
- **ViewModel:** `EstadoSolicitudesViewModel` mantiene una lista reactiva agrupada por estado. La suscripción Realtime actualiza el estado inmediatamente al recibir cambios.
- **Línea de tiempo:** implementar como widget personalizado en `shared/widgets/` usando un `ListView` con `CustomPaint` para las líneas conectoras. Las etapas se construyen a partir del historial de cambios de `updated_at` y `estado` de la solicitud.
- **PDF:** el logo de la institución se embebe como imagen desde los assets. El código QR se genera con el paquete `qr_flutter` usando el número de expediente como dato.
- **RLS de Supabase:** la tabla `solicitudes_notas_internas` tiene políticas que permiten leer solo a `asesor_id = auth.uid()` o a usuarios con `perfil = supervisor` de la misma agencia.
- **Filtros:** implementar el filtro por rango de fechas y monto sobre los datos locales (ya descargados via Realtime) para evitar consultas adicionales a la red.
