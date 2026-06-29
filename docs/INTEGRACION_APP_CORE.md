# Análisis de Integración — App Fuerza de Ventas ↔ App Core

**Fecha:** 2026-06-18  
**Propósito:** Determinar qué necesita App Core para que la App Fuerza de Ventas pueda conectarse y funcionar como cliente.

---

## 1. Arquitectura Actual de Fuerza de Ventas

### 1.1 Diagrama de la situación actual

```
┌──────────────────────────────────────────────────────┐
│               App Fuerza de Ventas (Flutter)          │
│                                                        │
│  ┌─────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │  Riverpod│  │ GoRouter │  │    Firebase (FCM)    │  │
│  │ (Estado) │  │ (Rutas)  │  │  (solo notificaciones)│  │
│  └────┬─────┘  └──────────┘  └──────────────────────┘  │
│       │                                                 │
│  ┌────▼──────────────────────────────────────────┐     │
│  │         Capa de Repositorios                    │     │
│  │  (Auth, Cartera, Ficha, Solicitud, Estado,     │     │
│  │   Buro, Cobranza, Prospeccion, Ruta,           │     │
│  │   Transmision, Documentos, Reportes)           │     │
│  └────┬──────────────────────────────┬───────────┘     │
│       │                              │                  │
│  ┌────▼──────────┐           ┌───────▼──────────┐      │
│  │  PostgreSQL   │           │   Google Maps    │      │
│  │   (local)     │           │   Directions API │      │
│  │  192.168.1.2  │           │   (solo ruta)    │      │
│  └───────────────┘           └──────────────────┘      │
└──────────────────────────────────────────────────────┘
```

### 1.2 Stack tecnológico actual

| Componente | Tecnología | Uso |
|---|---|---|
| Lenguaje | Dart 3 / Flutter | UI multiplataforma |
| Estado | flutter_riverpod ^2.6.1 | State management |
| Routing | go_router ^14.8.1 | Navegación |
| BD local | postgres ^3.5.11 directo | Persistencia principal |
| Seed data | SeedData (desde código) | Precarga de datos en PostgreSQL |
| Secure storage | flutter_secure_storage | Tokens, sesión, user data |
| Notificaciones | firebase_messaging | Push notifications |
| Notificaciones locales | flutter_local_notifications | Alertas locales |
| Mapas | google_maps_flutter | Visualización de rutas |
| Geolocalización | geolocator, geocoding | Ubicación GPS |
| Cámara | camera, image_picker | Captura de documentos |
| PDF | pdf, printing | Generación de expedientes |
| Firma | signature | Captura de firma |
| Background | workmanager | Sync nocturna (desactivada) |
| Connectivity | connectivity_plus | Detectar online/offline |
| Cache offline | Tablas PostgreSQL locales | 22 tablas de cache + cola offline |

### 1.3 ¿Qué consume actualmente?

| Recurso | ¿Consume? | Detalle |
|---|---|---|
| **API REST** | ❌ No | Cero llamadas HTTP a APIs propias |
| **Supabase** | ❌ No (comentado) | Todo el código Supabase está comentado |
| **Edge Functions** | ❌ No | Completamente desactivado |
| **PostgreSQL directo** | ✅ Sí | Conexión directa a base de datos compartida |
| **Google Maps API** | ✅ Sí | Solo para directions de ruta |
| **Firebase** | ✅ Sí | Solo FCM para notificaciones push |
| **GraphQL** | ❌ No | No implementado |
| **WebSockets** | ❌ No | No implementado |
| **Auth externo** | ❌ No | Login contra tabla `usuarios` en PostgreSQL |

### 1.4 Patrón de acceso a datos actual

```
[UI] → [Provider (Riverpod)] → [Repository] → [LocalDatasource] → [PgDatabase] → [PostgreSQL local]

                                        ┌─────────────────────────┐
                                        │  Sin capa API           │
                                        │  No hay servidor intermedio│
                                        │  La app habla directo a BD│
                                        └─────────────────────────┘
```

---

## 2. Fuentes de Datos Actuales por Módulo

### 2.1 Tabla completa

