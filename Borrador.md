# App Clientes — Banco Confianza (Banca Móvil)

## Documentación Técnica para Construcción

---

## 1. Resumen

Aplicación móvil para clientes de Banco Confianza que permita consultar productos (cuentas, créditos, tarjetas), realizar operaciones (pagos, transferencias), gestionar perfil, y recibir notificaciones. Se integrará al ecosistema existente compartiendo la base de datos `bd_fuerza_ventas` y consumiendo la API del Core Banking (`app_banco_core`).

---

## 2. Tecnología Sugerida

### Opción Recomendada: **Flutter**

| Criterio | Flutter | Kotlin Nativo |
|---|---|---|
| Consistencia con App Fuerza de Ventas | ✅ Misma tecnología, reuso de patrones | ❌ Tecnología diferente |
| Código compartido (Android/iOS) | ✅ Single codebase | ❌ Desarrollo separado |
| Tiempo de desarrollo | ✅ Más rápido | ❌ Más lento |
| Estado del ecosistema | ✅ Maduro (Riverpod, go_router, etc.) | ✅ Maduro (Jetpack Compose) |
| Conexión directa a PostgreSQL | ✅ Posible (mismo driver) | ❌ No recomendado |
| Justificación | La App Fuerza de Ventas ya usa Flutter con Riverpod + go_router + PostgreSQL directo. Usar Flutter permite compartir modelos de datos, lógica de negocio, y patrones de arquitectura. Además, el backend ya tiene endpoints preparados para clientes en `/cliente/*`. |

**Decisión: Flutter 3.11.5+** con Dart 3.x.

---

## 3. Arquitectura Sugerida

### Clean Architecture + Riverpod

```
lib/
├── app/
│   ├── app.dart                  # Widget raíz
│   └── router.dart               # Configuración de rutas (go_router)
├── core/
│   ├── constants/                # Constantes, colores, temas
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── api_constants.dart
│   ├── network/                  # Capa de red
│   │   ├── api_client.dart       # HTTP client (dio/http)
│   │   ├── api_interceptors.dart # Auth interceptor
│   │   └── api_exceptions.dart
│   ├── storage/                  # Almacenamiento local
│   │   ├── secure_storage.dart   # Tokens, sesión
│   │   └── local_db.dart         # SQLite cache (sqflite)
│   ├── services/                 # Servicios globales
│   │   ├── auth_service.dart
│   │   ├── notification_service.dart
│   │   └── sync_service.dart
│   └── theme/                    # Tema de la app
│       └── app_theme.dart
├── features/
│   ├── auth/                     # Módulo de autenticación
│   │   ├── data/
│   │   │   ├── datasources/      # API calls
│   │   │   └── repositories/     # Implementación repositorio
│   │   ├── domain/
│   │   │   ├── models/           # Modelos de dominio
│   │   │   └── repositories/     # Interfaces repositorio
│   │   └── presentation/
│   │       ├── providers/        # Riverpod providers
│   │       ├── screens/          # Pantallas
│   │       └── widgets/          # Widgets reutilizables
│   ├── dashboard/                # Módulo inicio
│   ├── cuentas/                  # Módulo cuentas de ahorro
│   ├── creditos/                 # Módulo créditos
│   ├── pagos/                    # Módulo pagos
│   ├── movimientos/              # Módulo movimientos
│   ├── tarjetas/                 # Módulo tarjetas
│   ├── perfil/                   # Módulo perfil
│   └── notificaciones/           # Módulo notificaciones
└── shared/                       # Widgets compartidos
    ├── widgets/
    │   ├── app_button.dart
    │   ├── app_text_field.dart
    │   ├── loading_overlay.dart
    │   └── error_screen.dart
    └── utils/
        ├── formatters.dart       # Moneda, fecha, etc.
        └── validators.dart       # Validaciones de formularios
```

---

## 4. Módulos Funcionales y Pantallas

### 4.1. Autenticación

