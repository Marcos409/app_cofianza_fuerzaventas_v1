# App Fuerza de Ventas — Índice de Módulos

**Curso:** Desarrollo de Aplicaciones Móviles 2026  
**Docente:** Mg. Guillermo E. Peña García  
**Stack:** Flutter · Supabase · SQLite · Firebase Cloud Messaging  
**Arquitectura:** MVVM con Riverpod (StateNotifier)

---

## Descripción del proyecto
App móvil para asesores de negocios de microfinanzas en Perú. Reemplaza el expediente físico: descarga la cartera del día, permite registrar solicitudes en campo sin internet, captura fotos de documentos, consulta el buró de crédito y transmite electrónicamente la solicitud completa al comité de evaluación.

**Ciclo del crédito:** Pre-evaluación → Evaluación → Aprobación → Desembolso → Recuperación

---

## Módulos y archivos de instrucciones

| # | Módulo | Archivo | HU | RF |
|---|---|---|---|---|
| M0 | Autenticación y perfiles | `M00_autenticacion_perfiles.md` | HU-01 a HU-03 | RF-01 a RF-08 |
| M1 | Cartera diaria | `M01_cartera_diaria.md` | HU-04 a HU-07 | RF-09 a RF-18 |
| M2 | Planificación de ruta | `M02_planificacion_ruta.md` | HU-08 a HU-10 | RF-19 a RF-26 |
| M3 | Ficha del cliente | `M03_ficha_cliente.md` | HU-11 a HU-14 | RF-27 a RF-36 |
| M4 | Pre-evaluación y prospección | `M04_preevaluacion_prospeccion.md` | HU-15 a HU-16 | RF-37 a RF-42 |
| M5 | Captura de solicitud de crédito | `M05_captura_solicitud.md` | HU-17 a HU-20 | RF-43 a RF-54 |
| M6 | Captura de documentos | `M06_captura_documentos.md` | HU-21 a HU-22 | RF-55 a RF-60 |
| M7 | Consulta de buró y listas | `M07_consulta_buro_listas.md` | HU-23 a HU-24 | RF-61 a RF-66 |
| M8 | Transmisión electrónica | `M08_transmision_electronica.md` | HU-25 a HU-26 | RF-67 a RF-72 |
| M9 | Estado de solicitudes | `M09_estado_solicitudes.md` | HU-27 a HU-29 | RF-73 a RF-79 |
| M10 | Recuperación de cartera vencida | `M10_recuperacion_cartera.md` | HU-30 a HU-31 | RF-80 a RF-84 |
| M11 | Reportes y supervisión | `M11_reportes_supervision.md` | HU-32 a HU-33 | RF-85 a RF-90 |

**Total:** 33 Historias de Usuario · 90 Requerimientos Funcionales

---

## Dependencias principales (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  supabase_flutter: ^2.5.0
  sqflite: ^2.3.3
  path: ^1.9.0
  go_router: ^14.0.0
  google_maps_flutter: ^2.9.0
  geolocator: ^12.0.0
  geocoding: ^3.0.0
  camera: ^0.11.0
  image_picker: ^1.1.2
  image: ^4.2.0
  fl_chart: ^0.68.0
  flutter_local_notifications: ^17.2.2
  firebase_messaging: ^15.1.3
  signature: ^5.4.1
  pdf: ^3.11.1
  printing: ^5.13.2
  intl: ^0.19.0
  connectivity_plus: ^6.0.5
  workmanager: ^0.5.2
  flutter_secure_storage: ^9.2.2
```

---

## Estructura de carpetas del proyecto Flutter

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # MaterialApp y configuración global
│   └── router.dart                 # GoRouter con rutas nombradas
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # Paleta de colores de la entidad
│   │   └── app_strings.dart        # Textos y etiquetas
│   ├── network/
│   │   └── network_monitor.dart    # Stream de conectividad
│   ├── storage/
│   │   └── local_db.dart           # Inicialización y migraciones SQLite
│   └── supabase/
│       └── supabase_client.dart    # Instancia única de SupabaseClient
├── features/
│   ├── auth/          # M0
│   ├── cartera/       # M1
│   ├── ruta/          # M2
│   ├── ficha_cliente/ # M3
│   ├── solicitud/     # M4 y M5
│   ├── documentos/    # M6
│   ├── buro/          # M7
│   ├── estado_solicitudes/ # M8 y M9
│   ├── cobranza/      # M10
│   └── reportes/      # M11
└── shared/
    ├── widgets/
    │   ├── cliente_card.dart
    │   ├── badge_tipo_gestion.dart
    │   ├── semaforo_riesgo.dart
    │   ├── signature_pad.dart
    │   ├── stepper_solicitud.dart
    │   └── documento_checklist.dart
    └── utils/
        ├── formatters.dart         # Moneda, fechas, DNI censurado
        ├── validators.dart         # Validaciones de formularios
        └── calculadora_credito.dart # Fórmula de amortización francesa
```

---

## Patrones transversales

### Offline-first (aplica a M1, M5, M7, M10)
1. El ViewModel solicita datos al Repository.
2. El Repository verifica conectividad con `connectivity_plus`.
3. **Con red:** consulta Supabase → guarda en SQLite → devuelve datos.
4. **Sin red:** lee de SQLite → devuelve datos con indicador "offline".
5. Al reconectar: el Repository procesa la cola de filas con `pendiente_sync = true` y las envía en lote.

### MVVM con Riverpod
- Cada módulo tiene exactamente un `ViewModel` (`StateNotifier`) y una o más `Screen` (`ConsumerWidget`).
- El estado es una clase **inmutable**. Los Widgets usan `ref.watch(provider)`.
- La Vista **nunca** accede directamente a Supabase ni a SQLite.

### RLS de Supabase
- Los asesores solo acceden a filas donde `asesor_id = auth.uid()`.
- Los supervisores acceden a todas las filas de su `agencia_id`.
- Los administradores tienen acceso completo a su institución.
