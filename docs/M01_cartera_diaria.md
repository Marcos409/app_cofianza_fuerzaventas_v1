# M1 — Cartera Diaria

## Contexto
El asesor descarga su lista de clientes asignados para el día y la gestiona durante la jornada, incluso sin conexión a internet. El sistema prioriza automáticamente las visitas y permite marcar cada una como completada.

---

## HU-04 · Ver la lista de cartera asignada del día

**Historia:** Como asesor de negocios, quiero ver al iniciar el día la lista completa de clientes asignados a mí, para planificar visitas sin depender de conexión a internet durante el día.

**Criterios de aceptación:**
- La lista muestra por cada cliente: nombre, documento censurado (`***456`), tipo de gestión con etiqueta de color, monto del crédito y nivel de prioridad (ALTA / MEDIA / NORMAL).
- Un indicador en el encabezado muestra: _"15 clientes · 4 visitados · 11 pendientes"_.
- Los clientes visitados se desplazan al fondo con fondo gris y marca de completado.
- Una barra de progreso muestra el avance del día (visitados sobre total).
- Los datos están disponibles sin conexión desde la última sincronización.

**Story points:** 8

### RF-09 — Consulta de cartera desde Supabase
- Consultar la tabla `cartera_diaria` filtrando por `asesor_id` y `fecha_asignacion` igual a la fecha actual.
- Ordenar por `score_prioridad` descendente.
- Guardar el resultado localmente en SQLite para uso offline.
- Disparar esta consulta al iniciar sesión o al pulsar "Actualizar".

### RF-10 — Tipos de gestión y colores de etiqueta

| Tipo | Color | Descripción |
|---|---|---|
| RENOVACION | Azul | Crédito vigente próximo a vencer |
| AMPLIACION | Verde | Cliente solicita incremento de monto |
| NUEVA SOLICITUD | Naranja | Prospecto o cliente nuevo |
| SEGUIMIENTO | Gris | Visita de control post-desembolso |
| RECUPERACION MORA | Rojo | Cliente con cuotas vencidas |
| DESERTOR | Morado | Cliente que dejó de operar con la institución |

### RF-11 — Filtros de cartera
- Fila de filtros: **Todos / Renovaciones / Nuevas / En mora / Visitados**.
- El filtrado opera sobre los datos locales, sin nueva consulta a red.
- El contador del encabezado se actualiza con el subconjunto filtrado.

### RF-12 — Búsqueda rápida
- Campo de búsqueda con retraso de 300ms (debounce).
- Busca por nombre completo o últimos cuatro dígitos del documento.
- Búsqueda contra datos en caché local.

---

## HU-05 · Descarga automática nocturna de cartera

**Historia:** Como asesor de negocios, quiero que la app descargue mi cartera del día siguiente cada noche automáticamente, para llegar al campo con todos los datos disponibles sin esperar sincronización.

**Criterios de aceptación:**
- Una tarea programada ejecuta la sincronización a las 22:00 horas todos los días.
- La sincronización descarga: cartera asignada, fichas de clientes, últimos tres meses de movimientos y preaprobados vigentes.
- Al completar, envía notificación: _"Tu cartera de mañana está lista: X clientes."_
- Si falla, reintenta a las 22:30 y 23:00 con incremento progresivo de espera.
- El encabezado de Cartera muestra _"Última actualización: hoy 22:03"_.

**Story points:** 5

### RF-13 — Tarea programada de sincronización nocturna
- Usar el paquete `workmanager ^0.5.2` (WorkManager en Flutter).
- Tarea periódica diaria programada para las 22:00 horas con restricción de red activa.
- En caso de fallo: política de reintento exponencial con máximo tres intentos (22:00, 22:30, 23:00).

### RF-14 — Notificación push local al completar
- Al terminar la sincronización, emitir una notificación local con el número de clientes cargados.
- La notificación incluye enlace directo a la pantalla de Cartera.
- Usar `flutter_local_notifications ^17.2.2`.

---

## HU-06 · Segmentación y priorización automática de visitas

**Historia:** Como asesor de negocios, quiero que el sistema indique qué clientes son más urgentes cada día, para maximizar el impacto de mis visitas según los objetivos de la agencia.

**Criterios de aceptación:**
- La cartera se ordena automáticamente por: mora vencida primero, luego renovaciones de alto monto, ampliaciones, seguimiento y nuevas solicitudes.
- Un puntaje de prioridad (0 a 100) determina el orden de cada cliente.
- El asesor puede reordenar manualmente su lista arrastrando elementos.
- El reordenamiento manual persiste localmente y no afecta la asignación del sistema central.

**Story points:** 5

### RF-15 — Lógica de puntaje de prioridad
Cálculo local con los siguientes pesos:

| Condición | Puntos |
|---|---|
| Mora activa | 40 base + días de mora (hasta 30 adicionales) |
| Renovación con monto > S/5,000 | 35 |
| Ampliación | 25 |
| Seguimiento | 10 |
| Nueva solicitud | 5 |