| Pantalla | Ruta | Descripción |
|---|---|---|
| Login | `/login` | Ingreso con número de documento + contraseña. Máximo 5 intentos fallidos, luego bloqueo de 30 min. |
| Recuperar Contraseña | `/recuperar` | Solicitud de restablecimiento de contraseña (vía email/SMS) |
| Registro Biométrico | `/registro-biometrico` | Configurar huella dactilar / Face ID para acceso rápido |
| PIN de Seguridad | `/configurar-pin` | Configurar PIN de 6 dígitos para operaciones |

### 4.2. Dashboard (Inicio)

| Pantalla | Ruta | Descripción |
|---|---|---|
| Home | `/home` | Saldo total consolidado, últimos movimientos, acceso rápido a pagos, notificaciones no leídas, resumen de productos |
| Dashboard Completo | `/dashboard` | Vista detallada con gráficos de gastos, ingresos, evolución de ahorros |

### 4.3. Cuentas

| Pantalla | Ruta | Descripción |
|---|---|---|
| Lista de Cuentas | `/cuentas` | Tarjetas con cada cuenta de ahorro (saldo, tipo, moneda) |
| Detalle Cuenta | `/cuentas/:id` | Saldo, últimos movimientos, opciones de transferencia |
| Historial Cuenta | `/cuentas/:id/movimientos` | Todos los movimientos con filtros por fecha/tipo |

### 4.4. Créditos

| Pantalla | Ruta | Descripción |
|---|---|---|
| Lista de Créditos | `/creditos` | Tarjetas con cada crédito (saldo, estado, cuotas) |
| Detalle Crédito | `/creditos/:codCuenta` | Información completa: monto desembolsado, saldo, TEA, cuotas restantes |
| Cronograma de Pagos | `/creditos/:codCuenta/cronograma` | Tabla de cuotas con fechas, montos y estado |
| Solicitar Crédito | `/creditos/solicitar` | Formulario de solicitud de nuevo crédito |

### 4.5. Pagos

| Pantalla | Ruta | Descripción |
|---|---|---|
| Pago de Cuota | `/pagos/pagar-cuota` | Seleccionar crédito y cuota a pagar, confirmar monto |
| Pago a Terceros | `/pagos/terceros` | Transferencia a cuenta de tercero (CuentaCCI o número de documento) |
| Recarga Móvil | `/pagos/recarga` | Recarga de teléfono móvil (operadores: Movistar, Claro, Entel, Bitel) |
| Pago de Servicios | `/pagos/servicios` | Pago de recibos (agua, luz, internet, etc.) |
| Confirmar Pago | `/pagos/confirmar` | Pantalla de confirmación con token/PIN |

### 4.6. Movimientos

| Pantalla | Ruta | Descripción |
|---|---|---|
| Últimos Movimientos | `/movimientos` | Lista cronológica con filtros (fecha, tipo, monto) |
| Detalle Movimiento | `/movimientos/:id` | Información completa de la operación |

### 4.7. Tarjetas

| Pantalla | Ruta | Descripción |
|---|---|---|
| Mis Tarjetas | `/tarjetas` | Lista de tarjetas de crédito/débito (enmascaradas) |
| Detalle Tarjeta | `/tarjetas/:id` | Línea de crédito, saldo utilizado, fecha de corte, fecha de pago |
| Bloquear Tarjeta | `/tarjetas/:id/bloquear` | Confirmación para bloqueo temporal/permanente |

### 4.8. Perfil

| Pantalla | Ruta | Descripción |
|---|---|---|
| Mi Perfil | `/perfil` | Datos personales, documento, email, teléfono |
| Editar Perfil | `/perfil/editar` | Actualizar email, teléfono, dirección |
| Cambiar Contraseña | `/perfil/cambiar-password` | Formulario de cambio de contraseña |
| Configuración | `/configuracion` | Notificaciones, biometría, PIN, tema, idioma |
| Acerca de | `/acerca-de` | Versión, términos y condiciones, contacto |

