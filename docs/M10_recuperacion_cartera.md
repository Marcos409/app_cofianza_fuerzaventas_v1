# M10 — Recuperación de Cartera Vencida

## Contexto
El asesor gestiona las cobranzas de clientes con cuotas vencidas. Visualiza la lista de mora ordenada por urgencia, registra cada gestión de cobranza con coordenadas GPS y programar alertas automáticas para los compromisos de pago acordados con el cliente.

---

## HU-30 · Ver listado de mora diaria

**Historia:** Como asesor de negocios, quiero ver la lista de mis clientes con cuotas vencidas ordenada por urgencia, para priorizar las gestiones de cobranza del día.

**Criterios de aceptación:**
- La lista muestra: cliente, días de mora, monto vencido y fecha del último contacto.
- Ordenada por días de mora descendente (mayor urgencia primero).
- Semáforo de días de mora: 1 a 30 días = amarillo, 31 a 60 = naranja, más de 60 = rojo.
- Un indicador en el encabezado muestra el monto total vencido de la cartera del asesor.

**Story points:** 5

### RF-75 — Consulta de mora diaria
- Consultar la tabla `cartera_vencida` con los filtros:
  - `asesor_id` = asesor autenticado
  - `dias_mora > 0`
- Ordenar por `dias_mora` descendente.

### RF-76 — Codificación de color por días de mora

| Rango de días | Color de etiqueta | Urgencia |
|---|---|---|
| 1 a 30 días | Amarillo | Seguimiento preventivo |
| 31 a 60 días | Naranja | Gestión prioritaria |
| Más de 60 días | Rojo | Recuperación urgente |

El indicador del encabezado calcula la **suma total de montos vencidos** del subconjunto filtrado (o de toda la cartera si no hay filtro activo).

---

## HU-31 · Registrar acción de cobranza en campo

**Historia:** Como asesor de negocios, quiero registrar el resultado de una gestión de cobranza con todos los detalles, para que el sistema actualice el estado del crédito y el supervisor vea mi gestión.

**Criterios de aceptación:**
- Formulario de acción: tipo de gestión (Visita / Llamada / Mensaje), resultado (Compromiso de pago / Pago parcial / Sin contacto / Se niega a pagar), fecha y monto del compromiso si aplica.
- Un compromiso de pago genera una **alerta automática** al asesor en la fecha acordada.
- La gestión queda registrada con coordenadas GPS y marca de tiempo.
- Si es pago parcial, el saldo vencido se actualiza en tiempo real.

**Story points:** 5

### RF-77 — Formulario de acción de cobranza

| Campo | Tipo | Descripción |
|---|---|---|
| tipo_gestion | Lista | visita / llamada / mensaje |
| resultado | Lista | compromiso_pago / pago_parcial / sin_contacto / se_niega |
| monto_pagado | Decimal | Monto pagado si aplica (resultado = pago_parcial) |
| fecha_compromiso | Selector de fecha | Fecha acordada para el pago |
| monto_comprometido | Decimal | Monto comprometido para el pago |
| observaciones | Texto libre | Notas adicionales |
| lat | DECIMAL(10,7) | Latitud capturada automáticamente |
| lng | DECIMAL(10,7) | Longitud capturada automáticamente |
| timestamp_gestion | TIMESTAMPTZ | Marca de tiempo automática |

### RF-78 — Alerta de seguimiento de compromiso
- Al registrar un compromiso de pago con fecha futura, programar una notificación local para ese día.
- Usar el paquete `flutter_local_notifications ^17.2.2` con `zonedSchedule`.
- El contenido de la notificación incluye: nombre del cliente y monto comprometido.
- Ejemplo: _"Seguimiento: Juan Pérez acordó pagar S/450 hoy."_

---

## Estructura de datos relevante

**Tabla: `acciones_cobranza`**

| Campo | Tipo | Descripción |
|---|---|---|
| id | UUID (PK) | Identificador único |
| asesor_id | UUID (FK → asesores_negocio) | Asesor que realizó la gestión |
| cliente_id | UUID (FK → clientes) | Cliente gestionado |
| credito_id | UUID (FK → creditos) | Crédito en mora |
| tipo_gestion | VARCHAR(20) | visita / llamada / mensaje |
| resultado | VARCHAR(30) | compromiso_pago / pago_parcial / sin_contacto / se_niega |
| monto_pagado | DECIMAL(12,2) | Monto pagado si aplica |
| fecha_compromiso | DATE | Fecha acordada para el pago |
| monto_compromiso | DECIMAL(12,2) | Monto comprometido |
| observaciones | TEXT | Notas adicionales |
| lat | DECIMAL(10,7) | Latitud de la gestión |
| lng | DECIMAL(10,7) | Longitud de la gestión |
| timestamp_gestion | TIMESTAMPTZ | Fecha y hora de la gestión |

**Tabla: `creditos`** _(campos relevantes para cobranza)_

| Campo | Tipo | Descripción |
|---|---|---|
| estado | VARCHAR(20) | vigente / pagado / vencido / castigado |
| saldo_actual | DECIMAL(12,2) | Saldo pendiente actual |
| cuotas_pagadas | INTEGER | Cuotas pagadas a la fecha |
| dias_mora | INTEGER | Días de mora actuales |

---

## Notas de implementación

- **Paquetes relevantes:** `supabase_flutter`, `geolocator ^12.0.0`, `flutter_local_notifications ^17.2.2`, `sqflite`
- **ViewModel:** `CobranzaViewModel` gestiona la lista de mora y el formulario de registro. Expone: `listaClientesMora`, `totalVencido`, `estadoFormulario`.
- **GPS automático:** capturar las coordenadas automáticamente al abrir el formulario de cobranza (no requiere acción explícita del asesor). Mostrar un indicador discreto mientras obtiene la señal.
- **Actualización del saldo:** al registrar un `pago_parcial`, invocar la Supabase Edge Function `registrar-pago` para actualizar `saldo_actual` y `cuotas_pagadas` en la tabla `creditos`. Actualizar también el caché local.
- **Notificación de compromiso:** al programar con `zonedSchedule`, usar la zona horaria de Perú (`America/Lima`). Cancelar la notificación si el cliente realiza el pago antes de la fecha acordada.
- **Offline:** el registro de acciones de cobranza sigue el patrón offline-first del Módulo 1. Si no hay red, guardar en cola local con `pendiente_sync = true` y sincronizar al reconectar.