| # | Módulo | Fuente Actual | Tipo de Acceso | ¿Tiene cola offline? |
|---|--------|---------------|----------------|----------------------|
| 1 | **Auth / Login** | `usuarios` (PostgreSQL) | `SELECT ... WHERE codigo_empleado = ? AND password_hash = ?` | ❌ No |
| 2 | **Cartera** | `cartera` (PostgreSQL) | `SELECT * FROM cartera ORDER BY score_prioridad DESC` | ✅ `visitas_pendientes` |
| 3 | **Ficha Cliente** | Cache local PostgreSQL (ficha_cache, creditos_cache, pagos_cache, ofertas_cache, posicion_cache) | `SELECT ... FROM ficha_cache WHERE cliente_id = ?` | ✅ `visitas_pendientes` |
| 4 | **Solicitud** | `solicitudes_borrador`, `solicitudes_enviadas` (PostgreSQL) | `INSERT/UPDATE/DELETE` sobre tablas locales | ✅ `pendiente_sync = 1` |
| 5 | **Estado Solicitudes** | `solicitudes_enviadas`, `solicitudes_notas_internas` (PostgreSQL) | `SELECT ... ORDER BY fecha_creacion DESC` | ❌ No |
| 6 | **Buró** | Mock (respuestas hardcodeadas) | Siempre retorna `ResultadoBuro(normal, 0 deudas)` | ❌ No |
| 7 | **Cobranza** | `cartera_vencida_cache` (PostgreSQL) | `SELECT * FROM cartera_vencida_cache` | ✅ `acciones_cobranza_pendientes` |
| 8 | **Prospección** | `campanas_cache`, `pre_evaluaciones_pendientes` (PostgreSQL) | `SELECT ... FROM campanas_cache WHERE activa = 1` | ✅ `pre_evaluaciones_pendientes` |
| 9 | **Ruta** | `campanas_cache` (PostgreSQL) + Google Maps API | Direcciones desde Google Maps API externa | ❌ No |
| 10 | **Transmisión** | Desactivado (lanza excepción) | No operativo | ❌ No |
| 11 | **Documentos** | `solicitudes_documentos` (PostgreSQL) + Storage simulado | Subida local simulada (siempre retorna true) | ✅ `pendiente_sync = 1` |
| 12 | **Reportes** | Mock (datos hardcodeados) | Siempre retorna arrays vacíos o datos ficticios | ❌ No |
| 13 | **Sync Nocturna** | Desactivado (comentado) | Antes: Supabase → PostgreSQL local | ❌ No |
| 14 | **FCM Tokens** | Desactivado (comentado) | Antes: Supabase update `asesores_negocio.token_fcm` | ❌ No |

### 2.2 Columnas offline (pendiente_sync)

El mecanismo offline está basado en un flag `pendiente_sync SMALLINT DEFAULT 0` en varias tablas:

| Tabla | Flag | Propósito |
|---|---|---|
| `cartera` | `pendiente_sync` | Visitas marcadas sin conexión |
| `visitas_pendientes` | `pendiente_sync` | Cola de visitas por sincronizar |
| `solicitudes` | `pendiente_sync` | Solicitudes creadas offline |
| `solicitudes_enviadas` | `pendiente_sync` | Solicitudes enviadas sin conexión |
| `pre_evaluaciones_pendientes` | `pendiente_sync` | Pre-evaluaciones offline |
| `acciones_cobranza_pendientes` | `pendiente_sync` | Acciones de cobranza offline |
| `deserciones_pendientes` | `pendiente_sync` | Deserciones offline |
| `sync_queue` | — | Cola genérica de sincronización |

---

## 3. Módulos que Necesitan Conectarse a App Core

Todos los módulos necesitan conectarse a App Core. La tabla siguiente muestra la prioridad y el tipo de integración requerida:

| Prioridad | Módulo | ¿Qué necesita de App Core? | Tipo de operación |
|---|---|---|---|
| 🔴 **Crítica** | **Auth / Login** | Validar credenciales, obtener JWT, datos del asesor | `POST /auth/login` → `POST /auth/refresh` |
| 🔴 **Crítica** | **Cartera** | Obtener cartera del día, sincronizar visitas | `GET /cartera/diaria/:asesorId` → `POST /cartera/visitas` |
| 🔴 **Crítica** | **Solicitud** | Enviar solicitud, consultar solicitudes del mes | `POST /solicitudes` → `GET /solicitudes?asesorId=X&mes=Y` |
| 🔴 **Crítica** | **Ficha Cliente** | Obtener datos del cliente, posición, historial, ofertas | `GET /clientes/:id` → `GET /clientes/:id/posicion` |
| 🟡 **Alta** | **Estado Solicitudes** | Consultar estado, stream de cambios, notas internas | `GET /solicitudes/:id/estado` → `WebSocket /ws/solicitudes` |
| 🟡 **Alta** | **Documentos** | Subir documentos a Storage, obtener URLs | `POST /documentos/upload` → `GET /documentos/:solicitudId` |
| 🟡 **Alta** | **Transmisión** | Transmitir expediente completo, consultar estado | `POST /transmision/enviar` → `GET /transmision/estado/:solicitudId` |
| 🟡 **Alta** | **Buró** | Consultar central de riesgos (SBS), guardar resultado | `POST /buro/consultar` → `GET /buro/reciente/:clienteId` |
| 🟢 **Media** | **Cobranza** | Obtener morosos, registrar acciones de cobranza | `GET /cobranza/morosos/:asesorId` → `POST /cobranza/acciones` |
| 🟢 **Media** | **Prospección** | Obtener campañas, pre-evaluar cliente | `GET /campanas/activas` → `POST /prospeccion/pre-evaluar` |
| 🟢 **Media** | **Ruta** | Obtener zonas de trabajo, optimizar ruta | `GET /ruta/zonas/:asesorId` → `POST /ruta/optimizar` |
| 🔵 **Baja** | **Reportes** | Obtener métricas de productividad y avance | `GET /reportes/avance-diario/:asesorId` → `GET /reportes/productividad/:asesorId` |
| 🔵 **Baja** | **Sync Nocturna** | Sincronización programada de cartera | `GET /cartera/diaria/:asesorId?fecha=YYYY-MM-DD` |
| 🔵 **Baja** | **FCM Tokens** | Registrar token de dispositivo para notificaciones | `POST /asesores/token-fcm` |

---

## 4. Endpoints/Recursos que Necesita de App Core

### 4.1 API REST (Endpoint por módulo)

#### Auth (`/api/auth`)
```
POST   /api/auth/login              → { codigo_empleado, password }           → { token, asesor }
POST   /api/auth/refresh             → { token }                              → { token }
POST   /api/auth/logout              → { token }                              → { ok }
GET    /api/auth/me                  → (token en header)                      → { asesor }
PUT    /api/auth/token-fcm           → { token_fcm }                          → { ok }
```

#### Cartera (`/api/cartera`)
```
GET    /api/cartera/diaria/{asesorId}        → ?fecha=YYYY-MM-DD              → [ CarteraModel ]
POST   /api/cartera/visitas                  → [ VisitaData ]                 → { ok, sincronizados }
POST   /api/cartera/visita                   → { id, estado, resultado, ... } → { ok }
```

#### Clientes / Ficha (`/api/clientes`)
```
GET    /api/clientes/{id}                                             → FichaClienteModel
GET    /api/clientes/{id}/posicion                                    → PosicionCliente
GET    /api/clientes/{id}/creditos                                    → [ CreditoHistorico ]
GET    /api/clientes/{id}/pagos                                       → [ PagoMensual ]
GET    /api/clientes/{id}/oferta                                      → OfertaPreaprobada | null
PUT    /api/clientes/{id}/ubicacion                                   → { lat, lng } → { ok }
```

#### Solicitudes (`/api/solicitudes`)
```
POST   /api/solicitudes                            → SolicitudData            → { id, numero_expediente }
GET    /api/solicitudes                            → ?asesorId, ?mes, ?anio   → [ SolicitudModel ]
GET    /api/solicitudes/{id}                       →                          → SolicitudModel
GET    /api/solicitudes/{id}/estado                →                          → { estado, observaciones }
GET    /api/solicitudes/{id}/notas                 →                          → [ NotaInterna ]
POST   /api/solicitudes/{id}/notas                 → { contenido }            → NotaInterna
```

#### Buró (`/api/buro`)
```
POST   /api/buro/consultar          → { dni, firma_consentimiento }           → ConsultaBuroModel
GET    /api/buro/reciente/{id}      → ?dias=30                                 → ConsultaBuroModel | null
```

