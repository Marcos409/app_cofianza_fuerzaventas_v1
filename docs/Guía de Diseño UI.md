# 🎨 Guía de Diseño UI – App Fuerza de Ventas (Financiera Confianza)

## 1. Inspiración visual (basada en imágenes proporcionadas)

La interfaz debe reflejar la identidad de **Financiera Confianza** y su vínculo con **Fundación BBVA Microfinanzas**, con un estilo:

- Limpio, corporativo pero accesible.
- Fondo predominantemente blanco.
- Tarjetas elevadas con sombras suaves.
- Íconos lineales delgados.
- Énfasis en legibilidad y jerarquía clara.
- Toques de color en elementos interactivos y etiquetas de estado.

## 2. Paleta de colores

| Uso | Color (HEX) | Nombre / Referencia |
|-----|-------------|----------------------|
| Primario institucional | `#003366` | Azul profundo (logo Financiera Confianza) |
| Secundario / Acentos | `#00A3B2` | Turquesa / Cyan (usado en botones y detalles) |
| Fondo principal | `#FFFFFF` | Blanco |
| Fondo secundario | `#F5F7FA` | Gris muy claro para secciones alternas |
| Texto principal | `#1A1A1A` | Casi negro |
| Texto secundario | `#6B7280` | Gris medio |
| Borde / División | `#E5E7EB` | Gris claro |
| Éxito / OK | `#10B981` | Verde |
| Advertencia | `#F59E0B` | Ámbar |
| Error / Urgente | `#EF4444` | Rojo |
| Info / Neutral | `#3B82F6` | Azul claro |

### Colores de etiquetas de gestión (HU-04)

| Tipo de gestión | Color de fondo | Color de texto |
|----------------|----------------|----------------|
| Renovación | `#DBEAFE` | `#1E40AF` |
| Ampliación | `#D1FAE5` | `#065F46` |
| Nueva solicitud | `#FFEDD5` | `#9A3412` |
| Seguimiento | `#F3F4F6` | `#374151` |
| Recuperación mora | `#FEE2E2` | `#991B1B` |
| Desertor | `#F3E8FF` | `#5B21B6` |

### Prioridades

| Prioridad | Color |
|-----------|-------|
| ALTA | `#EF4444` (rojo) |
| MEDIA | `#F59E0B` (ámbar) |
| NORMAL | `#10B981` (verde) |

### Semaforo SBS (riesgo crediticio)

| Calificación | Color |
|--------------|-------|
| Normal | `#10B981` |
| CPP (Problemas potenciales) | `#F59E0B` |
| Deficiente | `#F97316` |
| Dudoso | `#EF4444` |
| Pérdida | `#6B7280` |

## 3. Tipografía

| Elemento | Fuente | Tamaño | Peso |
|----------|--------|--------|------|
| Títulos de pantalla | Inter / Montserrat | 22px | Bold |
| Nombre de cliente | Inter / Montserrat | 18px | SemiBold |
| Subtítulos / secciones | Inter | 16px | Medium |
| Cuerpo de texto | Inter / Roboto | 14px | Regular |
| Texto auxiliar / etiquetas | Inter | 12px | Regular |
| Montos / números destacados | Inter | 20px | Bold |

> *Nota: Usar Inter como primera opción (descarga gratuita desde Google Fonts).*

## 4. Componentes de interfaz

### Botones

| Tipo | Estilo | Ejemplo |
|------|--------|---------|
| Primario | Fondo `#003366`, texto blanco, esquinas 8px, padding vertical 12px | `Ingresar` |
| Secundario | Borde `#003366`, texto `#003366`, fondo transparente | `Guardar borrador` |
| Terciario | Solo texto `#00A3B2`, sin borde ni fondo | `¿Problemas para ingresar?` |
| Peligro | Fondo `#EF4444`, texto blanco | `Eliminar` |

### Tarjetas (Cards)

- Fondo blanco (`#FFFFFF`).
- Borde redondeado: `12px`.
- Sombra: `0px 2px 8px rgba(0,0,0,0.05)`.
- Padding interno: `16px`.
- Separación entre tarjetas: `12px`.

### Barras de navegación

- **Barra inferior (bottom navigation)**:
  - Fondo blanco.
  - Ícono + etiqueta.
  - Color inactivo: `#9CA3AF`.
  - Color activo: `#003366`.
  - Altura: `64px`.

- **Barra superior (app bar)**:
  - Fondo blanco.
  - Sombra inferior suave.
  - Título centrado o alineado a la izquierda.
  - Ícono de usuario / notificaciones a la derecha.

### Campos de formulario

- Borde: `1px solid #E5E7EB`.
- Radio: `8px`.
- Padding interno: `12px 16px`.
- Label: `14px`, color `#374151`, peso Medium.
- Placeholder: `#9CA3AF`.
- Estado error: borde `#EF4444` + mensaje abajo.

### Modo offline (banner superior)

- Fondo: `#FEF3C7` (ámbar claro).
- Texto: `#92400E`.
- Ícono: 📡 o ⚠️.
- Mensaje: *"Trabajando sin conexión – Los datos se guardarán localmente"*.

## 5. Espaciado y layout

- Grid base: `8px`.
- Márgenes laterales: `16px`.
- Separación entre elementos verticales:
  - Entre campos: `16px`.
  - Entre secciones: `24px`.
  - Entre tarjetas: `12px`.

## 6. Íconos

- Estilo: **lineal**, trazo fino (2px).
- Tamaño estándar: `24x24px`.
- Color por defecto: `#6B7280`.
- Color activo: `#003366`.
- Proveedor sugerido: Feather Icons o Material Symbols (outlined).

## 7. Estados visuales

| Estado | Indicación visual |
|--------|--------------------|
| Cargando | Skeleton loader gris + spinner azul (`#003366`) |
| Vacío | Ilustración simple + texto "No hay datos" |
| Error | Tarjeta roja clara `#FEF2F2` con borde `#EF4444` |
| Éxito | Modal verde `#10B981` con check blanco |
| Offline | Banner amarillo fijo en la parte superior |
| Pendiente de sincronización | Ícono de nube + reloj junto al elemento |

## 8. Ejemplos visuales desde las imágenes

- Pantalla de login debe respetar el formato de la imagen 5 (logo, campos centrados, versión abajo).
- Pantalla de inicio debe integrar el estilo de la imagen 1 (tarjeta blanca con sombra, íconos lineales, barra inferior).
- Pantalla de voucher / detalle debe usar tipografía clara y montos destacados como en imagen 3.
- Pantalla de confirmación ("¡Depositaste!") debe usar fondo verde claro + ícono de éxito.

## 9. Restricciones de diseño (para el UI/UX)


- Mantener consistencia con la marca **Financiera Confianza** en todas las pantallas.
- Priorizar legibilidad en campo (posible sol brillante).
- Evitar colores saturados agresivos.
- Asegurar contraste WCAG AA mínimo.

