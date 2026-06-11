# M4 — Pre-evaluación y Prospección

## Contexto
El asesor puede pre-evaluar a un prospecto nuevo en campo antes de iniciar el proceso formal, y gestionar las campañas de renovación y ampliación activas para clientes existentes. Si no hay conexión, la pre-evaluación queda en cola y se procesa al reconectar.

---

## HU-15 · Pre-evaluar a un prospecto en campo

**Historia:** Como asesor de negocios, quiero registrar datos básicos de un prospecto y obtener una pre-evaluación crediticia en campo, para saber si el prospecto califica antes de iniciar el proceso formal.

**Criterios de aceptación:**
- El formulario captura: documento, nombres, tipo de negocio, ingresos estimados, destino del crédito y monto solicitado.
- Al pulsar "Pre-evaluar", el sistema consulta la posición del prospecto en el sistema financiero.
- El resultado indica: **APTO** (continuar evaluación), **REVISAR** (requiere análisis adicional) o **NO PROCEDE**.
- Si está apto, el botón "Iniciar solicitud formal" abre el formulario completo con datos prellenados.
- Sin conexión, la pre-evaluación queda en cola y se procesa al reconectar.

**Story points:** 8

### RF-37 — Formulario de prospección

| Campo | Tipo | Validación |
|---|---|---|
| Número de documento | Numérico | 8 dígitos exactos |
| Nombres | Texto | Obligatorio, solo letras |
| Apellidos | Texto | Obligatorio |
| Fecha de nacimiento | Selector de fecha | — |
| Tipo de negocio | Lista desplegable | Obligatorio |
| Antigüedad del negocio | Numérico (años + meses) | — |
| Ingresos estimados mensuales | Decimal | Mayor que cero |
| Monto solicitado | Control deslizante | Entre S/500 y S/50,000 |
| Destino del crédito | Texto libre | Obligatorio |

### RF-38 — Consulta en línea al sistema de pre-evaluación
- Invocar la Supabase Edge Function `pre-evaluar` con los datos del prospecto.
- La función devuelve:
  - `calificacion`: APTO / REVISAR / NO PROCEDE
  - `motivo`: motivo en caso de restricción
  - `puntaje_estimado`: puntaje interno estimado

### RF-39 — Presentación visual del resultado de pre-evaluación

| Resultado | Color de fondo | Etiqueta visible | Acción disponible |
|---|---|---|---|
| APTO | Verde | Puede continuar la evaluación | Iniciar solicitud formal |
| REVISAR | Amarillo | Requiere análisis adicional | Registrar observaciones |
| NO PROCEDE | Rojo | No cumple condiciones | Informar al cliente |

---

## HU-16 · Gestionar campañas de renovaciones y ampliaciones

**Historia:** Como asesor de negocios, quiero ver los clientes con oferta de renovación o ampliación activa en mi cartera, para gestionar campañas comerciales sin perder oportunidades del período.

**Criterios de aceptación:**
- Una sección "Campañas activas" en el dashboard muestra las ofertas vigentes del período.
- Cada oferta indica: tipo (renovación / ampliación / producto paralelo), monto ofertado, fecha de vencimiento y cliente al que aplica.
- Al gestionar una oferta en campo, el sistema inicia el proceso de solicitud con datos prellenados.
- Las ofertas expiradas se marcan automáticamente como vencidas al día siguiente.

**Story points:** 5

### RF-40 — Consulta de campañas activas
- Consultar la tabla `campanas_activas` con los filtros:
  - `asesor_id` = asesor autenticado
  - `activa = true`
  - `fecha_vencimiento >= fecha actual`
- Ordenar por `fecha_vencimiento` ascendente (más próximas a expirar primero).

### RF-41 — Tarjeta de campaña activa
Cada tarjeta muestra:
- Etiqueta del tipo con color diferenciado (renovación: azul, ampliación: verde, producto paralelo: naranja).
- Nombre del cliente.
- Monto de la oferta formateado.
- Cuenta regresiva de días restantes.
- Botón "Gestionar ahora" → navega al formulario de solicitud con datos prellenados.

### RF-42 — Registro de cliente desertor
Para clientes desertores, el formulario captura:

| Campo | Tipo |
|---|---|
| Motivo de deserción | Lista predefinida |
| Institución a la que migró | Texto libre (opcional) |
| Probabilidad de retorno | Alta / Media / Baja |
| Observaciones | Texto libre |

---

## Notas de implementación

- **Paquetes relevantes:** `supabase_flutter`, `sqflite`, `connectivity_plus`
- **ViewModel:** `ProspeccionViewModel` gestiona el estado del formulario y el resultado de la pre-evaluación. Usa un estado con variantes: `inicial`, `cargando`, `resultado(calificacion)`, `error`.
- **Offline:** Si no hay red al pulsar "Pre-evaluar", guardar los datos del prospecto en la tabla local `pre_evaluaciones_pendientes` con `pendiente_sync = true`. Al reconectar, procesar la cola y mostrar el resultado al asesor mediante notificación local.
- **Prellenado del formulario de solicitud:** Al pasar a "Iniciar solicitud formal", navegar a M5 pasando los datos del prospecto como argumentos de ruta (`GoRouter`). El `SolicitudViewModel` recibe estos datos y prellena el Paso 1.
- Las campañas activas se descargan durante la sincronización nocturna (M1 RF-13) y se leen de caché local durante el día.
