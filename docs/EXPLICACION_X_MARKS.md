# Explicación Detallada de los ❌ (X Marks) en la Integración

**Fecha:** 2026-06-18  
**Archivo de referencia:** `docs/INTEGRACION_APP_CORE.md`  
**Propósito:** Explicar en detalle cada elemento marcado con ❌, el porqué de su estado actual, y qué necesita App Core para convertirlos en ✅.

---

## Sección 1.3 — ¿Qué consume actualmente?

### ❌ 1. API REST

| Aspecto | Detalle |
|---|---|
| **¿Qué es?** | Una interfaz de programación de aplicaciones vía HTTP (GET, POST, PUT, DELETE) que permite a Fuerza de Ventas comunicarse con un servidor central. |
| **Estado actual** | **No implementado.** No existe una sola llamada `http.get()`, `http.post()`, `Dio`, `Retrofit` ni ningún cliente HTTP hacia un backend propio en todo el código. |
| **Evidencia** | Búsqueda en todo `lib/`: 0 ocurrencias de `Dio`, 0 de `ApiClient`, 0 de `http.get/post` hacia un backend propio. La única llamada HTTP externa es a Google Maps Directions API en `ruta/data/directions_service.dart`. |
| **¿Por qué es ❌?** | Porque cuando se comentó Supabase (para dejar de depender de ese servicio externo), **no se creó una API alternativa**. La app pasó a hablar directo a PostgreSQL como solución temporal de desarrollo. No hay un backend intermedio que exponga endpoints REST. |
| **¿Qué necesita App Core?** | App Core debe implementar una REST API con todos los endpoints listados en sección 4 del documento de integración (~35 endpoints). Fuerza de Ventas necesita agregar un `ApiClient` (idealmente con Dio + interceptors) para consumir esa API. |

**Código afectado:** Todos los repositorios. Ninguno tiene lógica HTTP hacia un backend.

---

### ❌ 2. Supabase

| Aspecto | Detalle |
|---|---|
| **¿Qué era?** | Backend-as-a-Service que proveía: base de datos PostgreSQL gestionada, autenticación, almacenamiento de archivos, edge functions (serverless), y realtime subscriptions vía WebSocket. |
| **Estado actual** | **Completamente comentado.** +100 etiquetas `SUPABASE_COMENTADO` en todos los módulos. El archivo `supabase_client.dart` es un stub vacío. |
| **Evidencia** | `lib/core/supabase/supabase_client.dart` línea 28: `class SupabaseService { static final SupabaseService instance = SupabaseService._(); SupabaseService._(); Future<void> initialize() async {} }` — no hace nada. |
| **¿Por qué es ❌?** | Por decisión arquitectónica. Se decidió desarrollar solo con PostgreSQL local para no depender de un servicio externo durante el desarrollo. Pero al comentar Supabase, se perdió: (1) el backend como intermediario, (2) edge functions para lógica de negocio, (3) realtime para estado de solicitudes, (4) storage para documentos. |
| **¿Qué necesita App Core?** | App Core debe reemplazar **cada funcionalidad** que antes proveía Supabase: REST en vez de Supabase client, File Storage en vez de Supabase Storage, WebSockets en vez de Supabase Realtime, y lógica de negocio server-side en vez de Edge Functions. |

**Código afectado:** `lib/core/supabase/supabase_client.dart`, `lib/main.dart`, `lib/core/services/sync_service.dart`, y todos los módulos de features.

---

### ❌ 3. Edge Functions (Supabase)