### 4.9. Notificaciones

| Pantalla | Ruta | Descripción |
|---|---|---|
| Centro de Notificaciones | `/notificaciones` | Lista de notificaciones push/in-app |
| Detalle Notificación | `/notificaciones/:id` | Contenido completo de la notificación |

---

## 5. Endpoints API (Puerto 8004)

La App Clientes consumirá del Core Banking existente en `app_banco_core` (puerto 8003), más los siguientes endpoints adicionales:

### 5.1. Endpoints Existentes (Reutilizar)

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| POST | `/cliente/login` | No | Login con DNI + password → JWT |
| GET | `/cliente/perfil` | Bearer | Perfil del cliente autenticado |
| GET | `/cliente/cuentas` | Bearer | Cuentas de ahorro |
| GET | `/cliente/creditos` | Bearer | Créditos del cliente |
| GET | `/cliente/creditos/{cod}/cronograma` | Bearer | Cronograma de pagos |
| GET | `/cliente/movimientos?limit=20` | Bearer | Últimos movimientos |
| GET | `/cliente/tarjetas` | Bearer | Tarjetas del cliente |
| GET | `/cliente/notificaciones` | Bearer | Notificaciones del cliente |
| POST | `/cliente/operaciones` | Bearer | Registrar operación |

### 5.2. Endpoints Nuevos (Por Crear)

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| POST | `/cliente/recuperar-password` | No | Solicitar restablecimiento de contraseña |
| POST | `/cliente/restablecer-password` | No | Restablecer contraseña con token |
| PUT | `/cliente/perfil` | Bearer | Actualizar datos del perfil |
| PUT | `/cliente/cambiar-password` | Bearer | Cambiar contraseña (password actual + nueva) |
| POST | `/cliente/biometria/registrar` | Bearer | Registrar huella/Face ID |
| POST | `/cliente/pagos/cuota` | Bearer | Pagar cuota de crédito |
| POST | `/cliente/pagos/tercero` | Bearer | Transferencia a tercero |
| POST | `/cliente/recarga` | Bearer | Recarga móvil |
| POST | `/cliente/servicios/pagar` | Bearer | Pago de servicios |
| POST | `/cliente/tarjetas/{id}/bloquear` | Bearer | Bloquear tarjeta |
| GET | `/cliente/servicios/disponibles` | No | Lista de servicios disponibles para pago |
| POST | `/cliente/solicitar-credito` | Bearer | Enviar solicitud de nuevo crédito |

**Total:** 12 endpoints nuevos + 9 existentes = 21 endpoints para la App Clientes.

---

## 6. Modelos de Datos

### 6.1. Modelos Existentes (en BD `bd_fuerza_ventas`)

