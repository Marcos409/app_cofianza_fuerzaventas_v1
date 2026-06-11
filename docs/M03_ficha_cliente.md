# M3 — Ficha del Cliente

## Contexto
Antes de visitar al cliente, el asesor consulta toda su información: datos personales, posición crediticia en el sistema, historial de pagos, oferta preaprobada y alertas de mora. Los datos se muestran desde caché si no hay conexión.

---

## HU-11 · Ver ficha completa del cliente antes de la visita

**Historia:** Como asesor de negocios, quiero consultar toda la información del cliente antes de visitarlo, para llegar preparado con datos actualizados sin depender de papeles.

**Criterios de aceptación:**
- La ficha muestra: foto o iniciales, nombre completo, documento, dirección, teléfono, tipo y antigüedad del negocio.
- Sección "Posición del cliente": deuda total en el sistema, cuotas al día, cuotas en mora, fecha del último pago.
- Sección "Historial crediticio": últimos cinco créditos con monto, plazo, tasa, estado y porcentaje de pagos puntuales.
- Sección "Oferta vigente": monto preaprobado por el sistema de scoring (si existe).
- Botón "Llamar" abre el marcador telefónico con el número del cliente prellenado.
- Los datos se cargan desde caché si no hay conexión.

**Story points:** 8

### RF-27 — Estructura de la pantalla de ficha
La pantalla usa desplazamiento vertical con secciones apiladas:
1. Encabezado del cliente (foto/iniciales, nombre, semáforo SBS)
2. Datos de contacto y negocio
3. Posición en el sistema
4. Historial de créditos (últimos 5)
5. Oferta preaprobada
6. Botonera de acciones (Llamar, Registrar visita, Iniciar solicitud)

### RF-28 — Semáforo de riesgo crediticio

| Calificación SBS | Color | Descripción |
|---|---|---|
| Normal | Verde | Sin observaciones |
| CPP (Con Problemas Potenciales) | Amarillo | Requiere atención |
| Deficiente | Naranja | Requiere comité especial |
| Dudoso | Rojo | Alto riesgo |
| Pérdida | Gris oscuro | No procede evaluación |

Implementar como widget `SemaforoRiesgo` en `shared/widgets/semaforo_riesgo.dart`.

### RF-29 — Llamada directa desde la ficha
- El botón "Llamar" lanza la app telefónica del dispositivo con el número del cliente.
- **No realiza la llamada automáticamente**; el asesor confirma desde el marcador.
- Usar `url_launcher` con el esquema `tel:`.

### RF-30 — Consulta de posición del cliente
- Invocar la Supabase Edge Function `consulta-posicion` con el `cliente_id`.
- La función devuelve:
  - Deuda total consolidada
  - Número de cuentas vigentes
  - Número de cuentas en mora
  - Días de mayor mora histórica
  - Fecha del último pago registrado

---

## HU-12 · Ver gráfico de comportamiento de pagos

**Historia:** Como asesor de negocios, quiero ver un gráfico mensual del comportamiento de pagos del cliente en los últimos 12 meses, para evaluar visualmente si es candidato a una nueva operación antes de proponer algo.

**Criterios de aceptación:**
- Gráfico de barras con 12 columnas: verde = pago puntual, rojo = pago con mora, gris = sin cuota ese mes.
- Indicadores debajo del gráfico: porcentaje de pagos puntuales, días promedio de mora, monto total pagado.
- El gráfico funciona offline con datos descargados en la sincronización nocturna.

**Story points:** 5

### RF-31 — Gráfico de comportamiento con fl_chart
- Usar el paquete `fl_chart ^0.68.0`.
- Tipo: gráfico de barras (`BarChart`).
- Color de cada barra según estado de pago: verde (puntual), rojo (mora), gris (sin cuota).
- Eje X: meses abreviados (Ene, Feb, Mar…).
- El gráfico se alimenta de datos locales en SQLite.

### RF-32 — Cálculo de indicadores de comportamiento
Los indicadores se calculan en el ViewModel a partir de los datos locales:

| Indicador | Fórmula |
|---|---|
| Porcentaje puntual | `(cuotas al día / total cuotas) × 100` |
| Días promedio de mora | `suma días mora en cuotas morosas / número cuotas morosas` |
| Monto total pagado | `suma de todos los montos pagados registrados` |

---

## HU-13 · Ver oferta preaprobada del scoring

**Historia:** Como asesor de negocios, quiero ver el monto máximo preaprobado calculado por el sistema antes de la visita, para llegar con una propuesta concreta en lugar de generar expectativas sin respaldo.