| Aspecto | Detalle |
|---|---|
| **¿Qué eran?** | Funciones serverless escritas en TypeScript que se ejecutaban en el edge de Supabase. Fuerza de Ventas invocaba: `consulta-posicion`, `pre-evaluar`, `consulta-buro`, `registrar-solicitud`, `registrar-pago`. |
| **Estado actual** | **Completamente desactivado.** Todos los llamados a `.functions.invoke()` están comentados. |
| **Evidencia** | `lib/features/buro/data/buro_repository.dart` línea 85: `// final response = await _supabase.functions.invoke('consulta-buro', body: {...})` — comentado. En `ficha_repository.dart` también están comentadas las llamadas a `consulta-posicion`. |
| **¿Por qué es ❌?** | Porque esas edge functions contenían lógica de negocio IMPORTANTE: (1) consulta a central de riesgos SBS, (2) scoring de pre-evaluación, (3) registro oficial de solicitudes, (4) registro de pagos. Sin App Core, esa lógica no existe. Los módulos que dependían de ellas ahora retornan **datos mock** (buró, reportes) o **no operan** (transmisión). |
| **¿Qué necesita App Core?** | App Core debe implementar esa lógica como endpoints REST con la misma funcionalidad: `POST /api/buro/consultar`, `POST /api/prospeccion/pre-evaluar`, `POST /api/solicitudes`, `POST /api/cobranza/pagos`, etc. |

**Código afectado:** `lib/features/buro/`, `lib/features/ficha_cliente/`, `lib/features/solicitud/`, `lib/features/prospeccion/`.

---

### ❌ 4. GraphQL

| Aspecto | Detalle |
|---|---|
| **¿Qué es?** | Lenguaje de consulta para APIs que permite al cliente pedir exactamente los datos que necesita. |
| **Estado actual** | **No implementado.** No hay dependencias GraphQL en `pubspec.yaml`, no hay clientes GraphQL, ni schemas, ni queries. |
| **Evidencia** | Cero ocurrencias de `graphql`, `gql`, `GraphQLClient` en todo el proyecto. |
| **¿Por qué es ❌?** | Porque nunca fue parte de la arquitectura. La app se diseñó originalmente con Supabase (que usa REST + Realtime), no GraphQL. No hay planes inmediatos para implementarlo. |
| **¿Qué necesita App Core?** | No es necesario. App Core puede ser REST. Si en el futuro se requiere GraphQL, se agrega como capa adicional sobre la misma lógica de negocio. |

**Código afectado:** Ninguno. Es una no-implementación deliberada.

---

### ❌ 5. WebSockets

| Aspecto | Detalle |
|---|---|
| **¿Qué es?** | Protocolo de comunicación bidireccional en tiempo real sobre TCP. Permite al servidor enviar datos al cliente sin que el cliente los solicite. |
| **Estado actual** | **No implementado.** No hay `WebSocket`, `socket_io`, ni ninguna conexión persistente en todo el código. |
| **Evidencia** | Cero ocurrencias de `WebSocket`, `socket_io`, `IO.Socket` en todo el proyecto. |
| **¿Por qué es ❌?** | El módulo de **Estado Solicitudes** usaba Supabase Realtime (que internamente usa WebSockets) para recibir cambios en vivo cuando una solicitud cambiaba de estado. Al comentar Supabase, se perdió esa capacidad. Ahora el stream del `EstadoRepository` emite una sola vez y se cierra. |
| **¿Qué necesita App Core?** | App Core debe implementar un WebSocket (ej: `ws://core/ws/solicitudes/{asesorId}`) que emita eventos cuando el estado de una solicitud cambie. Fuerza de Ventas necesita reconectar el `EstadoRepository` a ese WebSocket. |

**Código afectado:** `lib/features/estado_solicitudes/data/estado_repository.dart` — stream reemplazado por emisión única.

---

### ❌ 6. Auth externo (JWT / OAuth)

