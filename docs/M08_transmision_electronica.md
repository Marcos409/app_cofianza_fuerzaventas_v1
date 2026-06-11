# M8 — Transmisión Electrónica al Sistema Central

## Contexto
El asesor envía la solicitud completa (formulario + documentos + buró + firma) al sistema central en un único proceso atómico con soporte de reanudación. El comité recibe la solicitud en minutos y el asesor recibe notificaciones en tiempo real ante cada cambio de estado.

---

## HU-25 · Enviar solicitud completa con todos los documentos

**Historia:** Como asesor de negocios, quiero transmitir electrónicamente la solicitud completa al sistema central en un solo proceso, para que el comité la reciba de inmediato y pueda evaluarla el mismo día.

**Criterios de aceptación:**
- El botón "Enviar al comité" verifica que estén completos: todos los documentos obligatorios, el formulario completo, el reporte de buró o justificación de omisión, y la firma del cliente.
- Una pantalla de progreso muestra los pasos: Validando datos → Subiendo documentos (N de M) → Registrando en sistema central → Asignando expediente → Solicitud enviada.
- Si el proceso falla a mitad, puede **reanudarse** desde el último paso completado.
- Al finalizar, se muestra el número de expediente oficial y el tiempo estimado de respuesta.
- El asesor recibe notificación de confirmación.

**Story points:** 8

### RF-62 — Validación previa al envío
Antes de iniciar la transmisión, verificar:

| Check | Condición |
|---|---|
| Documentos obligatorios | Todos en estado LISTO (dni_anverso, dni_reverso, foto_negocio, foto_visita) |
| Completitud del formulario | Todos los campos obligatorios de los 4 pasos completados |
| Firma del cliente | `firma_cliente_base64` presente y no vacía |
| Resultado del buró | Registro en `consultas_buro` vinculado a la solicitud, o justificación de omisión ingresada |

Si hay errores: mostrar la **lista completa de elementos faltantes** antes de permitir el envío.

### RF-63 — Pantalla de progreso del envío
Indicador vertical de pasos con tres estados visuales por etapa:

| Estado | Visual |
|---|---|
| Pendiente | Círculo vacío con línea punteada |
| En proceso | Indicador de carga circular animado |
| Completado | Marca de verificación verde |

**Etapas del proceso:**
1. Validando datos
2. Subiendo documentos (N de M)
3. Registrando en sistema central
4. Asignando expediente
5. Solicitud enviada ✓

### RF-64 — Transmisión atómica con soporte de reanudación
- El estado del proceso se guarda localmente en SQLite después de cada paso exitoso.
- Si la transmisión se interrumpe (cierre de app, pérdida de conexión):
  - Al reintentar, el sistema lee el estado guardado.
  - Salta directamente al **primer paso no completado**.
- El estado de reanudación incluye: `paso_completado` (1-4), `solicitud_id`, `documentos_subidos[]`.

### RF-65 — Subida paralela de documentos
- Los documentos se suben en **paralelo** usando operaciones asíncronas concurrentes (`Future.wait`).
- El contador "Subiendo documentos (N de M)" se actualiza conforme completa cada subida.
- Minimiza el tiempo total de transmisión respecto a la subida secuencial.

---

## HU-26 · Recibir confirmación del comité en tiempo real

**Historia:** Como asesor de negocios, quiero recibir notificación cuando el comité confirme la recepción y cuando tome una decisión, para comunicarme con el cliente sin necesidad de consultar manualmente el sistema.

**Criterios de aceptación:**
- Notificación al recibir la solicitud en el comité (menos de 5 minutos tras el envío).
- Notificación al aprobar: incluye monto aprobado y fecha estimada de desembolso.
- Notificación al rechazar: incluye motivo del rechazo.
- Notificación al desembolsar: el cliente puede retirar en agencia.
- Al tocar cualquier notificación, abre directamente el detalle de esa solicitud.

**Story points:** 3

### RF-66 — Suscripción Realtime para cambios de estado
- Suscribirse al canal Realtime de Supabase para actualizaciones en la tabla `solicitudes_credito` donde `asesor_id` coincide con el usuario autenticado.
- Al recibir un cambio de estado: actualizar el ViewModel y emitir la notificación correspondiente.

### RF-67 — Contenido de notificaciones push por estado

| Estado | Título | Cuerpo |
|---|---|---|
| recibido_comite | Solicitud recibida | `{Cliente}` — Expediente `{num}` en evaluación |
| aprobado | Crédito aprobado | `{Cliente}` — S/`{monto}` aprobado. Desembolso: `{fecha}` |
| condicionado | Solicitud condicionada | `{Cliente}` — `{condicion_adicional}` |
| rechazado | Solicitud rechazada | `{Cliente}` — `{motivo_rechazo}` |
| desembolsado | Crédito desembolsado | `{Cliente}` puede retirar en agencia |

---

## Estructura de datos relevante

**Tabla: `solicitudes_credito`** _(campos de estado relevantes para este módulo)_

| Campo | Tipo | Descripción |
|---|---|---|
| estado | VARCHAR(30) | borrador / enviado / recibido_comite / en_evaluacion / aprobado / condicionado / rechazado / desembolsado |
| monto_aprobado | DECIMAL(12,2) | Monto aprobado por el comité |
| motivo_rechazo | TEXT | Motivo del rechazo si aplica |
| condicion_adicional | TEXT | Condición adicional si aplica |
| analista_asignado | VARCHAR(100) | Analista del comité asignado |
| pendiente_sync | BOOLEAN | Si está pendiente de sincronización offline |

---

## Notas de implementación

- **Paquetes relevantes:** `supabase_flutter`, `firebase_messaging ^15.1.3`, `flutter_local_notifications ^17.2.2`
- **ViewModel:** `TransmisionViewModel` gestiona el flujo de envío con el estado: `pasoActual`, `documentosCompletados`, `expedienteGenerado`, `error`.
- **Subida paralela:** usar `Future.wait([subida1, subida2, subida3, subida4])` del paquete `dart:async`. Manejar errores individuales con `catchError` para no cancelar las demás subidas si una falla.
- **Reanudación:** almacenar el progreso en la tabla local `transmision_estado` con los campos `solicitud_id`, `paso_completado` (INTEGER 0-4), `documentos_subidos` (JSON array de tipos completados) y `updated_at`.
- **FCM:** el token FCM del dispositivo se guarda en `asesores_negocio.token_fcm` al iniciar sesión (ver M0). El servidor backend dispara el mensaje via FCM cuando cambia el estado de la solicitud.
- **Notificaciones al tocar:** implementar `onMessageOpenedApp` de `firebase_messaging` para navegar al detalle de la solicitud correspondiente cuando el asesor toca la notificación desde el panel de notificaciones del dispositivo.
