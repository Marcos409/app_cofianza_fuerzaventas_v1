# M5 — Captura de Solicitud de Crédito en Campo

## Contexto
El asesor registra la solicitud completa directamente en el negocio del cliente, en cuatro pasos secuenciales. El formulario funciona offline-first: si no hay conexión al enviar, la solicitud queda en cola local. También incluye un simulador de crédito rápido y el historial de solicitudes del mes.

---

## HU-17 · Registrar solicitud de crédito en cuatro pasos (offline-first)

**Historia:** Como asesor de negocios, quiero capturar la solicitud de crédito completa del cliente directamente en su negocio, para iniciar el proceso de evaluación sin regresar a la agencia.

**Criterios de aceptación:**
- El formulario tiene cuatro pasos secuenciales: Datos del solicitante, Datos del negocio, Condiciones del crédito, Confirmación y firma.
- Cada paso valida sus campos antes de permitir avanzar. Los campos obligatorios no completados se resaltan en rojo.
- El asesor puede guardar borrador en cualquier paso y retomarlo después.
- Con conexión, la solicitud se envía al instante. Sin conexión, queda en cola con indicador "Pendiente de envío".
- Al enviar, se genera un número de expediente local visible al asesor.
- El formulario se adapta según el tipo de producto: microcredito o consumo.

**Story points:** 13

### RF-43 — Indicador de progreso de cuatro pasos
- El encabezado muestra los cuatro pasos con estado visual: completado (relleno) / activo (borde destacado) / pendiente (vacío).
- Navegación entre pasos con botones "Anterior" y "Siguiente".
- El deslizamiento lateral está **deshabilitado** para evitar saltar validaciones.
- Implementar como widget `StepperSolicitud` en `shared/widgets/stepper_solicitud.dart`.

### RF-44 — Paso 1: Datos del solicitante

| Campo | Tipo | Validación |
|---|---|---|
| Nombres | Texto | Obligatorio, solo letras |
| Apellidos | Texto | Obligatorio |
| Documento | Numérico | 8 dígitos exactos |
| Fecha de nacimiento | Selector de fecha | Edad entre 18 y 75 años |
| Estado civil | Lista | Soltero / Casado / Conviviente / Divorciado / Viudo |
| Grado de instrucción | Lista | Primaria / Secundaria / Técnico / Universitario |
| Teléfono | Numérico | 9 dígitos |
| Correo electrónico | Texto | Formato válido (opcional) |

Activar campos adicionales para cónyuge o garante según el estado civil y las reglas del producto seleccionado.

### RF-45 — Paso 2: Datos del negocio y destino del crédito

| Campo | Tipo | Validación |
|---|---|---|
| Tipo de negocio | Lista | Comercio / Servicios / Producción / Agropecuario |
| Nombre del negocio | Texto | Obligatorio |
| Dirección del negocio | Texto | Obligatorio |
| Antigüedad del negocio | Numérico (años + meses) | Mínimo 6 meses |
| Ingresos estimados mensuales | Decimal | Mayor que cero |
| Gastos mensuales | Decimal | Mayor o igual a cero |
| Patrimonio estimado | Decimal | Opcional |
| Destino del crédito | Texto libre | Máximo 500 caracteres |
| Actividad económica | Lista | Según catálogo CIIU |

### RF-46 — Paso 3: Condiciones del crédito
- Control deslizante para el monto solicitado: entre S/500 y S/150,000.
- Lista desplegable para plazo en meses: 3, 6, 12, 18, 24, 36, 48 o 60.
- Selector de moneda: PEN o USD.
- Selector de tipo de cuota: mensual, quincenal o semanal.
- Lista de garantía: sin garantía, aval, hipotecaria o prendaria.
- Tarjeta de simulación que se actualiza en tiempo real al modificar monto o plazo (ver RF-47).

### RF-47 — Fórmula de simulación de cuota en tiempo real
Usar la fórmula de **amortización francesa**:

```
Tasa mensual equivalente = (1 + TEA)^(1/12) - 1
Cuota mensual = Monto × Tasa_mensual / (1 - (1 + Tasa_mensual)^(-Plazo_meses))
```

La tarjeta de simulación muestra:
- Cuota estimada
- Total a pagar
- Costo financiero total
- TEA referencial

> El cálculo es síncrono en el ViewModel y **no requiere conexión a red**.

### RF-48 — Paso 4: Confirmación y firma digital
- Vista de resumen en modo solo lectura con todos los datos ingresados.
- Lienzo táctil para que el cliente firme con el dedo (widget `SignaturePad`).
- La firma se convierte a imagen en base64 y se adjunta a la solicitud.
- Casilla obligatoria: _"El cliente declara que los datos son veraces"_.

---

## HU-18 · Guardar y retomar borradores de solicitud

**Historia:** Como asesor de negocios, quiero guardar una solicitud incompleta como borrador y retomarla después, para completarla en una segunda visita sin perder los datos ya ingresados.

**Criterios de aceptación:**
- Al intentar salir del formulario, aparece diálogo: _"Guardar borrador / Descartar / Cancelar"_.
- La pantalla "Borradores" lista las solicitudes incompletas con: nombre del cliente, paso alcanzado, fecha y monto.
- Al seleccionar un borrador, navega al paso donde se quedó con todos los campos prellenados.
- Deslizar un borrador hacia un lado y confirmar lo elimina permanentemente.