> Máximo 100 puntos.

### RF-16 — Reordenamiento manual con arrastrar y soltar
- La pantalla de cartera permite reorganizar la lista arrastrando cada elemento.
- El nuevo orden se guarda localmente en la tabla `cartera_orden_local`.
- El orden manual no se sincroniza con el sistema central.

---

## HU-07 · Marcar visita como completada

**Historia:** Como asesor de negocios, quiero registrar el resultado de cada visita al salir de la ficha del cliente, para llevar control del avance del día y que mi supervisor lo vea en tiempo real.

**Criterios de aceptación:**
- Al salir de la ficha del cliente, un panel inferior ofrece: **Visitado / No encontrado / Reagendar / Negocio cerrado**.
- Cada resultado incluye campo de observación libre (máximo 200 caracteres).
- Al confirmar, el elemento cambia visualmente y se actualiza en Supabase con marca de tiempo y coordenadas GPS del momento.
- Sin conexión, el cambio queda en cola local y se sincroniza al reconectar.
- El supervisor ve el cambio en tiempo real en el portal web.

**Story points:** 5

### RF-17 — Registro de resultado de visita
Campos enviados a Supabase al confirmar el resultado:

| Campo | Descripción |
|---|---|
| estado_visita | Estado resultante de la visita |
| resultado_visita | Resultado registrado |
| observacion_visita | Observación libre |
| timestamp_visita | Fecha y hora |
| lat_visita | Latitud GPS |
| lng_visita | Longitud GPS |

Sin conexión: guardar en tabla local `visitas_pendientes` con `pendiente_sync = true`.

### RF-18 — Sincronización de visitas pendientes al reconectar
- El monitor de red detecta la reconexión.
- Disparar sincronización de todas las filas con `pendiente_sync = true`.
- Enviarlas en lote a Supabase.
- Marcar cada una como sincronizada al completar.

---

## Estructura de datos relevante

**Tabla: `cartera_diaria`**

| Campo | Tipo | Descripción |
|---|---|---|
| id | UUID (PK) | Identificador único |
| asesor_id | UUID (FK → asesores_negocio) | Asesor asignado |
| cliente_id | UUID (FK → clientes) | Cliente en la cartera |
| agencia_id | UUID (FK → agencias) | Agencia de la asignación |
| fecha_asignacion | DATE | Fecha para la que fue asignada |
| tipo_gestion | VARCHAR(30) | RENOVACION / AMPLIACION / NUEVA_SOLICITUD / SEGUIMIENTO / RECUPERACION_MORA / DESERTOR |
| prioridad | VARCHAR(10) | alta / media / normal |
| score_prioridad | INTEGER | Puntaje calculado (0-100) |
| estado_visita | VARCHAR(20) | pendiente / visitado / no_encontrado / reagendado / negocio_cerrado |
| resultado_visita | VARCHAR(30) | Resultado registrado por el asesor |
| observacion_visita | TEXT | Observaciones libres |
| timestamp_visita | TIMESTAMPTZ | Fecha y hora del registro |
| lat_visita | DECIMAL(10,7) | Latitud |
| lng_visita | DECIMAL(10,7) | Longitud |
| orden_manual | INTEGER | Orden definido por el asesor |

> **Restricción:** `UNIQUE(asesor_id, cliente_id, fecha_asignacion)` — un cliente no puede aparecer dos veces en la cartera del mismo asesor el mismo día.

**Tabla local SQLite: `visitas_pendientes`**

| Campo | Tipo | Descripción |
|---|---|---|
| id | TEXT (PK) | UUID generado localmente |
| cartero_id | TEXT | ID del registro en cartera_diaria |
| resultado | TEXT | Resultado de la visita |
| observacion | TEXT | Observación del asesor |
| timestamp_visita | TEXT | Marca de tiempo ISO 8601 |
| lat | REAL | Latitud |
| lng | REAL | Longitud |
| pendiente_sync | INTEGER | 1 = pendiente, 0 = sincronizado |

---

## Notas de implementación

- **Paquetes relevantes:** `supabase_flutter`, `sqflite`, `connectivity_plus`, `workmanager`, `flutter_local_notifications`
- **ViewModel:** `CarteraViewModel` extiende `StateNotifier` con Riverpod. Expone: lista filtrada, contadores (total, visitados, pendientes) y estado de carga.
- **Repository:** `CarteraRepository` decide entre `CarteraRemoteDatasource` (Supabase) y `CarteraLocalDatasource` (SQLite) según disponibilidad de red.
- **Caché:** Siempre guardar en SQLite después de cada descarga exitosa de Supabase. Leer de SQLite cuando no hay red.
- **Monitor de red:** `network_monitor.dart` expone un `Stream<bool>` de conectividad. El repositorio se suscribe para disparar la sincronización de pendientes al reconectar.
- El formato de documento censurado (`***456`) se implementa en `formatters.dart`.
