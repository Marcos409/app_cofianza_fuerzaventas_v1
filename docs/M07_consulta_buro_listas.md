# M7 — Consulta de Buró y Listas Negras

## Contexto
Antes de enviar la solicitud al comité, el asesor consulta el historial crediticio del cliente en las centrales de riesgo y verifica que no esté en listas de restricción. La consulta requiere firma digital de consentimiento del cliente (Ley 29733 de Protección de Datos Personales). Si el cliente realizó una consulta en los últimos 30 días, el sistema ofrece reutilizar ese resultado para no impactar su historial.

> **Nota de implementación del curso:** Las Edge Functions de buró son simuladas (mock). En producción conectarían con los servicios reales de la SBS, Equifax o Experian.

---

## HU-23 · Consultar historial en centrales de riesgo en campo

**Historia:** Como asesor de negocios, quiero consultar el reporte crediticio del cliente durante la visita, para tomar una decisión informada sobre la solicitud sin regresar a la oficina.

**Criterios de aceptación:**
- La consulta requiere firma digital de consentimiento del cliente (Ley de Protección de Datos Personales, Ley 29733).
- El resultado muestra: calificación SBS, número de entidades con deuda activa, deuda total en el sistema, mayor deuda individual y días de mayor mora histórica.
- El semáforo de resultado sigue la misma codificación que la ficha del cliente (ver M3 RF-28).
- La consulta queda registrada con marca de tiempo como evidencia de auditoría.
- Si existe una consulta del mismo cliente realizada en los **últimos 30 días**, el sistema ofrece reutilizar ese resultado.

**Story points:** 8

### RF-57 — Consentimiento previo a la consulta
- Antes de ejecutar la consulta, mostrar el texto legal de autorización completo (Ley 29733).
- El cliente firma en el lienzo táctil (`SignaturePad`).
- La firma y la marca de tiempo se guardan como evidencia junto al resultado.
- **No es posible continuar sin la firma.**

### RF-58 — Integración con Edge Function de buró (simulada para el curso)
- Invocar la Supabase Edge Function `consulta-buro` con el número de documento.
- La función devuelve en formato JSON:

| Campo devuelto | Tipo | Descripción |
|---|---|---|
| calificacion_sbs | STRING | Normal / CPP / Deficiente / Dudoso / Pérdida |
| num_entidades_deuda | INTEGER | Número de entidades con deuda activa |
| deuda_total | DECIMAL | Deuda total en el sistema (soles) |
| mayor_deuda | DECIMAL | Mayor deuda individual |
| dias_mayor_mora | INTEGER | Días de mayor mora histórica |

### RF-59 — Interpretación automática del resultado
- El sistema genera un texto interpretativo en lenguaje natural basado en el resultado.
- Ejemplo: _"El cliente tiene historial en 2 entidades con deuda total de S/15,400. Sin mora histórica. Recomendación: proceder con la evaluación."_
- El texto se genera localmente en el ViewModel a partir de los datos devueltos.

---

## HU-24 · Consultar listas de restricción y alerta de fraude

**Historia:** Como asesor de negocios, quiero verificar si el cliente aparece en listas de restricción, para no iniciar procesos con personas inhabilitadas.

**Criterios de aceptación:**
- La consulta verifica la lista interna de la institución y las listas de inhabilitados del sistema financiero.
- Si aparece en una lista, se muestra un aviso **bloqueante** en rojo con el motivo.
- Si está limpio, se muestra confirmación en verde y se permite continuar.
- El resultado queda registrado en el expediente.

**Story points:** 3

### RF-60 — Consulta combinada buró + listas negras
- Un único endpoint verifica ambas fuentes y devuelve:

| Campo | Tipo | Descripción |
|---|---|---|
| en_lista_negra | BOOLEAN | Si el cliente está bloqueado |
| motivo_bloqueo | TEXT | Motivo si aplica |
| resultado_buro | OBJECT | Resultado completo del buró |

- Si `en_lista_negra = true`: **el formulario de solicitud no puede abrirse** para ese cliente mientras persista el bloqueo.

### RF-61 — Pantalla de resultado de verificación

**Si el cliente está bloqueado:**
- Diálogo modal con fondo rojo.
- Texto del motivo.
- Único botón: "Entendido".
- El formulario de solicitud permanece inaccesible.

**Si está limpio:**
- Indicador verde.
- Acceso habilitado al formulario.

---

## Estructura de datos relevante

**Tabla: `consultas_buro`**

| Campo | Tipo | Descripción |
|---|---|---|
| id | UUID (PK) | Identificador único |
| asesor_id | UUID (FK → asesores_negocio) | Asesor que realizó la consulta |
| cliente_id | UUID (FK → clientes) | Cliente consultado |
| dni_consultado | VARCHAR(15) | Documento consultado |
| calificacion_sbs | VARCHAR(20) | Calificación obtenida |
| entidades_con_deuda | INTEGER | Número de entidades con deuda activa |
| deuda_total_pen | DECIMAL(12,2) | Deuda total en soles |
| mayor_deuda | DECIMAL(12,2) | Mayor deuda individual |
| dias_mayor_mora | INTEGER | Días de mayor mora histórica |
| resultado_json | JSONB | Respuesta completa de la fuente |
| firma_consentimiento_base64 | TEXT | Firma de consentimiento del cliente |
| solicitud_id | UUID (FK → solicitudes_credito) | Solicitud vinculada (opcional) |
| created_at | TIMESTAMPTZ | Fecha y hora de la consulta |

---

## Notas de implementación

- **Paquetes relevantes:** `supabase_flutter`, `signature ^5.4.1`
- **ViewModel:** `BuroViewModel` gestiona el flujo: `esperandoConsentimiento` → `firmando` → `consultando` → `resultado(datos)` / `bloqueado(motivo)`.
- **Reutilización de consulta reciente:** Al abrir la pantalla de buró, primero consultar `consultas_buro` filtrando por `cliente_id` y `created_at >= fecha_actual - 30 días`. Si existe, mostrar un banner: _"Existe una consulta de hace X días. ¿Usar ese resultado o realizar una nueva consulta?"_
- **Texto interpretativo:** implementar como función pura `interpretarResultadoBuro(datos)` en `utils/buro_interpreter.dart`. Construye el texto a partir de reglas condicionales sobre calificación, deuda y mora.
- **Auditoría:** guardar siempre el registro en `consultas_buro` incluyendo la firma de consentimiento, independientemente de si se reutilizó un resultado previo.
- **Seguridad de datos:** el `resultado_json` completo de la central de riesgo se guarda en la columna JSONB para trazabilidad, pero **no se muestra** al asesor en su totalidad; solo los campos resumidos definidos en RF-58.