**Story points:** 3

### RF-49 — Persistencia de borradores en SQLite local

**Tabla local SQLite: `solicitudes_borrador`**

| Campo | Tipo | Descripción |
|---|---|---|
| id | TEXT (PK) | UUID generado localmente |
| cliente_id | TEXT | ID del cliente (si fue seleccionado) |
| cliente_nombre | TEXT | Nombre del cliente para mostrar en lista |
| paso_actual | INTEGER | Número del último paso completado (1-4) |
| datos_json | TEXT | Todos los campos del formulario serializados en JSON |
| monto_solicitado | REAL | Monto para mostrar en la lista de borradores |
| asesor_id | TEXT | ID del asesor propietario del borrador |
| updated_at | INTEGER | Marca de tiempo de la última edición |

---

## HU-19 · Simulador de crédito rápido independiente

**Historia:** Como asesor de negocios, quiero calcular rápidamente la cuota de cualquier monto y plazo sin abrir una solicitud formal, para responder al instante las preguntas del cliente durante la visita.

**Criterios de aceptación:**
- Pantalla accesible desde el menú lateral y desde la ficha del cliente.
- Control deslizante de monto (S/500 a S/150,000) y selector de plazo.
- Cuota mensual, total a pagar y costo financiero se actualizan en tiempo real.
- Funciona completamente sin conexión.
- El botón "Crear solicitud con estos datos" navega al formulario con monto y plazo prellenados.

**Story points:** 5

### RF-50 — Pantalla del simulador
- Tres tarjetas de indicador: cuota mensual, total a pagar y costo financiero.
- Cálculo con la misma fórmula del RF-47.
- El botón de acción pasa `monto` y `plazo` como argumentos de ruta hacia M5.

---

## HU-20 · Ver historial de mis solicitudes del mes

**Historia:** Como asesor de negocios, quiero ver todas las solicitudes que he registrado en el período, para hacer seguimiento y reportar mi productividad.

**Criterios de aceptación:**
- Lista agrupada por semana con contador de cada estado.
- Encabezado con indicadores: total enviadas, aprobadas, desembolsadas y monto total del mes.
- Al tocar una solicitud, navega al detalle de su estado actual.

**Story points:** 3

### RF-51 — Consulta de solicitudes del período
- Consultar la tabla `solicitudes_credito` con los filtros:
  - `asesor_id` = asesor autenticado
  - `created_at` dentro del mes actual
- Ordenar por fecha descendente.

### RF-52 — Indicadores mensuales del asesor

| Indicador | Cálculo |
|---|---|
| Total enviadas | Total de filas |
| Aprobadas | Subconjunto con `estado = aprobado` |
| Desembolsadas | Subconjunto con `estado = desembolsado` |
| Monto total | Suma de `monto_aprobado` |
| Tasa de aprobación | `(aprobadas / enviadas) × 100` |

---

## Estructura de datos relevante

**Tabla: `solicitudes_credito`** _(campos principales)_

| Campo | Tipo | Descripción |
|---|---|---|
| id | UUID (PK) | Identificador único |
| numero_expediente | VARCHAR(20) UNIQUE | Número de expediente oficial |
| asesor_id | UUID (FK) | Asesor que capturó la solicitud |
| cliente_id | UUID (FK) | Cliente solicitante |
| monto_solicitado | DECIMAL(12,2) | Monto solicitado |
| plazo_meses | INTEGER | Plazo solicitado |
| moneda | VARCHAR(3) | PEN o USD |
| tipo_cuota | VARCHAR(10) | mensual / quincenal / semanal |
| garantia | VARCHAR(20) | sin_garantia / aval / hipotecaria / prendaria |
| cuota_estimada | DECIMAL(10,2) | Cuota mensual simulada |
| tea_referencial | DECIMAL(5,2) | TEA al momento de la solicitud |
| estado | VARCHAR(30) | borrador / enviado / recibido_comite / en_evaluacion / aprobado / condicionado / rechazado / desembolsado |
| firma_cliente_base64 | TEXT | Firma digital del cliente |
| pendiente_sync | BOOLEAN | Si está pendiente de sincronización offline |

---

## Notas de implementación

- **Paquetes relevantes:** `sqflite`, `supabase_flutter`, `signature ^5.4.1`, `connectivity_plus`
- **ViewModel:** `SolicitudViewModel` gestiona el estado de los cuatro pasos. El estado incluye: `pasoActual`, `datosFormulario`, `cuotaSimulada`, `estadoEnvio`.
- **Validación por paso:** cada paso tiene su propia función de validación en `validators.dart`. Al pulsar "Siguiente", se ejecuta antes de avanzar.
- **Firma digital:** widget `SignaturePad` en `shared/widgets/signature_pad.dart`. Exportar como PNG en base64 antes de adjuntar a la solicitud.
- **Navegación entre módulos:** Al terminar de capturar datos, el flujo continúa hacia M6 (documentos) antes de la transmisión (M8).
- La fórmula de amortización francesa se implementa como función pura en `utils/calculadora_credito.dart`, reutilizable desde el simulador y el formulario.