**Criterios de aceptación:**
- La sección "Oferta vigente" muestra: monto máximo, plazo sugerido, tasa TEA referencial, nivel de confianza del puntaje y fecha de vencimiento de la oferta.
- Si no existe preaprobado, muestra: _"Sin oferta vigente. Puede iniciar solicitud nueva."_
- El botón "Usar esta oferta" prellena el formulario de solicitud con esos datos.

**Story points:** 5

### RF-33 — Consulta de preaprobados vigentes
Consultar la tabla `creditos_preaprobados` con los filtros:
- `cliente_id` = cliente actual
- `vigente = true`
- `fecha_vencimiento >= fecha actual`

Tomar el registro con mayor `score_confianza`.

### RF-34 — Tarjeta visual de oferta preaprobada
- Fondo verde claro con borde verde.
- Muestra: monto formateado, plazo en meses, tasa TEA en porcentaje.
- Barra horizontal de confianza del puntaje (0-100).
- Fecha de vigencia.
- Botón de acción que navega al formulario de solicitud con los campos prellenados.

---

## HU-14 · Recibir alertas de caída de cartera

**Historia:** Como asesor de negocios, quiero recibir alertas cuando un cliente entra en mora o tiene variaciones importantes, para actuar de forma preventiva antes de que el crédito se deteriore.

**Criterios de aceptación:**
- Las alertas muestran una insignia numérica sobre el ícono de cartera en el menú.
- Tipos de alerta: primer día de mora, mora mayor a 30 días, mora mayor a 60 días, pago parcial, pago total.
- Al tocar una alerta, navega directamente a la ficha del cliente correspondiente.
- Las alertas leídas se marcan y desaparecen de la insignia al día siguiente.

**Story points:** 5

### RF-35 — Suscripción Realtime para alertas
- Suscribirse al canal Realtime de Supabase para inserciones en la tabla `alertas_cartera` donde `asesor_id` coincide con el usuario autenticado.
- Al recibir un evento: actualizar el estado del ViewModel y refrescar la insignia.

### RF-36 — Insignia numérica en menú
- Mostrar el número de alertas no leídas como insignia roja sobre el ícono de campana en el menú lateral.
- Actualizar en tiempo real al recibir nuevas alertas o al marcar las existentes como leídas.

---

## Estructura de datos relevante

**Tabla: `creditos_preaprobados`**

| Campo | Tipo | Descripción |
|---|---|---|
| id | UUID (PK) | Identificador único |
| cliente_id | UUID (FK → clientes) | Cliente al que aplica la oferta |
| asesor_id | UUID (FK → asesores_negocio) | Asesor asignado |
| monto_maximo | DECIMAL(12,2) | Monto máximo preaprobado |
| plazo_sugerido_meses | INTEGER | Plazo recomendado |
| tea_referencial | DECIMAL(5,2) | Tasa efectiva referencial |
| score_confianza | INTEGER | Puntaje de confianza (0-100) |
| vigente | BOOLEAN | Si la oferta está activa |
| fecha_vencimiento | DATE | Fecha hasta la que es válida |

**Tabla: `alertas_cartera`**

| Campo | Tipo | Descripción |
|---|---|---|
| id | UUID (PK) | Identificador único |
| asesor_id | UUID (FK → asesores_negocio) | Asesor destinatario |
| cliente_id | UUID (FK → clientes) | Cliente que generó la alerta |
| tipo_alerta | VARCHAR(30) | primer_dia_mora / mora_30d / mora_60d / pago_parcial / pago_total |
| mensaje | TEXT | Texto descriptivo |
| leida | BOOLEAN | Si el asesor ya la leyó |
| created_at | TIMESTAMPTZ | Fecha de generación |

---

## Notas de implementación

- **Paquetes relevantes:** `supabase_flutter`, `fl_chart ^0.68.0`, `sqflite`
- **ViewModel:** `FichaViewModel` extiende `StateNotifier`. Gestiona la carga en paralelo de: datos del cliente, posición crediticia (Edge Function) y oferta preaprobada (tabla local).
- **Widgets compartidos:** `SemaforoRiesgo`, `ClienteCard` en `shared/widgets/`.
- **Realtime:** La suscripción a `alertas_cartera` se inicializa en el `AppViewModel` global al autenticarse, no en la pantalla de ficha, para que la insignia funcione desde cualquier módulo.
- Los datos descargados en la sincronización nocturna deben incluir los últimos 12 meses de movimientos de pago para que el gráfico funcione offline.
