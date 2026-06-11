# M6 — Captura de Documentos

## Contexto
El asesor fotografía los documentos del cliente con la cámara del dispositivo. La app valida automáticamente la nitidez de cada foto y la comprime antes de subirla a Supabase Storage. Un checklist visual muestra el estado de cada documento y el botón de envío sólo se activa cuando todos los obligatorios están listos.

---

## HU-21 · Fotografiar documentos del cliente con validación de nitidez

**Historia:** Como asesor de negocios, quiero capturar fotos de los documentos del cliente con validación de calidad automática, para evitar que documentos ilegibles rechacen la solicitud en el comité.

**Criterios de aceptación:**
- Documentos **obligatorios**: DNI anverso, DNI reverso, foto del negocio, foto del asesor con el cliente.
- Documentos **opcionales**: RUC, recibo de servicios, contrato de arriendo.
- La app valida automáticamente la nitidez de cada foto antes de aceptarla.
- Cada foto se comprime automáticamente a un máximo de 800 KB antes de subir.
- Un listado visual muestra el estado de cada documento: **LISTO / PENDIENTE / OBLIGATORIO**.
- El botón "Enviar solicitud" solo se activa cuando todos los obligatorios están en estado LISTO.

**Story points:** 8

### RF-53 — Captura con camera package y marco guía
- Usar el paquete `camera ^0.11.0`.
- La vista previa muestra un **marco guía superpuesto** indicando el tipo de documento esperado (rectángulo con esquinas marcadas y texto del tipo de documento).
- La captura se realiza al pulsar el botón de la cámara en la pantalla de preview.
- También permitir selección desde la galería usando `image_picker ^1.1.2`.

### RF-54 — Compresión y validación de nitidez
Después de capturar, la imagen pasa por dos procesos en orden:

**1. Validación de nitidez:**
- Calcular la **varianza del Laplaciano** de la imagen en escala de grises.
- Si el puntaje está por debajo del umbral configurado → solicitar retomar la foto con mensaje: _"La foto no es suficientemente nítida. Por favor, vuelve a capturarla."_
- Implementar con el paquete `image ^4.2.0`.

**2. Compresión:**
- Compresión iterativa reduciendo la calidad en pasos de 10 puntos hasta que el archivo sea menor a 800 KB.
- La imagen validada y comprimida se sube a Supabase Storage en la ruta:
  ```
  documentos/solicitudes/{solicitud_id}/{tipo_documento}.jpg
  ```

**Tipos de documento válidos para el nombre de archivo:**

| Tipo | Valor en Storage |
|---|---|
| DNI anverso | `dni_anverso` |
| DNI reverso | `dni_reverso` |
| RUC | `ruc` |
| Recibo de servicios | `recibo_servicios` |
| Foto del negocio | `foto_negocio` |
| Foto asesor + cliente | `foto_visita` |
| Contrato de arriendo | `contrato_arrendamiento` |

---

## HU-22 · Revisar y gestionar fotos adjuntas antes del envío

**Historia:** Como asesor de negocios, quiero revisar las fotos adjuntas y reemplazar las que no sean claras, para asegurar que el comité pueda leer todos los documentos sin problemas.

**Criterios de aceptación:**
- Galería horizontal de miniaturas con el nombre del documento debajo de cada una.
- Al tocar una miniatura, se abre visor a pantalla completa con zoom de pinza.
- El botón "Retomar" en el visor permite reemplazar esa foto sin afectar las demás.
- El botón "Eliminar" muestra diálogo de confirmación antes de borrar.

**Story points:** 3

### RF-55 — Visor de imágenes con zoom
- Usar el paquete `photo_view` para el visor a pantalla completa.
- Soporte de zoom mediante gesto de pinza (pinch-to-zoom).
- El visor muestra en el encabezado el nombre del tipo de documento.

### RF-56 — Eliminación de documento con confirmación
Al confirmar la eliminación, ejecutar en secuencia:
1. Borrar el archivo de Supabase Storage.
2. Eliminar el registro de la tabla `solicitudes_documentos`.
3. Actualizar la vista del listado/checklist.

> Si alguna operación falla: mostrar mensaje de error y **revertir** los cambios aplicados.

---

## Estructura de datos relevante

**Tabla: `solicitudes_documentos`**

| Campo | Tipo | Descripción |
|---|---|---|
| id | UUID (PK) | Identificador único |
| solicitud_id | UUID (FK → solicitudes_credito) | Solicitud a la que pertenece |
| tipo_documento | VARCHAR(40) | dni_anverso / dni_reverso / ruc / recibo_servicios / foto_negocio / foto_visita / contrato_arrendamiento |
| storage_url | TEXT | URL del archivo en Supabase Storage |
| tamanio_kb | INTEGER | Tamaño del archivo comprimido |
| nitidez_score | DECIMAL(5,2) | Puntaje de nitidez (varianza de Laplaciano) |
| created_at | TIMESTAMPTZ | Fecha de subida |

---

## Notas de implementación

- **Paquetes relevantes:** `camera ^0.11.0`, `image_picker ^1.1.2`, `image ^4.2.0`, `supabase_flutter`, `photo_view`
- **Widget compartido:** `DocumentoChecklist` en `shared/widgets/documento_checklist.dart`. Recibe la lista de documentos y su estado; emite eventos al tocar cada ítem.
- **ViewModel:** `DocumentosViewModel` gestiona el estado de cada documento: `pendiente`, `capturando`, `subiendo`, `listo`, `error`. Expone un getter `todosObligatoriosListos` que el botón de envío observa.
- **Marco guía de cámara:** overlay SVG/Canvas superpuesto a la vista previa de la cámara. El texto del tipo de documento se pasa como parámetro al abrir la pantalla de captura.
- **Subida a Storage:** hacer la subida en un `Isolate` separado para no bloquear la UI durante la compresión y carga. Mostrar indicador de progreso por documento.
- **Manejo de errores de Storage:** si la subida falla, reintentar automáticamente hasta 3 veces con espera exponencial. Si persiste el error, marcar el documento como `error` y mostrar botón "Reintentar".
- **Flujo posterior:** una vez que `todosObligatoriosListos = true`, el asesor puede continuar hacia M7 (consulta de buró) o directamente a M8 (transmisión) si el buró ya fue consultado.