```sql
-- Tablas compartidas que la App Clientes consultará:

-- Cuentas de ahorro (replicadas del core)
CREATE TABLE cr_cuentas_ahorro (
    id UUID PK,
    cod_cuenta_ahorro VARCHAR(30) UNIQUE,
    cliente_id UUID FK → clientes.id,
    tipo_cuenta VARCHAR(40),
    moneda VARCHAR(3) DEFAULT 'PEN',
    saldo_capital NUMERIC(12,2),
    saldo_interes NUMERIC(12,2),
    tea NUMERIC(5,2),
    estado VARCHAR(20),
    sync_at TIMESTAMPTZ
);

-- Créditos (replicados del core)
CREATE TABLE cr_creditos (
    id UUID PK,
    cod_cuenta_credito VARCHAR(30) UNIQUE,
    cliente_id UUID FK → clientes.id,
    producto VARCHAR(40),
    monto_desembolsado NUMERIC(12,2),
    saldo_capital NUMERIC(12,2),
    saldo_total NUMERIC(12,2),
    dias_mora INTEGER DEFAULT 0,
    calificacion_interna VARCHAR(20),
    estado VARCHAR(20),
    fecha_desembolso DATE,
    tea NUMERIC(5,2),
    cuotas_total INTEGER,
    cuotas_pagadas INTEGER,
    sync_at TIMESTAMPTZ
);

-- Cronograma de pagos
CREATE TABLE cr_cronograma_pagos (
    id UUID PK,
    cod_cuenta_credito VARCHAR(30) FK → cr_creditos,
    nro_cuota INTEGER,
    fecha_vencimiento DATE,
    monto_cuota NUMERIC(10,2),
    monto_capital NUMERIC(10,2),
    monto_interes NUMERIC(10,2),
    saldo NUMERIC(12,2),
    estado_cuota VARCHAR(20),
    fecha_pago DATE,
    sync_at TIMESTAMPTZ,
    UNIQUE(cod_cuenta_credito, nro_cuota)
);

-- Movimientos
CREATE TABLE cr_movimientos (
    id UUID PK,
    cod_operacion VARCHAR(40) UNIQUE,
    cliente_id UUID FK → clientes.id,
    cod_cuenta VARCHAR(30),
    tipo VARCHAR(10),        -- DEB/CRE/TRF
    concepto VARCHAR(60),
    canal VARCHAR(20),
    monto NUMERIC(12,2),
    moneda VARCHAR(3) DEFAULT 'PEN',
    fecha_operacion TIMESTAMPTZ,
    sync_at TIMESTAMPTZ
);

-- Tarjetas
CREATE TABLE tarjetas (
    id UUID PK,
    cliente_id UUID FK → clientes.id,
    numero_enmascarado VARCHAR(25),
    marca VARCHAR(20),
    linea_credito NUMERIC(12,2),
    saldo_utilizado NUMERIC(12,2),
    fecha_corte DATE,
    fecha_pago DATE,
    estado VARCHAR(20) DEFAULT 'activa',
    created_at TIMESTAMPTZ
);

-- Clientes
CREATE TABLE clientes (
    id UUID PK,
    cod_cliente VARCHAR(20) UNIQUE,
    numero_documento VARCHAR(15) UNIQUE,
    tipo_documento VARCHAR(5) DEFAULT 'DNI',
    nombres VARCHAR(100),
    apellidos VARCHAR(100),
    fecha_nacimiento DATE,
    estado_civil VARCHAR(15),
    telefono VARCHAR(15),
    email VARCHAR(100),
    direccion TEXT,
    tipo_negocio VARCHAR(30),
    nombre_negocio VARCHAR(100),
    antiguedad_negocio_meses INTEGER,
    ingresos_estimados NUMERIC(12,2),
    lat NUMERIC(10,7),
    lng NUMERIC(10,7),
    calificacion_sbs VARCHAR(15),
    es_prospecto BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);

-- Notificaciones
CREATE TABLE notificaciones (
    id UUID PK,
    destinatario_tipo VARCHAR(10),  -- 'asesor' | 'cliente'
    asesor_id UUID FK,
    cliente_id UUID FK → clientes.id,
    titulo VARCHAR(120),
    cuerpo TEXT,
    tipo VARCHAR(40),
    data_json JSONB,
    leida BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ
);

-- Operaciones iniciadas por cliente
CREATE TABLE operaciones_cliente (
    id UUID PK,
    cliente_id UUID FK → clientes.id,
    cod_cuenta_origen VARCHAR(30),
    cod_cuenta_destino VARCHAR(30),
    tipo VARCHAR(20),           -- pago_cuota / transferencia / recarga
    monto NUMERIC(12,2),
    moneda VARCHAR(3) DEFAULT 'PEN',
    estado VARCHAR(20) DEFAULT 'pendiente',
    cod_operacion_core VARCHAR(40),
    created_at TIMESTAMPTZ
);
```

### 6.2. Modelos Nuevos (Sugeridos)

