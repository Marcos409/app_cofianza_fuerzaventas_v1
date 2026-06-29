-- =============================================================
-- PostgreSQL Migration: Schema
-- App: Fuerza Ventas - Confianza
-- Desc: All tables migrated from SQLite (sqflite) to PostgreSQL
-- =============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================
-- 1. CARTERA
-- =============================================================
CREATE TABLE IF NOT EXISTS cartera (
    id              TEXT PRIMARY KEY,
    asesor_id       TEXT NOT NULL,
    cliente_id      TEXT NOT NULL,
    agencia_id      TEXT,
    fecha_asignacion TIMESTAMPTZ NOT NULL,
    tipo_gestion    TEXT NOT NULL,
    prioridad       TEXT DEFAULT 'normal',
    score_prioridad INTEGER DEFAULT 0,
    estado_visita   TEXT DEFAULT 'pendiente',
    resultado_visita TEXT,
    observacion_visita TEXT,
    timestamp_visita TIMESTAMPTZ,
    lat_visita      DOUBLE PRECISION,
    lng_visita      DOUBLE PRECISION,
    orden_manual    INTEGER DEFAULT 0,
    pendiente_sync  BOOLEAN DEFAULT FALSE,
    nombre_cliente  TEXT NOT NULL,
    documento_cliente TEXT NOT NULL,
    direccion_cliente TEXT NOT NULL,
    telefono_cliente TEXT,
    monto_credito   NUMERIC(15,2)
);

CREATE INDEX IF NOT EXISTS idx_cartera_asesor ON cartera(asesor_id);
CREATE INDEX IF NOT EXISTS idx_cartera_cliente ON cartera(cliente_id);
CREATE INDEX IF NOT EXISTS idx_cartera_estado ON cartera(estado_visita);
CREATE INDEX IF NOT EXISTS idx_cartera_pendiente_sync ON cartera(pendiente_sync) WHERE pendiente_sync = TRUE;