#### Cobranza (`/api/cobranza`)
```
GET    /api/cobranza/morosos/{asesorId}        → ?orden=dias_mora DESC        → [ ClienteMora ]
POST   /api/cobranza/acciones                  → AccionCobranza               → { ok }
POST   /api/cobranza/acciones/sync             → [ AccionCobranza ]           → { ok, sincronizados }
```

#### Prospección (`/api/prospeccion`)
```
GET    /api/prospeccion/campanas                → ?activas=true                → [ Campana ]
POST   /api/prospeccion/pre-evaluar             → { cliente_data }            → { score, oferta, ... }
POST   /api/prospeccion/deserciones/sync        → [ DesercionData ]           → { ok }
```

#### Ruta (`/api/ruta`)
```
GET    /api/ruta/zonas/{asesorId}               →                             → [ ZonaTrabajo ]
GET    /api/ruta/optimizar                      → { cliente_ids, origen }     → { orden_optimizado }
```

#### Documentos (`/api/documentos`)
```
POST   /api/documentos/upload               → multipart: { file, solicitud_id, tipo } → { url, id }
GET    /api/documentos/{solicitudId}         →                                          → [ Documento ]
DELETE /api/documentos/{id}                  →                                          → { ok }
```

#### Transmisión (`/api/transmision`)
```
POST   /api/transmision/enviar                  → { solicitud_id, documentos[] } → { estado, url_expediente }
GET    /api/transmision/estado/{solicitudId}     →                               → { paso, documentos, expediente }
```

#### Reportes (`/api/reportes`)
```
GET    /api/reportes/avance-diario/{asesorId}     → ?fecha=YYYY-MM-DD           → { visitados, pendientes, ... }
GET    /api/reportes/productividad/{asesorId}     → ?desde=&hasta=              → { solicitudes, aprobaciones, ... }
```

### 4.2 WebSockets / Realtime

```
ws://core/ws/solicitudes/{asesorId}       → Stream de cambios en estado de solicitudes
ws://core/ws/notificaciones/{asesorId}    → Stream de notificaciones push
```

### 4.3 Resumen de recursos por categoría

| Categoría | Cantidad | Tipo |
|---|---|---|
| Endpoints REST | ~35 | CRUD sobre recursos de negocio |
| WebSockets | 2 | Tiempo real para solicitudes y notificaciones |
| File Upload | 1 | Subida de documentos (multipart) |
| Auth endpoints | 5 | Login, refresh, logout, me, token-fcm |
| Sync batch | 4 | Sincronización masiva offline→online |

---

## 5. Diagrama de Comunicación Propuesto

### 5.1 Arquitectura objetivo

```
┌─────────────────────────────────────────────────────────────────────┐
│                      App Fuerza de Ventas (Flutter)                 │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    Capa de Red (NUEVA)                        │   │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐   │   │
│  │  │ ApiClient   │  │ AuthInterceptor │  │ OfflineQueue     │   │   │
│  │  │ (http/dio)  │  │ (JWT attach)  │  │ (cola pendiente)  │   │   │
│  │  └──────┬──────┘  └──────┬───────┘  └─────────┬──────────┘   │   │
│  └─────────┼────────────────┼────────────────────┼───────────────┘   │
│            │                │                    │                    │
│  ┌─────────▼────────────────▼────────────────────▼───────────────┐   │
│  │              Repositorios (MODIFICAR)                         │   │
│  │  Cada repositorio ahora:                                      │   │
│  │  1. Intenta API primero (online)                              │   │
│  │  2. Cache local en PostgreSQL si falla (offline)             │   │
│  │  3. Cola offline con pendiente_sync                           │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                              │                                       │
│  ┌───────────────────────────▼───────────────────────────────────┐   │
│  │              Cache Local (PostgreSQL)                          │   │
│  │  Tablas: cartera, ficha_cache, creditos_cache, pagos_cache,   │   │
│  │  ofertas_cache, posicion_cache, cartera_vencida_cache,        │   │
│  │  campanas_cache, solicitudes_borrador, solicitudes_enviadas,  │   │
│  │  solicitudes_documentos, consultas_buro, transmision_estado,  │   │
│  │  solicitudes_notas_internas                                   │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
┌─────────────────────────┐  ┌──────────────────────┐
│    App Core (BACKEND)   │  │   Google Maps API    │
│                         │  │   (externa, igual)   │
│  ┌───────────────────┐  │  └──────────────────────┘
│  │  REST API         │  │
│  │  /api/*           │  │
│  ├───────────────────┤  │
│  │  Auth (JWT)       │  │
│  ├───────────────────┤  │
│  │  WebSockets       │  │
│  │  /ws/*            │  │
│  ├───────────────────┤  │
│  │  File Storage     │  │
│  ├───────────────────┤  │
│  │  Business Logic   │  │
│  ├───────────────────┤  │
│  │  PostgreSQL (Core)│  │
│  └───────────────────┘  │
└─────────────────────────┘
```