| Aspecto | Detalle |
|---|---|
| **¿Qué es?** | Sistema de autenticación centralizado donde un servidor emite tokens (JWT) que el cliente usa para autenticarse en cada request. |
| **Estado actual** | **Login local contra PostgreSQL.** El `AuthRemoteDatasource` ejecuta directamente: `SELECT * FROM usuarios WHERE codigo_empleado = ? AND password_hash = ?` contra la BD local. |
| **Evidencia** | `lib/features/auth/data/auth_remote_datasource.dart` línea 11: `final sql = "SELECT * FROM usuarios WHERE codigo_empleado = ? AND password_hash = ?";` — consulta directa a PostgreSQL. |
| **¿Por qué es ❌?** | (1) **Inseguro:** la validación de credenciales ocurre en el dispositivo, no en un servidor. (2) **No hay JWT:** el "token" que se guarda es el código de empleado (`token: codigoEmpleado`). (3) **No escalable:** cada dispositivo necesita acceso de lectura a la tabla `usuarios` de la BD. (4) **No hay sesión centralizada:** no se puede revocar una sesión desde el servidor. |
| **¿Qué necesita App Core?** | Endpoint `POST /api/auth/login` que reciba `{ codigo_empleado, password }`, valide contra la BD central, y devuelva `{ token: "jwt...", asesor: {...} }`. Fuerza de Ventas debe enviar ese JWT en el header `Authorization: Bearer <token>` en cada request. |

**Código afectado:** `lib/features/auth/data/auth_remote_datasource.dart` (reescribir), `lib/features/auth/data/auth_repository.dart` (agregar lógica JWT).

---

## Sección 2.1 — Módulos sin cola offline (pendiente_sync)

### ❌ 7. Auth / Login — Sin cola offline

| Aspecto | Detalle |
|---|---|
| **¿Qué le falta?** | No hay mecanismo para que un usuario pueda iniciar sesión sin conexión a App Core. |
| **Estado actual** | El login depende 100% de PostgreSQL local. Si la BD local no responde, el login falla. |
| **¿Por qué es ❌?** | El login es el punto de entrada. Para que sea offline-first, debería cachear las credenciales localmente después del primer login exitoso, permitiendo login offline con validación local mientras se sincroniza en segundo plano. |
| **¿Qué necesita App Core?** | Endpoint `POST /api/auth/login`. Además, Fuerza de Ventas debe guardar un hash local para validación offline. |

---

### ❌ 8. Estado Solicitudes — Sin cola offline

| Aspecto | Detalle |
|---|---|
| **¿Qué le falta?** | No hay cola de consultas offline. Si no hay conexión, no se pueden listar solicitudes. |
| **Estado actual** | Lee de `solicitudes_enviadas` local (cache). Pero no tiene un mecanismo formal de cola para solicitar datos cuando vuelva la conexión. |
| **¿Por qué es ❌?** | Porque cuando se comentó Supabase Realtime, se perdió el stream en vivo. La solución actual emite una sola vez (snapshot) y se cierra. No hay polling ni reconexión automática. |
| **¿Qué necesita App Core?** | WebSocket `ws://core/ws/solicitudes/{asesorId}` para tiempo real, o endpoint `GET /api/solicitudes?asesorId=X` para polling. Fuerza de Ventas debe cachear localmente los últimos estados y hacer diff en cada sincronización. |

---

### ❌ 9. Buró — Sin cola offline (y sin datos reales)

| Aspecto | Detalle |
|---|---|
| **¿Qué le falta?** | No tiene fuente de datos real ni cola offline. Todo es mock. |
| **Estado actual** | `BuroRepository.consultar()` siempre retorna `ResultadoBuro(calificacionSbs: normal, numEntidadesDeuda: 0, deudaTotal: 0)`. No consulta ninguna API real de central de riesgos. |
| **Evidencia** | `lib/features/buro/data/buro_repository.dart` línea 66: `return ConsultaBuroModel(... resultado: const ResultadoBuro(calificacionSbs: CalificacionSbs.normal, ...))` — siempre mock. |
| **¿Por qué es ❌?** | (1) La edge function `consulta-buro` de Supabase estaba comentada. (2) La integración con SBS (Superintendencia de Banca, Seguros y AFP) es compleja y requiere un backend. (3) Sin App Core, no hay un servicio que haga la consulta real a SBS. (4) No hay cola offline porque el módulo directamente no funciona. |
| **¿Qué necesita App Core?** | Endpoint `POST /api/buro/consultar` que se integre con la API de SBS (o un proveedor de risk scoring). Cache local de la última consulta (30 días) para modo offline. |

---