-- =============================================================
-- 2. VISITAS_PENDIENTES
-- =============================================================
CREATE TABLE IF NOT EXISTS visitas_pendientes (
    id              TEXT PRIMARY KEY,
    cartero_id      TEXT,
    resultado       TEXT,
    observacion     TEXT,
    timestamp_visita TIMESTAMPTZ,
    lat             DOUBLE PRECISION,
    lng             DOUBLE PRECISION,
    pendiente_sync  BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_visitas_pendientes_sync ON visitas_pendientes(pendiente_sync) WHERE pendiente_sync = TRUE;

-- =============================================================
-- 3. SOLICITUDES
-- =============================================================
CREATE TABLE IF NOT EXISTS solicitudes (
    id              TEXT PRIMARY KEY,
    cliente_id      TEXT NOT NULL,
    tipo_credito    TEXT NOT NULL,
    monto_solicitado NUMERIC(15,2) NOT NULL,
    plazo_meses     INTEGER NOT NULL,
    estado          TEXT NOT NULL DEFAULT 'borrador',
    datos_json      JSONB,
    pendiente_sync  BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_solicitudes_cliente ON solicitudes(cliente_id);
CREATE INDEX IF NOT EXISTS idx_solicitudes_estado ON solicitudes(estado);
CREATE INDEX IF NOT EXISTS idx_solicitudes_sync ON solicitudes(pendiente_sync) WHERE pendiente_sync = TRUE;

-- =============================================================
-- 4. DOCUMENTOS (legacy, superseded by solicitudes_documentos)
-- =============================================================
CREATE TABLE IF NOT EXISTS documentos (
    id              TEXT PRIMARY KEY,
    solicitud_id    TEXT NOT NULL,
    tipo_documento  TEXT NOT NULL,
    ruta_archivo    TEXT,
    pendiente_sync  BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documentos_solicitud ON documentos(solicitud_id);

-- =============================================================
-- 5. SYNC_QUEUE
-- =============================================================
CREATE TABLE IF NOT EXISTS sync_queue (
    id              SERIAL PRIMARY KEY,
    tabla           TEXT NOT NULL,
    registro_id     TEXT NOT NULL,
    operacion       TEXT NOT NULL,
    payload         JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sync_queue_tabla ON sync_queue(tabla);
CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON sync_queue(created_at);

-- =============================================================
-- 6. FICHA_CACHE
-- =============================================================
CREATE TABLE IF NOT EXISTS ficha_cache (
    cliente_id      TEXT PRIMARY KEY,
    nombre          TEXT NOT NULL,
    documento       TEXT NOT NULL,
    direccion       TEXT NOT NULL,
    telefono        TEXT,
    email           TEXT,
    tipo_negocio    TEXT,
    antiguedad_negocio INTEGER,
    lat             DOUBLE PRECISION,
    lng             DOUBLE PRECISION,
    calificacion_sbs TEXT DEFAULT 'normal',
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- 7. CREDITOS_CACHE
-- =============================================================
CREATE TABLE IF NOT EXISTS creditos_cache (
    cliente_id      TEXT NOT NULL,
    credito_id      TEXT NOT NULL,
    monto           NUMERIC(15,2) NOT NULL,
    plazo_meses     INTEGER NOT NULL,
    tea             NUMERIC(5,2) NOT NULL,
    estado          TEXT NOT NULL,
    porcentaje_puntual NUMERIC(5,2) DEFAULT 100,
    fecha_apertura  TIMESTAMPTZ,
    fecha_cierre    TIMESTAMPTZ,
    PRIMARY KEY (cliente_id, credito_id)
);

CREATE INDEX IF NOT EXISTS idx_creditos_cache_cliente ON creditos_cache(cliente_id);

-- =============================================================
-- 8. PAGOS_CACHE
-- =============================================================
CREATE TABLE IF NOT EXISTS pagos_cache (
    cliente_id      TEXT NOT NULL,
    mes             INTEGER NOT NULL,
    anio            INTEGER NOT NULL,
    monto_pagado    NUMERIC(15,2) NOT NULL,
    status          TEXT NOT NULL,
    PRIMARY KEY (cliente_id, anio, mes)
);

CREATE INDEX IF NOT EXISTS idx_pagos_cache_cliente ON pagos_cache(cliente_id);

-- =============================================================
-- 9. OFERTAS_CACHE
-- =============================================================
CREATE TABLE IF NOT EXISTS ofertas_cache (
    cliente_id          TEXT PRIMARY KEY,
    oferta_id           TEXT NOT NULL,
    monto_maximo        NUMERIC(15,2) NOT NULL,
    plazo_sugerido_meses INTEGER NOT NULL,
    tea_referencial     NUMERIC(5,2) NOT NULL,
    score_confianza     INTEGER NOT NULL,
    vigente             BOOLEAN DEFAULT TRUE,
    fecha_vencimiento   TIMESTAMPTZ NOT NULL
);

-- =============================================================
-- 10. PRE_EVALUACIONES_PENDIENTES
-- =============================================================
CREATE TABLE IF NOT EXISTS pre_evaluaciones_pendientes (
    id              TEXT PRIMARY KEY,
    asesor_id       TEXT,
    datos_json      JSONB NOT NULL,
    pendiente_sync  BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pre_eval_sync ON pre_evaluaciones_pendientes(pendiente_sync) WHERE pendiente_sync = TRUE;

-- =============================================================
-- 11. CAMPANAS_CACHE
-- =============================================================
CREATE TABLE IF NOT EXISTS campanas_cache (
    id              TEXT PRIMARY KEY,
    cliente_id      TEXT NOT NULL,
    nombre_cliente  TEXT NOT NULL,
    tipo            TEXT NOT NULL,
    monto_ofertado  NUMERIC(15,2) NOT NULL,
    fecha_vencimiento TIMESTAMPTZ NOT NULL,
    activa          BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_campanas_cliente ON campanas_cache(cliente_id);

-- =============================================================
-- 12. SOLICITUDES_BORRADOR
-- =============================================================
CREATE TABLE IF NOT EXISTS solicitudes_borrador (
    id              TEXT PRIMARY KEY,
    cliente_id      TEXT,
    cliente_nombre  TEXT,
    paso_actual     INTEGER DEFAULT 0,
    datos_json      JSONB,
    monto_solicitado NUMERIC(15,2) DEFAULT 0,
    asesor_id       TEXT,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- 13. SOLICITUDES_ENVIADAS
-- =============================================================
CREATE TABLE IF NOT EXISTS solicitudes_enviadas (
    id              TEXT PRIMARY KEY,
    asesor_id       TEXT NOT NULL,
    datos_json      JSONB,
    estado          TEXT DEFAULT 'enviado',
    pendiente_sync  BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_solicitudes_enviadas_asesor ON solicitudes_enviadas(asesor_id);
CREATE INDEX IF NOT EXISTS idx_solicitudes_enviadas_estado ON solicitudes_enviadas(estado);
CREATE INDEX IF NOT EXISTS idx_solicitudes_enviadas_sync ON solicitudes_enviadas(pendiente_sync) WHERE pendiente_sync = TRUE;

-- =============================================================
-- 14. SOLICITUDES_DOCUMENTOS
-- =============================================================
CREATE TABLE IF NOT EXISTS solicitudes_documentos (
    id              TEXT PRIMARY KEY,
    solicitud_id    TEXT NOT NULL,
    tipo_documento  TEXT NOT NULL,
    estado          TEXT DEFAULT 'pendiente',
    storage_url     TEXT,
    tamanio_kb      INTEGER,
    nitidez_score   NUMERIC(4,2),
    local_path      TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_solicitudes_docs_solicitud ON solicitudes_documentos(solicitud_id);

-- =============================================================
-- 15. CONSULTAS_BURO
-- =============================================================
CREATE TABLE IF NOT EXISTS consultas_buro (
    id              TEXT PRIMARY KEY,
    asesor_id       TEXT NOT NULL,
    cliente_id      TEXT NOT NULL,
    dni_consultado  TEXT NOT NULL,
    calificacion_sbs TEXT,
    entidades_con_deuda INTEGER DEFAULT 0,
    deuda_total_pen NUMERIC(15,2) DEFAULT 0,
    mayor_deuda     NUMERIC(15,2) DEFAULT 0,
    dias_mayor_mora INTEGER DEFAULT 0,
    resultado_json  JSONB,
    en_lista_negra  BOOLEAN DEFAULT FALSE,
    motivo_bloqueo  TEXT,
    firma_consentimiento_base64 TEXT,
    solicitud_id    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_consultas_buro_asesor ON consultas_buro(asesor_id);
CREATE INDEX IF NOT EXISTS idx_consultas_buro_cliente ON consultas_buro(cliente_id);
CREATE INDEX IF NOT EXISTS idx_consultas_buro_dni ON consultas_buro(dni_consultado);

-- =============================================================
-- 16. TRANSMISION_ESTADO
-- =============================================================
CREATE TABLE IF NOT EXISTS transmision_estado (
    solicitud_id    TEXT PRIMARY KEY,
    paso_completado INTEGER DEFAULT 0,
    documentos_subidos TEXT,
    expediente_generado TEXT,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- 17. SOLICITUDES_NOTAS_INTERNAS
-- =============================================================
CREATE TABLE IF NOT EXISTS solicitudes_notas_internas (
    id              TEXT PRIMARY KEY,
    solicitud_id    TEXT NOT NULL,
    asesor_id       TEXT NOT NULL,
    contenido       TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notas_solicitud ON solicitudes_notas_internas(solicitud_id);

-- =============================================================
-- 18. ACCIONES_COBRANZA_PENDIENTES
-- =============================================================
CREATE TABLE IF NOT EXISTS acciones_cobranza_pendientes (
    id              TEXT PRIMARY KEY,
    asesor_id       TEXT NOT NULL,
    cliente_id      TEXT NOT NULL,
    credito_id      TEXT NOT NULL,
    tipo_gestion    TEXT NOT NULL,
    resultado       TEXT NOT NULL,
    monto_pagado    NUMERIC(15,2),
    fecha_compromiso TIMESTAMPTZ,
    monto_compromiso NUMERIC(15,2),
    observaciones   TEXT,
    lat             DOUBLE PRECISION,
    lng             DOUBLE PRECISION,
    timestamp_gestion TIMESTAMPTZ NOT NULL,
    pendiente_sync  BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_cobranza_asesor ON acciones_cobranza_pendientes(asesor_id);
CREATE INDEX IF NOT EXISTS idx_cobranza_cliente ON acciones_cobranza_pendientes(cliente_id);
CREATE INDEX IF NOT EXISTS idx_cobranza_sync ON acciones_cobranza_pendientes(pendiente_sync) WHERE pendiente_sync = TRUE;

-- =============================================================
-- 19. POSICION_CACHE
-- =============================================================
CREATE TABLE IF NOT EXISTS posicion_cache (
    cliente_id      TEXT PRIMARY KEY,
    deuda_total     NUMERIC(15,2) NOT NULL DEFAULT 0,
    cuentas_vigentes INTEGER NOT NULL DEFAULT 0,
    cuentas_mora    INTEGER NOT NULL DEFAULT 0,
    dias_mayor_mora INTEGER NOT NULL DEFAULT 0,
    ultimo_pago     TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- 20. CARTERA_VENCIDA_CACHE
-- =============================================================
CREATE TABLE IF NOT EXISTS cartera_vencida_cache (
    id              TEXT PRIMARY KEY,
    cliente_id      TEXT NOT NULL,
    credito_id      TEXT NOT NULL,
    nombre_cliente  TEXT NOT NULL,
    documento_cliente TEXT NOT NULL,
    telefono        TEXT,
    direccion       TEXT,
    dias_mora       INTEGER NOT NULL DEFAULT 0,
    monto_vencido   NUMERIC(15,2) NOT NULL DEFAULT 0,
    saldo_actual    NUMERIC(15,2) NOT NULL DEFAULT 0,
    ultimo_contacto TIMESTAMPTZ,
    cuotas_pagadas  INTEGER,
    total_cuotas    INTEGER,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cartera_vencida_cliente ON cartera_vencida_cache(cliente_id);
CREATE INDEX IF NOT EXISTS idx_cartera_vencida_dias ON cartera_vencida_cache(dias_mora);

-- =============================================================
-- 21. USUARIOS
-- =============================================================
CREATE TABLE IF NOT EXISTS usuarios (
    id              TEXT PRIMARY KEY,
    codigo_empleado TEXT NOT NULL UNIQUE,
    nombres         TEXT NOT NULL,
    apellidos       TEXT NOT NULL,
    email           TEXT,
    telefono        TEXT,
    password_hash   TEXT NOT NULL,
    rol             TEXT NOT NULL DEFAULT 'operador',
    agencia_id      TEXT,
    activo          BOOLEAN DEFAULT TRUE,
    creado_por      TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios(rol);
CREATE INDEX IF NOT EXISTS idx_usuarios_agencia ON usuarios(agencia_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_activo ON usuarios(activo) WHERE activo = TRUE;

-- =============================================================
-- 22. AUDITORIA_USUARIOS
-- =============================================================
CREATE TABLE IF NOT EXISTS auditoria_usuarios (
    id              TEXT PRIMARY KEY,
    usuario_id      TEXT NOT NULL,
    accion          TEXT NOT NULL,
    detalle         TEXT,
    realizado_por   TEXT NOT NULL,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_auditoria_usuario ON auditoria_usuarios(usuario_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_accion ON auditoria_usuarios(accion);
CREATE INDEX IF NOT EXISTS idx_auditoria_creado ON auditoria_usuarios(creado_en);

-- =============================================================
-- Table missing in SQLite schema (referenced in code):
-- deserciones_pendientes (used in prospeccion_repository.dart)
-- =============================================================
CREATE TABLE IF NOT EXISTS deserciones_pendientes (
    id              TEXT PRIMARY KEY,
    asesor_id       TEXT,
    cliente_id      TEXT NOT NULL,
    tipo            TEXT NOT NULL,
    datos_json      JSONB,
    pendiente_sync  BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_deserciones_sync ON deserciones_pendientes(pendiente_sync) WHERE pendiente_sync = TRUE;