### 5.2 Flujo de comunicación típico

```
App Fuerza de Ventas                    App Core
        │                                   │
        │  1. POST /api/auth/login          │
        │  { codigo: "123456",             │
        │    password: "123456" }          │
        │──────────────────────────────────>│
        │                                   │
        │  2. Validar credenciales          │
        │     Generar JWT                   │
        │                                   │
        │  3. { token, asesor }            │
        │<──────────────────────────────────│
        │                                   │
        │  4. Guardar JWT en                │
        │     Secure Storage                │
        │                                   │
        │  5. GET /api/cartera/diaria/      │
        │     { Authorization: Bearer JWT } │
        │──────────────────────────────────>│
        │                                   │
        │  6. Validar JWT                   │
        │     Query cartera                 │
        │                                   │
        │  7. [ CarteraModel[] ]           │
        │<──────────────────────────────────│
        │                                   │
        │  8. Cachear en PostgreSQL local   │
        │     Mostrar en UI                 │
        │                                   │
        │  [Offline]                        │
        │  9. Marcar visita sin conexión    │
        │     Guarda en PostgreSQL local    │
        │     con pendiente_sync=1          │
        │                                   │
        │  [Vuelve online]                  │
        │  10. POST /api/cartera/visitas/   │
        │      sync                         │
        │      [VisitaData[]]               │
        │──────────────────────────────────>│
        │                                   │
        │  11. Procesar batch               │
        │      { ok, sincronizados }        │
        │<──────────────────────────────────│
        │                                   │
```

### 5.3 Estrategia offline/online

```
                     ┌─────────────┐
                     │  ¿Hay red?  │
                     └──────┬──────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
          [ONLINE]                   [OFFLINE]
              │                           │
   ┌──────────▼──────────┐     ┌──────────▼──────────┐
   │ Llamar a API Core   │     │ Usar cache local    │
   │ Actualizar cache    │     │ (PostgreSQL)        │
   │ Retornar datos      │     │ Marcar pendiente    │
   └─────────────────────┘     │ de sync (flag=1)    │
                               └─────────────────────┘
                                        │
                                   [Vuelve online]
                                        │
                               ┌────────▼────────┐
                               │ Sincronizar cola │
                               │ pendiente_sync  │
                               │ vía API batch    │
                               └─────────────────┘
```

---

## 6. Recomendación de Arquitectura para la Integración

### 6.1 Principios rectores

| Principio | Descripción |
|---|---|
| **API-first** | App Core expone una REST API. Fuerza de Ventas nunca accede a la BD de Core directamente. |
| **Offline-first** | La app siempre guarda en cache local (PostgreSQL) antes de responder al usuario. La red es solo para sincronizar. |
| **JWT-based auth** | App Core emite JWTs. Fuerza de Ventas los almacena en Secure Storage y los envía en cada request. |
| **Batch sync** | La sincronización offline se hace en lotes, no registro por registro. |
| **Cola de pendientes** | Cada repositorio mantiene su propia cola de elementos pendientes de sincronizar. |
| **Cambio mínimo en UI** | No se rediseña la UI. Solo se modifica la capa de datos (repositorios). |

### 6.2 Cambios necesarios en Fuerza de Ventas

#### a) Agregar dependencias

```yaml
# pubspec.yaml - nuevas dependencias
dependencies:
  dio: ^5.4.0              # HTTP client con interceptors
  retrofit: ^4.1.0         # Type-safe API client generator
  retrofit_generator: ^8.1.0  # (dev)
  json_annotation: ^4.8.0  # JSON serialization
  json_serializable: ^6.7.0  # (dev)
  build_runner: ^2.4.0     # (dev)
```

