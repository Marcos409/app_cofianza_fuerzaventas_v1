# M2 — Planificación de Ruta

## Contexto
El asesor visualiza en un mapa todos sus clientes del día, optimiza el orden de visitas por distancia y puede lanzar la navegación en Waze o Google Maps. El módulo también gestiona geocercas por zona de trabajo y permite capturar o actualizar la ubicación GPS del negocio del cliente durante la visita.

---

## HU-08 · Ver mapa de visitas del día con ruta optimizada

**Historia:** Como asesor de negocios, quiero ver un mapa con todos mis clientes del día y una ruta sugerida, para reducir tiempo de desplazamiento y visitar más clientes.

**Criterios de aceptación:**
- El mapa muestra un marcador por cliente con color según prioridad: rojo (ALTA), amarillo (MEDIA), verde (NORMAL).
- Al tocar un marcador, aparece una ficha rápida con nombre, tipo de gestión y botón "Ver ficha completa".
- El botón "Optimizar ruta" reordena los marcadores por distancia y tiempo desde la posición actual.
- La ruta óptima se dibuja como línea conectando los puntos en orden.
- El botón "Navegar" lanza Waze o Google Maps con el primer destino.
- Los clientes ya visitados cambian su marcador a gris con marca de completado.

**Story points:** 8

### RF-19 — Integración de Google Maps en Flutter
- Usar el paquete `google_maps_flutter ^2.9.0`.
- Crear marcadores con color diferenciado por prioridad (rojo / amarillo / verde / gris).
- Dibujar la polilínea de ruta óptima sobre el mapa como capa adicional.

### RF-20 — Permisos de ubicación
- Solicitar permiso de ubicación precisa al abrir el módulo de ruta.
- Si el usuario deniega: mostrar explicación clara de por qué es necesario.
- Sin permiso: el mapa funciona, pero sin posición actual ni optimización de ruta.
- Usar `geolocator ^12.0.0` para la gestión de permisos y ubicación.

### RF-21 — Algoritmo de optimización de ruta
Implementar el algoritmo del **vecino más cercano**:
1. Partir desde la posición actual del asesor.
2. En cada paso, elegir el cliente no visitado más próximo por distancia euclidiana.
3. Repetir hasta cubrir toda la cartera.
4. Presentar el resultado como lista reordenada y polilínea en el mapa.

> El cálculo es síncrono en el ViewModel y no requiere conexión a red.

### RF-22 — Lanzar app de navegación externa
Al pulsar "Navegar":
1. Intentar abrir **Waze** con las coordenadas del destino.
2. Si Waze no está instalado, abrir **Google Maps** (app).
3. Si ninguna está disponible, abrir el navegador con Google Maps web.

---

## HU-09 · Gestionar geocercas por zona de trabajo

**Historia:** Como administrador de agencia, quiero definir zonas geográficas para cada asesor, para organizar la fuerza comercial por sectores y medir cobertura real.

**Criterios de aceptación:**
- El mapa permite definir polígonos que delimitan zonas de trabajo.
- Cada zona tiene nombre, color distintivo y lista de asesores asignados.
- El asesor ve el contorno de su zona como capa semitransparente en su mapa.
- Si el asesor registra una visita fuera de su zona, el sistema muestra un aviso (no bloquea).

**Story points:** 5

### RF-23 — Capa de geocerca en el mapa
- Renderizar el polígono de la zona como capa de relleno semitransparente sobre el mapa.
- Usar borde del color asignado a la zona.
- La capa se dibuja usando `Polygon` de `google_maps_flutter`.

### RF-24 — Detección de visita fuera de zona
- Antes de guardar el resultado de una visita, comparar la ubicación GPS actual con el polígono de zona.
- Algoritmo: **Ray Casting** (conteo de cruces de rayo horizontal con los lados del polígono).
- Si está fuera: mostrar aviso _"Esta visita está fuera de tu zona asignada. Se registrará igualmente."_
- El aviso es informativo; **no bloquea** el registro.

---

## HU-10 · Registrar coordenadas GPS del negocio del cliente

**Historia:** Como asesor de negocios, quiero capturar y actualizar la ubicación exacta del negocio del cliente durante la visita, para que futuras visitas y el mapa del equipo sean más precisos.

**Criterios de aceptación:**
- En la ficha del cliente, el botón "Actualizar ubicación del negocio" captura las coordenadas actuales.
- Se muestra la dirección aproximada obtenida por geocodificación inversa.
- El asesor puede confirmar o descartar la ubicación capturada.
- Al confirmar, se actualizan las coordenadas del cliente en Supabase.

**Story points:** 3

### RF-25 — Captura de coordenadas con GPS de alta precisión
- Usar `geolocator` con precisión alta (`LocationAccuracy.high`).
- Mostrar indicador de carga mientras obtiene la señal GPS.
- La captura se realiza al momento de pulsar el botón.

### RF-26 — Geocodificación inversa
- Usar el paquete `geocoding ^3.0.0` para convertir coordenadas en dirección legible.
- Mostrar: calle, distrito, ciudad.
- El campo de dirección resultante es **editable** para que el asesor pueda corregir si es necesario.
- Al confirmar, actualizar `lat` y `lng` del cliente en la tabla `clientes` de Supabase.

---

## Estructura de datos relevante

**Campos de ubicación en tabla `clientes`:**

| Campo | Tipo | Descripción |
|---|---|---|
| lat | DECIMAL(10,7) | Latitud del negocio |
| lng | DECIMAL(10,7) | Longitud del negocio |

**Campos de ubicación en tabla `cartera_diaria`:**

| Campo | Tipo | Descripción |
|---|---|---|
| lat_visita | DECIMAL(10,7) | Latitud donde se registró la visita |
| lng_visita | DECIMAL(10,7) | Longitud donde se registró la visita |

---

## Notas de implementación

- **Paquetes relevantes:** `google_maps_flutter ^2.9.0`, `geolocator ^12.0.0`, `geocoding ^3.0.0`
- **ViewModel:** `RutaViewModel` expone: lista ordenada de clientes, estado de carga del GPS y polilínea de ruta.
- **Algoritmo de vecino más cercano:** implementar en el ViewModel como función pura. Recibe lista de puntos (`lat`, `lng`) y posición actual; devuelve la lista reordenada.
- **Polígono de geocerca:** almacenar como lista de pares `(lat, lng)` en Supabase. Descargar durante la sincronización nocturna.
- **Fallback sin permisos GPS:** mostrar el mapa centrado en la agencia del asesor con todos los marcadores, pero sin polilínea ni botón de optimización activo.
- La apertura de apps externas (Waze / Google Maps) se hace con `url_launcher` construyendo deep links con las coordenadas del destino.