### ❌ 10. Ruta — Sin cola offline

| Aspecto | Detalle |
|---|---|
| **¿Qué le falta?** | No hay cola offline para zonas de trabajo ni optimización de ruta. |
| **Estado actual** | `RutaRepository.getZonasTrabajo()` retorna lista vacía. La actualización de ubicación de cliente es no-op. |
| **Evidencia** | `lib/features/ruta/data/ruta_repository.dart` línea 31: `return [];` — retorna vacío. |
| **¿Por qué es ❌?** | (1) Originalmente las zonas de trabajo se obtenían de Supabase. (2) Al comentar Supabase, se perdió la fuente de datos geográficos. (3) La optimización de ruta requiere lógica del lado del servidor (TSP - Traveling Salesman Problem). (4) No hay cola offline porque el módulo no tiene datos que sincronizar. |
| **¿Qué necesita App Core?** | Endpoint `GET /api/ruta/zonas/{asesorId}` con datos de zonas geográficas. Opcionalmente `POST /api/ruta/optimizar` para orden óptimo de visitas. Fuerza de Ventas debe cachear estas zonas localmente. |

---

### ❌ 11. Transmisión — No operativo

| Aspecto | Detalle |
|---|---|
| **¿Qué le falta?** | Todo. El módulo está desactivado. |
| **Estado actual** | `TransmisionRepository.enviar()` lanza `Exception('Transmisión desactivada en modo desarrollo local')`. El stream de estado retorna `Stream.empty()`. |
| **Evidencia** | `lib/features/transmision/data/transmision_repository.dart` línea 109: `throw Exception('Transmisión desactivada en modo desarrollo local');`. |
| **¿Por qué es ❌?** | (1) La transmisión de expedientes dependía de edge functions de Supabase para generar PDFs y subirlos a Storage. (2) El flujo completo involucraba: generar expediente PDF, subir documentos a Storage, enviar a sistema central (core bancario). (3) Sin App Core, no hay servidor que reciba, procesa y almacene el expediente. (4) No hay cola offline porque el módulo está deliberadamente roto. |
| **¿Qué necesita App Core?** | Endpoints `POST /api/transmision/enviar`, `GET /api/transmision/estado/{id}`. También file Storage para PDFs y documentos. Cola offline en Fuerza de Ventas para transmisiones pendientes. |

---

### ❌ 12. Reportes — Datos mock

| Aspecto | Detalle |
|---|---|
| **¿Qué le falta?** | Datos reales. |
| **Estado actual** | `ReportesRepository.getAvanceDiario()` retorna `{ visitados: 0, pendientes: 12 }` fijo. `getProductividad()` retorna `{ solicitudes: 0, aprobados: 0 }` fijo. No consulta ninguna fuente real. |
| **Evidencia** | `lib/features/reportes/data/reportes_repository.dart` línea 23-25: hardcodeado. |
| **¿Por qué es ❌?** | (1) Los reportes se obtenían de consultas a Supabase (`cartera_diaria`, `solicitudes_credito`). (2) Al comentar Supabase, se perdieron las consultas agregadas. (3) No se implementó una alternativa porque los reportes son de baja prioridad para el desarrollo local. (4) No hay cola offline — los reportes siempre son datos frescos del backend. |
| **¿Qué necesita App Core?** | Endpoints `GET /api/reportes/avance-diario/{asesorId}` y `GET /api/reportes/productividad/{asesorId}` con lógica de agregación SQL del lado del servidor. Fuerza de Ventas puede cachear los últimos reportes localmente. |

---

### ❌ 13. Sync Nocturna — Desactivada

