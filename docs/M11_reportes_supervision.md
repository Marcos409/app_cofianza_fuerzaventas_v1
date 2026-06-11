# M11 — Reportes y Supervisión

## Contexto
Este módulo es exclusivo para perfiles **Supervisor** y **Administrador**. Permite monitorear en tiempo real el avance de todos los asesores en el mapa y consultar un reporte de productividad mensual por asesor, exportable como PDF. Los asesores con perfil Operador no ven este módulo en su menú.

---

## HU-32 · Ver reporte de cobertura de visitas del día

**Historia:** Como supervisor de agencia, quiero ver en tiempo real el avance de todos mis asesores en el mapa, para saber quiénes están trabajando, dónde se encuentran y cuántas gestiones han completado.

**Criterios de aceptación:**
- Mapa con marcadores de distintos colores por asesor mostrando su última ubicación.
- Panel lateral con tabla: asesor, visitados sobre total asignado, última sincronización.
- Filtro por agencia y por fecha.
- Solo visible para perfiles **Supervisor** y **Administrador**.

**Story points:** 5

### RF-79 — Monitor de supervisión en tiempo real
- Suscripción Realtime a la tabla `cartera_diaria` filtrando por:
  - `agencia_id` = agencia del supervisor autenticado
  - `fecha_asignacion` = fecha de hoy
- Al recibir actualizaciones, refrescar el mapa y la tabla de avance **sin recargar la pantalla**.
- Cada marcador en el mapa representa la **última ubicación registrada** (`lat_visita`, `lng_visita`) de la última visita del asesor.

**Datos mostrados por asesor en el panel:**

| Columna | Descripción |
|---|---|
| Nombre | Nombre completo del asesor |
| Avance | `X visitados / Y total asignados` |
| % completado | Barra de progreso |
| Última sincronización | Marca de tiempo de la última visita registrada |

---

## HU-33 · Ver reporte de productividad mensual

**Historia:** Como jefe regional, quiero ver un reporte de solicitudes gestionadas, aprobadas y desembolsadas por asesor en el mes, para tomar decisiones sobre metas y resultados del equipo.

**Criterios de aceptación:**
- Tabla con: asesor, solicitudes enviadas, aprobadas, desembolsadas, monto total y tasa de aprobación.
- Gráfico de barras comparativo entre asesores del período.
- Exportable como PDF.
- Solo accesible para Supervisor y Administrador.

**Story points:** 5

### RF-80 — Consulta de productividad agregada
- Consultar la tabla `solicitudes_credito` con los filtros:
  - `agencia_id` = agencia del supervisor
  - `created_at` dentro del rango del mes actual (o mes seleccionado)
- Agrupar por `asesor_id` y `estado`.
- Calcular para cada asesor:

| Métrica | Cálculo |
|---|---|
| Solicitudes enviadas | `COUNT(*)` |
| Aprobadas | `COUNT(*) WHERE estado = 'aprobado'` |
| Desembolsadas | `COUNT(*) WHERE estado = 'desembolsado'` |
| Monto total aprobado | `SUM(monto_aprobado) WHERE estado IN ('aprobado', 'desembolsado')` |
| Tasa de aprobación | `(aprobadas / enviadas) × 100` |

### RF-81 — Gráfico comparativo de productividad
- Usar el paquete `fl_chart ^0.68.0`.
- Tipo: gráfico de **barras agrupadas** (`BarChart` con grupos de barras).
- Una barra por estado (enviadas, aprobadas, desembolsadas) por asesor.
- Eje X: nombre del asesor (abreviado si es muy largo).
- Eje Y: número de solicitudes.
- Leyenda de colores debajo del gráfico.

**Exportación como PDF:**
- Generar con el paquete `pdf ^3.11.1`.
- El documento incluye: encabezado con logo de la institución, nombre de la agencia, período del reporte, tabla de datos y el gráfico renderizado como imagen.
- Compartir con `printing ^5.13.2`.

---

## Notas de implementación

- **Acceso restringido:** verificar el perfil del asesor autenticado antes de mostrar el módulo en el menú lateral (ver M0 RF-05). Si el perfil es `operador` o `super_operador`, este módulo no aparece.
- **Paquetes relevantes:** `supabase_flutter`, `google_maps_flutter ^2.9.0`, `fl_chart ^0.68.0`, `pdf ^3.11.1`, `printing ^5.13.2`
- **ViewModel:** `ReportesViewModel` gestiona dos fuentes de datos separadas: el canal Realtime para el mapa de cobertura y la consulta agregada para el reporte de productividad.
- **Mapa de supervisión:** usar `google_maps_flutter` con marcadores personalizados por asesor (iniciales del asesor o un pin con su foto). Actualizar la posición del marcador con animación al recibir una actualización Realtime.
- **Filtro de período:** selector de mes con flechas de navegación (← mes anterior / mes siguiente →). Al cambiar el mes, relanzar la consulta de productividad con el nuevo rango de fechas.
- **Renderizado del gráfico para PDF:** `fl_chart` no exporta directamente a PDF. Capturar el widget como imagen usando `RepaintBoundary` y `toImage()`, luego incluir esa imagen en el PDF con el paquete `pdf`.
- **RLS de Supabase:** los supervisores solo pueden leer filas de su `agencia_id`. Los administradores tienen acceso a todas las agencias de su institución.