#### b) Implementar nueva capa de red

```
lib/
├── core/
│   ├── network/
│   │   ├── api_client.dart          # Dio instance + interceptors
│   │   ├── api_exceptions.dart      # Manejo de errores HTTP
│   │   ├── auth_interceptor.dart    # Inyecta JWT en headers
│   │   ├── retry_interceptor.dart   # Reintentos con backoff
│   │   └── offline_queue.dart       # Sincronización batch
│   ├── storage/
│   │   └── local_db.dart            # Ya existe (cache en PostgreSQL)
│   └── supabase/
│       └── supabase_client.dart      # Eliminar o mantener stub
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_remote_datasource.dart  # NUEVO: llama a API Core
│   │   │   └── auth_repository.dart         # MODIFICAR: online→API, offline→local
│   ├── cartera/
│   │   ├── data/
│   │   │   ├── cartera_api.dart             # NUEVO: endpoint definitions (retrofit)
│   │   │   ├── cartera_remote_datasource.dart # MODIFICAR: usa API en vez de Supabase
│   │   │   └── cartera_repository.dart      # MODIFICAR: online/offline logic
│   ...
```

#### c) Estrategia de migración por fases

| Fase | Módulos | Esfuerzo | Dependencia |
|---|---|---|---|
| **1. Base** | Auth + ApiClient + OfflineQueue | 3 días | App Core debe tener `/api/auth/*` |
| **2. Core negocio** | Cartera + Solicitud + Ficha Cliente | 5 días | App Core debe tener cartera, clientes, solicitudes |
| **3. Secundarios** | Estado Solicitudes + Documentos + Transmisión + Buró | 4 días | App Core debe tener WS, upload, buró |
| **4. Resto** | Cobranza + Prospección + Ruta + Reportes | 3 días | App Core debe tener estos endpoints |
| **5. Sync** | Sync nocturna + FCM tokens | 1 día | App Core debe tener endpoint de cartera diaria |

### 6.3 Lo que App Core debe proveer

#### Backend mínimo viable (MVP)

```
App Core - Módulos esenciales para que Fuerza de Ventas funcione:

┌──────────────────────────────────────────────────┐
│                  App Core                         │
│                                                    │
│  ┌────────────────────────────────────────────┐   │
│  │ 1. Auth Module                              │   │
│  │    - Login con código_empleado + password   │   │
│  │    - JWT emisión y validación               │   │
│  │    - Refresh token                          │   │
│  │    - Registro de token FCM                  │   │
│  └────────────────────────────────────────────┘   │
│                                                    │
│  ┌────────────────────────────────────────────┐   │
│  │ 2. Cartera Module                           │   │
│  │    - Asignación diaria de clientes          │   │
│  │    - Registro de visitas (con geolocalización)│  │
│  │    - Sincronización batch                   │   │
│  └────────────────────────────────────────────┘   │
│                                                    │
│  ┌────────────────────────────────────────────┐   │
│  │ 3. Clientes Module                          │   │
│  │    - Datos maestros del cliente             │   │
│  │    - Posición financiera                    │   │
│  │    - Historial crediticio                   │   │
│  │    - Ofertas preaprobadas                   │   │
│  └────────────────────────────────────────────┘   │
│                                                    │
│  ┌────────────────────────────────────────────┐   │
│  │ 4. Solicitudes Module                       │   │
│  │    - Registro de solicitudes de crédito     │   │
│  │    - Flujo de aprobación                    │   │
│  │    - Notas internas                         │   │
│  │    - WebSocket para cambios de estado       │   │
│  └────────────────────────────────────────────┘   │
│                                                    │
│  ┌────────────────────────────────────────────┐   │
│  │ 5. Documentos Module                        │   │
│  │    - File Storage (upload/download)         │   │
│  │    - Asociación con solicitudes             │   │
│  └────────────────────────────────────────────┘   │
│                                                    │
│  ┌────────────────────────────────────────────┐   │
│  │ 6. Buró Module                              │   │
│  │    - Integración con central de riesgos SBS │   │
│  │    - Cache de consultas recientes           │   │
│  └────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────┘
```