| Aspecto | Detalle |
|---|---|
| **¿Qué era?** | Tarea programada con Workmanager que ejecutaba `SyncService.executeSyncTask()` cada 24 horas (a las 10 PM) para descargar la cartera del día siguiente desde Supabase. |
| **Estado actual** | **Completamente comentada.** El método `executeSyncTask()` solo cuenta registros en `cartera` y muestra una notificación. No descarga nada. |
| **Evidencia** | `lib/core/services/sync_service.dart` líneas 30-56: todo el bloque de sincronización con Supabase está comentado. |
| **¿Por qué es ❌?** | (1) Dependía de Supabase para obtener la cartera del día siguiente (`cartera_diaria` + join con `clientes`). (2) Sin App Core, no hay un endpoint que sirva la cartera programada. (3) La sync nocturna es crítica para producción porque precarga la cartera antes de que el asesor salga a campo. (4) Workmanager sigue activo en `main.dart`, pero la tarea no hace nada útil. |
| **¿Qué necesita App Core?** | Endpoint `GET /api/cartera/diaria/{asesorId}?fecha=YYYY-MM-DD` que devuelva la cartera asignada para una fecha específica. `SyncService` debe consumir ese endpoint y reemplazar el cache local. |

---

### ❌ 14. FCM Tokens — Desactivado

| Aspecto | Detalle |
|---|---|
| **¿Qué era?** | Después del login, la app registraba el token FCM (Firebase Cloud Messaging) del dispositivo en Supabase, asociándolo al asesor para poder enviarle notificaciones push personalizadas. |
| **Estado actual** | **Completamente comentado.** Los métodos `_guardarTokenFcm()`, `_actualizarTokenFcm()`, y `_configurarFcmCallbacks()` están comentados. |
| **Evidencia** | `lib/features/auth/presentation/providers/auth_provider.dart` líneas 192-225: los 3 métodos están comentados. |
| **¿Por qué es ❌?** | (1) Dependía de Supabase para hacer `UPDATE asesores_negocio SET token_fcm = ? WHERE id = ?`. (2) Sin App Core, no hay un endpoint que reciba y almacene el token FCM. (3) Firebase FCM sigue funcionando (se inicializa en `main.dart`), pero los tokens no se asocian a ningún asesor, por lo que las notificaciones push no pueden ser dirigidas a un usuario específico. (4) Las notificaciones locales aún funcionan, pero no las push contextuales (ej: "Tu solicitud cambió a APROBADO"). |
| **¿Qué necesita App Core?** | Endpoint `PUT /api/auth/token-fcm` que reciba `{ token_fcm: "..." }` con autenticación JWT y lo asocie al asesor. Fuerza de Ventas debe reactivar `_guardarTokenFcm()` en el flujo de login y `_actualizarTokenFcm()` en el callback de cambio de token. |

---

## Resumen: ¿Por qué hay tantos ❌?

| Causa raíz | Impacto |
|---|---|
| **Supabase fue comentado como solución temporal** | Se perdieron 4 servicios: REST API, Edge Functions, Realtime, Storage |
| **No se construyó un reemplazo** | No hay App Core aún. La app quedó con PostgreSQL local como única fuente de datos |
| **Módulos que dependían de Supabase ahora son stubs** | Buró, Transmisión, Reportes no funcionan; Ruta tiene datos vacíos; Sync nocturna está muerta |
| **Auth es local e inseguro** | No hay JWT, no hay sesión centralizada, no hay revocación de tokens |
| **Offline está a medias** | Solo 5 de 14 módulos tienen cola offline; el resto depende de conexión permanente |

## La solución

App Core debe reconstruir **todo lo que Supabase proveía** pero como un backend propio:

```
Supabase (antes)                    App Core (futuro)
────────────────────                ────────────────────
Supabase Client (REST)              → REST API /api/*
Supabase Edge Functions             → Endpoints server-side
Supabase Realtime (WebSocket)       → WebSocket /ws/*
Supabase Storage                    → File Storage (S3/MinIO)
Supabase Auth (GoTrue)              → JWT Auth
```

Y Fuerza de Ventas debe agregar:

```
ApiClient (Dio + JWT Interceptor)   → Consumir API Core
OfflineQueue mejorada               → Sincronización batch
Realtime reconectado                → WebSocket para estado solicitudes
```

---

*Documento generado el 2026-06-18 como complemento a `docs/INTEGRACION_APP_CORE.md`*