```sql
-- Sesiones biométricas
CREATE TABLE clientes_biometria (
    id UUID PK,
    cliente_id UUID FK → clientes.id,
    tipo VARCHAR(20),            -- 'huella' | 'face_id'
    credential_id TEXT,           -- ID de la biometría en el dispositivo
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ
);

-- PIN de seguridad para operaciones
CREATE TABLE clientes_pin (
    id UUID PK,
    cliente_id UUID FK → clientes.id UNIQUE,
    pin_hash TEXT NOT NULL,
    intentos_fallidos INTEGER DEFAULT 0,
    bloqueado BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMPTZ
);

-- Tokens de restablecimiento de contraseña
CREATE TABLE clientes_reset_token (
    id UUID PK,
    cliente_id UUID FK → clientes.id,
    token TEXT UNIQUE NOT NULL,
    expira_en TIMESTAMPTZ NOT NULL,
    usado BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ
);
```

---

## 7. Dependencias Técnicas

### pubspec.yaml

```yaml
name: app_confianza_clientes
description: "App Clientes - Banco Confianza (Banca Móvil)"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.3.5

  # Navegación
  go_router: ^14.8.1

  # Networking (API REST - reemplaza conexión directa a BD)
  dio: ^5.4.0
  pretty_dio_logger: ^1.3.1

  # Almacenamiento Local
  flutter_secure_storage: ^9.2.4
  shared_preferences: ^2.2.2

  # UI
  google_fonts: ^6.1.0
  fl_chart: ^0.68.0          # Gráficos
  shimmer: ^3.0.0            # Loading skeletons
  cached_network_image: ^3.3.1

  # Notificaciones
  firebase_core: ^3.12.1
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^17.2.2

  # Biometría
  local_auth: ^2.1.8         # Huella / Face ID

  # Utilidades
  intl: ^0.20.2              # Formato de moneda/fechas
  connectivity_plus: ^6.1.4  # Estado de red
  url_launcher: ^6.3.0       # Links externos
  uuid: ^4.5.1               # Generación de UUIDs
  package_info_plus: ^8.0.0  # Información de la app

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

---

## 8. Plan de Desarrollo

### Fase 1: Infraestructura y Base (Semanas 1-2)

| Tarea | Duración | Dependencias |
|---|---|---|
| Crear proyecto Flutter + estructura de carpetas | 1 día | — |
| Configurar tema, colores, tipografía | 1 día | — |
| Implementar capa de red (Dio + interceptors) | 2 días | — |
| Implementar almacenamiento seguro (tokens) | 1 día | — |
| Configurar navegación (go_router) | 1 día | — |
| Crear pantalla Splash + onboarding | 2 días | — |
| **Total Fase 1** | **8 días** | |

### Fase 2: Autenticación (Semanas 3-4)

| Tarea | Duración | Dependencias |
|---|---|---|
| Pantalla Login + validación | 2 días | Fase 1 |
| Integrar endpoint `/cliente/login` | 1 día | Capa de red |
| Manejo de sesión (JWT storage + refresh) | 2 días | — |
| Pantalla Recuperar Contraseña | 2 días | — |
| Registro biométrico (local_auth) | 2 días | Fase 1 |
| Configuración de PIN | 1 día | — |
| **Total Fase 2** | **10 días** | |

### Fase 3: Dashboard y Consulta de Productos (Semanas 5-6)

| Tarea | Duración | Dependencias |
|---|---|---|
| Home Dashboard (saldo consolidado) | 3 días | Fase 2 |
| Pantalla Cuentas + Detalle | 2 días | — |
| Pantalla Créditos + Detalle | 2 días | — |
| Cronograma de Pagos | 2 días | — |
| Pantalla Tarjetas | 1 día | — |
| Últimos Movimientos | 2 días | — |
| **Total Fase 3** | **12 días** | |

### Fase 4: Operaciones (Semanas 7-8)

| Tarea | Duración | Dependencias |
|---|---|---|
| Flujo de Pago de Cuota | 3 días | Fase 3 |
| Flujo de Transferencia a Terceros | 3 días | — |
| Flujo de Recarga Móvil | 2 días | — |
| Flujo de Pago de Servicios | 2 días | — |
| Pantalla Confirmación (PIN + token) | 2 días | Fase 2 |
| Historial de Operaciones | 2 días | — |
| **Total Fase 4** | **14 días** | |

### Fase 5: Perfil, Notificaciones y Ajustes (Semanas 9-10)

| Tarea | Duración | Dependencias |
|---|---|---|
| Pantalla Perfil + Editar | 2 días | Fase 2 |
| Cambio de Contraseña | 1 día | — |
| Centro de Notificaciones | 2 días | Fase 3 |
| Pantalla Configuración | 2 días | — |
| Acerca de | 1 día | — |
| **Total Fase 5** | **8 días** | |

### Fase 6: Pulido y Publicación (Semanas 11-12)

| Tarea | Duración | Dependencias |
|---|---|---|
| Pruebas de integración con Core Banking API | 3 días | Fases 1-5 |
| Pruebas de seguridad (OWASP top 10 mobile) | 2 días | — |
| Optimización de rendimiento | 2 días | — |
| Preparación store assets (iconos, screenshots) | 2 días | — |
| Publicación en Play Store / App Store | 3 días | — |
| **Total Fase 6** | **12 días** | |

### Estimación Total: **64 días hábiles (~3 meses)**

---

## 9. Seguridad

### Requisitos de Seguridad

1. **Autenticación:** JWT con expiración configurable (480 min por defecto)
2. **Almacenamiento:** Tokens en `flutter_secure_storage` (encrypted SharedPreferences en Android, Keychain en iOS)
3. **PIN de Operaciones:** PIN de 6 dígitos, hash con bcrypt, máximo 3 intentos fallidos
4. **Biometría:** Usar `local_auth` package, almacenar solo referencia biométrica
5. **Red:** TLS/HTTPS obligatorio en producción, certificate pinning recomendado
6. **Logout automático:** 5 minutos de inactividad, sesión expirada
7. **Ofuscación:** Habilitar `flutter build --obfuscate` en release
8. **Root/Jailbreak detection:** Usar package como `root_detector`

---

## 10. Comunicación con el Ecosistema

```
┌─────────────────────────────────────────────────────────────┐
│                    App Clientes (Flutter)                    │
│  Puerto: 8004 (emulada, realmente desde dispositivo móvil)   │
│  Conexión: API REST (Dio) → Backend Core :8003              │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTPS (REST API)
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                 Backend Core (FastAPI :8003)                  │
│  - /cliente/* (login, cuentas, créditos, pagos, etc.)        │
│  - /auth/* (para asesores, no usado por clientes)            │
└──────────────────────┬──────────────────────────────────────┘
                       │ SQLAlchemy
                       ▼
┌─────────────────────────────────────────────────────────────┐
│           PostgreSQL :5432 / bd_fuerza_ventas                │
│  Tablas compartidas: clientes, cr_creditos, cr_cuentas_ahorro│
│  cr_cronograma_pagos, cr_movimientos, tarjetas,             │
│  notificaciones, operaciones_cliente, sync_outbox           │
└─────────────────────────────────────────────────────────────┘
```

A diferencia de la App Fuerza de Ventas (que se conecta DIRECTAMENTE a PostgreSQL), la **App Clientes se conectará vía API REST** al Backend Core, siguiendo el patrón estándar de seguridad móvil.

---

## 11. Referencias

- **API Docs (Swagger)**: http://localhost:8003/docs
- **Endpoints existentes para cliente**: Prefijo `/cliente/*` en `backend_core/app/routes/rtr_cliente.py`
- **Modelos de datos**: `backend_core/app/models/mdl_cliente_mobile.py`
- **App Fuerza de Ventas (referencia)**: `app_cofianza_fuerzaventas_v1/` — misma tecnología Flutter, Riverpod, go_router
- **Base de datos compartida**: `bd_fuerza_ventas` con tablas `cr_*` (replicadas del core financiero)