### 6.4 Base de datos de App Core

App Core debe tener su propia base de datos PostgreSQL (NO la misma que usa Fuerza de Ventas localmente). Debe contener:

| Tabla Core | Relación con Fuerza de Ventas |
|---|---|
| `asesores_negocio` | Equivalente a `usuarios` local. Login, roles, token FCM |
| `agencia` | Agencias/sucursales. Relación 1:N con asesores |
| `clientes` | Datos maestros de clientes |
| `creditos` | Historial crediticio real (no cache) |
| `creditos_preaprobados` | Ofertas vigentes por cliente |
| `cartera_diaria` | Asignación diaria de clientes a asesores |
| `visitas` | Registro de visitas con geolocalización |
| `solicitudes_credito` | Solicitudes de crédito (core del negocio) |
| `solicitudes_notas_internas` | Notas de seguimiento |
| `solicitudes_documentos` | Documentos asociados a solicitudes |
| `consultas_buro` | Historial de consultas a SBS |
| `cartera_vencida` | Cartera en mora |
| `acciones_cobranza` | Acciones de recuperación |
| `campanas` | Campañas de prospección |
| `deserciones` | Clientes desertores |
| `transmision_expedientes` | Expedientes transmitidos |
| `pagos_mensuales` | Comportamiento de pago por cliente |
| `zonas_trabajo` | Zonas geográficas de trabajo |
| `sync_log` | Log de sincronización con dispositivos |

### 6.5 Consideraciones técnicas adicionales

| Aspecto | Recomendación |
|---|---|
| **Rate limiting** | Implementar en App Core para evitar abuso desde dispositivos |
| **Compresión** | Usar gzip en respuestas JSON grandes (cartera, historial) |
| **Paginación** | Endpoints de listas deben soportar `?page=&limit=` |
| **Versionado** | Prefijo `/api/v1/` para permitir evolución |
| **Documentación** | OpenAPI/Swagger para que Fuerza de Ventas consuma los endpoints |
| **Staging/QA** | App Core debe tener un entorno de pruebas para desarrollo |
| **Tiempo real** | WebSocket es opcional en MVP. Polling cada 30s es aceptable inicialmente |
| **File Storage** | Local filesystem o S3 compatible (MinIO para desarrollo) |
| **Errores** | Formato estándar: `{ "error": "codigo", "message": "descripción" }` |

---

## 7. Resumen Ejecutivo

| Pregunta | Respuesta |
|---|---|
| **¿Qué consume Fuerza de Ventas actualmente?** | PostgreSQL directo (sin API), Google Maps API (solo rutas), Firebase FCM (solo notificaciones). Todo el código de Supabase está comentado. |
| **¿Qué debería consumir de App Core?** | API REST con JWT. Datos de asesores, cartera, clientes, solicitudes, buró, documentos, cobranza, prospección, reportes. |
| **¿Cómo deben comunicarse?** | REST API (HTTP/HTTPS) + WebSockets para tiempo real. JWT en headers. Batch sync para operaciones offline. |
| **¿Qué necesita App Core para soportar Fuerza de Ventas?** | ~35 endpoints REST, 2 WebSockets, file storage, integración con SBS, y una base de datos PostgreSQL centralizada con ~19 tablas. |

---

## 8. Próximos Pasos Recomendados

1. **Definir el stack de App Core** (lenguaje, framework, base de datos)
2. **Construir MVP de App Core** con los 4 módulos esenciales: Auth, Cartera, Clientes, Solicitudes
3. **Implementar `ApiClient` en Fuerza de Ventas** con interceptors JWT y offline queue
4. **Migrar módulo Auth** primero (validar flujo completo de login JWT)
5. **Migrar Cartera** (el módulo más usado, validar sync offline/online)
6. **Migrar Solicitud y Ficha Cliente** (core del negocio)
7. **Agregar WebSockets** para tiempo real en estado de solicitudes
8. **Activar sync nocturna** contra App Core en vez de Supabase
9. **Probar en campo** con datos reales antes de desactivar PostgreSQL local
10. **Documentar API** con OpenAPI para facilitar mantenimiento futuro

---

*Documento generado el 2026-06-18 basado en el análisis del código fuente de App Fuerza de Ventas v1.0.0*
