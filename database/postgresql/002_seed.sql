-- =============================================================
-- PostgreSQL Migration: Seed Data
-- App: Fuerza Ventas - Confianza
-- Desc: Seed data for development/testing (all 22 tables)
-- =============================================================

-- =============================================================
-- Helper: Seed only if table is empty
-- =============================================================
DO $$
BEGIN
    -- ─────────── USUARIOS ───────────
    IF NOT EXISTS (SELECT 1 FROM usuarios LIMIT 1) THEN
        INSERT INTO usuarios (id, codigo_empleado, nombres, apellidos, email, telefono, password_hash, rol, agencia_id, activo, creado_por, creado_en, actualizado_en) VALUES
            (gen_random_uuid()::text, '123456', 'Carlos', 'García López', 'carlos.garcia@example.com', '999000123', '123456', 'operador', 'AG001', TRUE, 'seed', NOW(), NOW()),
            (gen_random_uuid()::text, '654321', 'María', 'Fernández Rojas', 'maria.fernandez@example.com', '999000456', '654321', 'supervisor', 'AG001', TRUE, 'seed', NOW(), NOW()),
            (gen_random_uuid()::text, '111111', 'Admin', 'Sistema', 'admin@confianza.com', '999000789', '111111', 'administrador', 'AG001', TRUE, 'seed', NOW(), NOW()),
            (gen_random_uuid()::text, '222222', 'Super', 'Operador Test', 'super.operador@example.com', '999000012', '222222', 'super_operador', 'AG001', TRUE, 'seed', NOW(), NOW());
    END IF;

    -- ─────────── CARTERA ───────────
    IF NOT EXISTS (SELECT 1 FROM cartera LIMIT 1) THEN
        INSERT INTO cartera (id, asesor_id, cliente_id, agencia_id, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita, resultado_visita, observacion_visita, timestamp_visita, lat_visita, lng_visita, orden_manual, pendiente_sync, nombre_cliente, documento_cliente, direccion_cliente, telefono_cliente, monto_credito) VALUES
            (gen_random_uuid()::text, '123456', 'c_001', 'AG001', NOW() - INTERVAL '3 days', 'RENOVACION', 'normal', 5, 'pendiente', NULL, NULL, NULL, NULL, NULL, 0, FALSE, 'María López Torres', '12345678', 'Av. Los Olivos 123, San Martín', '999000111', 2000),
            (gen_random_uuid()::text, '123456', 'c_002', 'AG001', NOW() - INTERVAL '3 days', 'SEGUIMIENTO', 'normal', 10, 'pendiente', NULL, NULL, NULL, NULL, NULL, 0, FALSE, 'Juan Pérez García', '23456789', 'Jr. Las Flores 456, Breña', '999000222', 3500),
            (gen_random_uuid()::text, '123456', 'c_003', 'AG001', NOW() - INTERVAL '3 days', 'RECUPERACION_MORA', 'alta', 85, 'pendiente', NULL, NULL, NULL, NULL, NULL, 0, FALSE, 'Rosa Mamani Condori', '34567890', 'Calle Real 789, Huancayo', '999000333', 5000),
            (gen_random_uuid()::text, '123456', 'c_004', 'AG001', NOW() - INTERVAL '3 days', 'NUEVA_SOLICITUD', 'normal', 5, 'pendiente', NULL, NULL, NULL, NULL, NULL, 0, FALSE, 'Carlos Huamán Ríos', '45678901', 'Av. Arequipa 321, Lince', '999000444', 1500),
            (gen_random_uuid()::text, '123456', 'c_005', 'AG001', NOW() - INTERVAL '3 days', 'DESERTOR', 'normal', 25, 'pendiente', NULL, NULL, NULL, NULL, NULL, 0, FALSE, 'Lucía Quispe Flores', '56789012', 'Jr. Unión 654, Cercado', '999000555', 800),
            (gen_random_uuid()::text, '123456', 'c_006', 'AG001', NOW() - INTERVAL '3 days', 'AMPLIACION', 'normal', 20, 'pendiente', NULL, NULL, NULL, NULL, NULL, 0, FALSE, 'Pedro Castillo Sánchez', '67890123', 'Av. Grau 987, Barranco', '999000666', 4000),
            (gen_random_uuid()::text, '123456', 'c_007', 'AG001', NOW() - INTERVAL '3 days', 'RECUPERACION_MORA', 'media', 65, 'pendiente', NULL, NULL, NULL, NULL, NULL, 0, FALSE, 'Ana Gutiérrez Paredes', '78901234', 'Calle Los Pinos 147, Miraflores', '999000777', 2800),
            (gen_random_uuid()::text, '123456', 'c_008', 'AG001', NOW() - INTERVAL '3 days', 'RENOVACION', 'normal', 15, 'pendiente', NULL, NULL, NULL, NULL, NULL, 0, FALSE, 'José Ramos Huerta', '89012345', 'Av. Primavera 258, Surco', '999000888', 6000),
            (gen_random_uuid()::text, '123456', 'c_009', 'AG001', NOW() - INTERVAL '3 days', 'RECUPERACION_MORA', 'alta', 75, 'pendiente', NULL, NULL, NULL, NULL, NULL, 0, FALSE, 'Elena Vargas Ruiz', '90123456', 'Jr. Amazonas 369, Magdalena', '999000999', 4200),
            (gen_random_uuid()::text, '123456', 'c_010', 'AG001', NOW() - INTERVAL '3 days', 'SEGUIMIENTO', 'normal', 30, 'pendiente', NULL, NULL, NULL, NULL, NULL, 0, FALSE, 'Miguel Pizarro Díaz', '10123456', 'Av. Central 741, San Juan de Lurigancho', '999000000', 1800);
    END IF;

    -- ─────────── FICHA_CACHE ───────────
    IF NOT EXISTS (SELECT 1 FROM ficha_cache LIMIT 1) THEN
        INSERT INTO ficha_cache (cliente_id, nombre, documento, direccion, telefono, email, tipo_negocio, antiguedad_negocio, lat, lng, calificacion_sbs, updated_at) VALUES
            ('c_001', 'María López Torres', '12345678', 'Av. Los Olivos 123, San Martín', '999000111', 'maria.lopez@email.com', 'Bodega', 8, -12.0453, -77.0324, 'normal', NOW()),
            ('c_002', 'Juan Pérez García', '23456789', 'Jr. Las Flores 456, Breña', '999000222', 'juan.perez@email.com', 'Ferretería', 5, -12.0521, -77.0456, 'cpp', NOW()),
            ('c_003', 'Rosa Mamani Condori', '34567890', 'Calle Real 789, Huancayo', '999000333', 'rosa.mamani@email.com', 'Restaurante', 12, -12.0654, -77.0289, 'deficiente', NOW()),
            ('c_004', 'Carlos Huamán Ríos', '45678901', 'Av. Arequipa 321, Lince', '999000444', 'carlos.huaman@email.com', 'Transporte', 3, -12.0756, -77.0398, 'normal', NOW()),
            ('c_005', 'Lucía Quispe Flores', '56789012', 'Jr. Unión 654, Cercado', '999000555', 'lucia.quispe@email.com', 'Peluquería', 2, -12.0389, -77.0512, 'normal', NOW()),
            ('c_006', 'Pedro Castillo Sánchez', '67890123', 'Av. Grau 987, Barranco', '999000666', 'pedro.castillo@email.com', 'Carpintería', 7, -12.0821, -77.0345, 'cpp', NOW()),
            ('c_007', 'Ana Gutiérrez Paredes', '78901234', 'Calle Los Pinos 147, Miraflores', '999000777', 'ana.gutierrez@email.com', 'Tienda de ropa', 4, -12.0912, -77.0489, 'dudoso', NOW()),
            ('c_008', 'José Ramos Huerta', '89012345', 'Av. Primavera 258, Surco', '999000888', 'jose.ramos@email.com', 'Farmacia', 10, -12.1034, -77.0256, 'normal', NOW()),
            ('c_009', 'Elena Vargas Ruiz', '90123456', 'Jr. Amazonas 369, Magdalena', '999000999', 'elena.vargas@email.com', 'Hospedaje', 6, -12.0587, -77.0678, 'deficiente', NOW()),
            ('c_010', 'Miguel Pizarro Díaz', '10123456', 'Av. Central 741, SJL', '999000000', 'miguel.pizarro@email.com', 'Transporte', 9, -12.0712, -77.0123, 'normal', NOW());
    END IF;

    -- ─────────── CREDITOS_CACHE ───────────
    IF NOT EXISTS (SELECT 1 FROM creditos_cache LIMIT 1) THEN
        INSERT INTO creditos_cache (cliente_id, credito_id, monto, plazo_meses, tea, estado, porcentaje_puntual, fecha_apertura, fecha_cierre) VALUES
            ('c_001', 'CR001', 2000, 12, 32.5, 'pagado', 100, NOW() - INTERVAL '400 days', NOW() - INTERVAL '40 days'),
            ('c_001', 'CR002', 2500, 18, 30.0, 'vigente', 95, NOW() - INTERVAL '100 days', NULL),
            ('c_002', 'CR003', 3000, 12, 35.0, 'vigente', 70, NOW() - INTERVAL '180 days', NULL),
            ('c_003', 'CR004', 5000, 24, 38.0, 'vigente', 40, NOW() - INTERVAL '300 days', NULL),
            ('c_003', 'CR005', 2000, 12, 36.0, 'pagado', 60, NOW() - INTERVAL '600 days', NOW() - INTERVAL '200 days'),
            ('c_004', 'CR006', 1500, 12, 28.0, 'pagado', 100, NOW() - INTERVAL '500 days', NOW() - INTERVAL '50 days'),
            ('c_005', 'CR007', 800, 6, 30.0, 'pagado', 100, NOW() - INTERVAL '300 days', NOW() - INTERVAL '90 days'),
            ('c_006', 'CR008', 4000, 18, 33.0, 'vigente', 80, NOW() - INTERVAL '200 days', NULL),
            ('c_007', 'CR009', 2800, 12, 36.0, 'vigente', 50, NOW() - INTERVAL '250 days', NULL),
            ('c_007', 'CR010', 1500, 12, 34.0, 'pagado', 75, NOW() - INTERVAL '550 days', NOW() - INTERVAL '150 days'),
            ('c_008', 'CR011', 6000, 24, 29.0, 'vigente', 100, NOW() - INTERVAL '120 days', NULL),
            ('c_008', 'CR012', 3000, 12, 31.0, 'pagado', 100, NOW() - INTERVAL '450 days', NOW() - INTERVAL '30 days'),
            ('c_009', 'CR013', 4200, 18, 37.0, 'vigente', 30, NOW() - INTERVAL '280 days', NULL),
            ('c_010', 'CR014', 1800, 12, 32.0, 'pagado', 90, NOW() - INTERVAL '350 days', NOW() - INTERVAL '60 days');
    END IF;

    -- ─────────── PAGOS_CACHE ───────────
    IF NOT EXISTS (SELECT 1 FROM pagos_cache LIMIT 1) THEN
        INSERT INTO pagos_cache (cliente_id, mes, anio, monto_pagado, status) VALUES
            -- c_001 (PUNTUAL)
            ('c_001', 6, 2025, 260, 'PUNTUAL'), ('c_001', 7, 2025, 270, 'PUNTUAL'),
            ('c_001', 8, 2025, 280, 'PUNTUAL'), ('c_001', 9, 2025, 260, 'PUNTUAL'),
            ('c_001', 10, 2025, 270, 'PUNTUAL'), ('c_001', 11, 2025, 280, 'PUNTUAL'),
            ('c_001', 12, 2025, 260, 'PUNTUAL'), ('c_001', 1, 2026, 270, 'PUNTUAL'),
            ('c_001', 2, 2026, 280, 'PUNTUAL'), ('c_001', 3, 2026, 260, 'PUNTUAL'),
            ('c_001', 4, 2026, 270, 'PUNTUAL'), ('c_001', 5, 2026, 280, 'PUNTUAL'),
            -- c_002 (PUNTUAL 8, MORA 4)
            ('c_002', 6, 2025, 280, 'PUNTUAL'), ('c_002', 7, 2025, 280, 'PUNTUAL'),
            ('c_002', 8, 2025, 280, 'PUNTUAL'), ('c_002', 9, 2025, 280, 'PUNTUAL'),
            ('c_002', 10, 2025, 280, 'PUNTUAL'), ('c_002', 11, 2025, 280, 'PUNTUAL'),
            ('c_002', 12, 2025, 280, 'PUNTUAL'), ('c_002', 1, 2026, 280, 'PUNTUAL'),
            ('c_002', 2, 2026, 180, 'MORA'), ('c_002', 3, 2026, 180, 'MORA'),
            ('c_002', 4, 2026, 180, 'MORA'), ('c_002', 5, 2026, 180, 'MORA'),
            -- c_003 (PUNTUAL 5, MORA 7)
            ('c_003', 6, 2025, 350, 'PUNTUAL'), ('c_003', 7, 2025, 350, 'PUNTUAL'),
            ('c_003', 8, 2025, 350, 'PUNTUAL'), ('c_003', 9, 2025, 350, 'PUNTUAL'),
            ('c_003', 10, 2025, 350, 'PUNTUAL'),
            ('c_003', 11, 2025, 200, 'MORA'), ('c_003', 12, 2025, 200, 'MORA'),
            ('c_003', 1, 2026, 200, 'MORA'), ('c_003', 2, 2026, 200, 'MORA'),
            ('c_003', 3, 2026, 200, 'MORA'), ('c_003', 4, 2026, 200, 'MORA'),
            ('c_003', 5, 2026, 200, 'MORA'),
            -- c_004 (PUNTUAL)
            ('c_004', 6, 2025, 260, 'PUNTUAL'), ('c_004', 7, 2025, 270, 'PUNTUAL'),
            ('c_004', 8, 2025, 280, 'PUNTUAL'), ('c_004', 9, 2025, 260, 'PUNTUAL'),
            ('c_004', 10, 2025, 270, 'PUNTUAL'), ('c_004', 11, 2025, 280, 'PUNTUAL'),
            ('c_004', 12, 2025, 260, 'PUNTUAL'), ('c_004', 1, 2026, 270, 'PUNTUAL'),
            ('c_004', 2, 2026, 280, 'PUNTUAL'), ('c_004', 3, 2026, 260, 'PUNTUAL'),
            ('c_004', 4, 2026, 270, 'PUNTUAL'), ('c_004', 5, 2026, 280, 'PUNTUAL'),
            -- c_005 (PUNTUAL)
            ('c_005', 6, 2025, 150, 'PUNTUAL'), ('c_005', 7, 2025, 150, 'PUNTUAL'),
            ('c_005', 8, 2025, 150, 'PUNTUAL'), ('c_005', 9, 2025, 150, 'PUNTUAL'),
            ('c_005', 10, 2025, 150, 'PUNTUAL'), ('c_005', 11, 2025, 150, 'PUNTUAL'),
            ('c_005', 12, 2025, 150, 'PUNTUAL'), ('c_005', 1, 2026, 150, 'PUNTUAL'),
            ('c_005', 2, 2026, 150, 'PUNTUAL'), ('c_005', 3, 2026, 150, 'PUNTUAL'),
            ('c_005', 4, 2026, 150, 'PUNTUAL'), ('c_005', 5, 2026, 150, 'PUNTUAL'),
            -- c_006 (PUNTUAL 8, MORA 4)
            ('c_006', 6, 2025, 280, 'PUNTUAL'), ('c_006', 7, 2025, 280, 'PUNTUAL'),
            ('c_006', 8, 2025, 280, 'PUNTUAL'), ('c_006', 9, 2025, 280, 'PUNTUAL'),
            ('c_006', 10, 2025, 280, 'PUNTUAL'), ('c_006', 11, 2025, 280, 'PUNTUAL'),
            ('c_006', 12, 2025, 280, 'PUNTUAL'), ('c_006', 1, 2026, 280, 'PUNTUAL'),
            ('c_006', 2, 2026, 180, 'MORA'), ('c_006', 3, 2026, 180, 'MORA'),
            ('c_006', 4, 2026, 180, 'MORA'), ('c_006', 5, 2026, 180, 'MORA'),
            -- c_007 (PUNTUAL 3, MORA 9)
            ('c_007', 6, 2025, 300, 'PUNTUAL'), ('c_007', 7, 2025, 300, 'PUNTUAL'),
            ('c_007', 8, 2025, 300, 'PUNTUAL'),
            ('c_007', 9, 2025, 150, 'MORA'), ('c_007', 10, 2025, 150, 'MORA'),
            ('c_007', 11, 2025, 150, 'MORA'), ('c_007', 12, 2025, 150, 'MORA'),
            ('c_007', 1, 2026, 150, 'MORA'), ('c_007', 2, 2026, 150, 'MORA'),
            ('c_007', 3, 2026, 150, 'MORA'), ('c_007', 4, 2026, 150, 'MORA'),
            ('c_007', 5, 2026, 150, 'MORA'),
            -- c_008 (PUNTUAL)
            ('c_008', 6, 2025, 260, 'PUNTUAL'), ('c_008', 7, 2025, 270, 'PUNTUAL'),
            ('c_008', 8, 2025, 280, 'PUNTUAL'), ('c_008', 9, 2025, 260, 'PUNTUAL'),
            ('c_008', 10, 2025, 270, 'PUNTUAL'), ('c_008', 11, 2025, 280, 'PUNTUAL'),
            ('c_008', 12, 2025, 260, 'PUNTUAL'), ('c_008', 1, 2026, 270, 'PUNTUAL'),
            ('c_008', 2, 2026, 280, 'PUNTUAL'), ('c_008', 3, 2026, 260, 'PUNTUAL'),
            ('c_008', 4, 2026, 270, 'PUNTUAL'), ('c_008', 5, 2026, 280, 'PUNTUAL'),
            -- c_009 (PUNTUAL 5, MORA 7)
            ('c_009', 6, 2025, 350, 'PUNTUAL'), ('c_009', 7, 2025, 350, 'PUNTUAL'),
            ('c_009', 8, 2025, 350, 'PUNTUAL'), ('c_009', 9, 2025, 350, 'PUNTUAL'),
            ('c_009', 10, 2025, 350, 'PUNTUAL'),
            ('c_009', 11, 2025, 200, 'MORA'), ('c_009', 12, 2025, 200, 'MORA'),
            ('c_009', 1, 2026, 200, 'MORA'), ('c_009', 2, 2026, 200, 'MORA'),
            ('c_009', 3, 2026, 200, 'MORA'), ('c_009', 4, 2026, 200, 'MORA'),
            ('c_009', 5, 2026, 200, 'MORA'),
            -- c_010 (PUNTUAL)
            ('c_010', 6, 2025, 260, 'PUNTUAL'), ('c_010', 7, 2025, 270, 'PUNTUAL'),
            ('c_010', 8, 2025, 280, 'PUNTUAL'), ('c_010', 9, 2025, 260, 'PUNTUAL'),
            ('c_010', 10, 2025, 270, 'PUNTUAL'), ('c_010', 11, 2025, 280, 'PUNTUAL'),
            ('c_010', 12, 2025, 260, 'PUNTUAL'), ('c_010', 1, 2026, 270, 'PUNTUAL'),
            ('c_010', 2, 2026, 280, 'PUNTUAL'), ('c_010', 3, 2026, 260, 'PUNTUAL'),
            ('c_010', 4, 2026, 270, 'PUNTUAL'), ('c_010', 5, 2026, 280, 'PUNTUAL');
    END IF;

    -- ─────────── OFERTAS_CACHE ───────────
    IF NOT EXISTS (SELECT 1 FROM ofertas_cache LIMIT 1) THEN
        INSERT INTO ofertas_cache (cliente_id, oferta_id, monto_maximo, plazo_sugerido_meses, tea_referencial, score_confianza, vigente, fecha_vencimiento) VALUES
            ('c_001', 'OFR001', 3500, 18, 28.5, 92, TRUE, NOW() + INTERVAL '60 days'),
            ('c_004', 'OFR002', 2500, 12, 26.0, 88, TRUE, NOW() + INTERVAL '45 days'),
            ('c_008', 'OFR003', 8000, 24, 27.0, 95, TRUE, NOW() + INTERVAL '90 days');
    END IF;

    -- ─────────── POSICION_CACHE ───────────
    IF NOT EXISTS (SELECT 1 FROM posicion_cache LIMIT 1) THEN
        INSERT INTO posicion_cache (cliente_id, deuda_total, cuentas_vigentes, cuentas_mora, dias_mayor_mora, ultimo_pago, updated_at) VALUES
            ('c_001', 2500, 12, 0, 0, NOW() - INTERVAL '10 days', NOW()),
            ('c_002', 3000, 8, 4, 20, NOW() - INTERVAL '15 days', NOW()),
            ('c_003', 5000, 10, 14, 85, NOW() - INTERVAL '45 days', NOW()),
            ('c_004', 1500, 12, 0, 0, NOW() - INTERVAL '5 days', NOW()),
            ('c_005', 800, 6, 0, 0, NOW() - INTERVAL '12 days', NOW()),
            ('c_006', 4000, 14, 4, 18, NOW() - INTERVAL '8 days', NOW()),
            ('c_007', 2800, 6, 6, 45, NOW() - INTERVAL '22 days', NOW()),
            ('c_008', 6000, 24, 0, 0, NOW() - INTERVAL '3 days', NOW()),
            ('c_009', 4200, 8, 10, 60, NOW() - INTERVAL '28 days', NOW()),
            ('c_010', 1800, 11, 1, 5, NOW() - INTERVAL '7 days', NOW());
    END IF;

    -- ─────────── CAMPANAS_CACHE ───────────
    IF NOT EXISTS (SELECT 1 FROM campanas_cache LIMIT 1) THEN
        INSERT INTO campanas_cache (id, cliente_id, nombre_cliente, tipo, monto_ofertado, fecha_vencimiento, activa) VALUES
            ('cmp_001', 'c_004', 'Carlos Huamán Ríos', 'renovacion', 2000, NOW() + INTERVAL '30 days', TRUE),
            ('cmp_002', 'c_008', 'José Ramos Huerta', 'ampliacion', 5000, NOW() + INTERVAL '45 days', TRUE),
            ('cmp_003', 'c_001', 'María López Torres', 'cruzada', 1500, NOW() + INTERVAL '20 days', TRUE);
    END IF;

    -- ─────────── SOLICITUDES_BORRADOR ───────────
    IF NOT EXISTS (SELECT 1 FROM solicitudes_borrador LIMIT 1) THEN
        INSERT INTO solicitudes_borrador (id, cliente_id, cliente_nombre, paso_actual, datos_json, monto_solicitado, asesor_id, updated_at) VALUES
            ('sol_br_001', 'c_004', 'Carlos Huamán Ríos', 2,
             ('{"id":"sol_br_001","numero_expediente":"","asesor_id":"123456","cliente_id":"c_004","nombre_cliente":"Carlos Huamán Ríos","estado":"borrador","paso_actual":2,"nombres":"Carlos","apellidos":"Huamán Ríos","documento":"45678901","fecha_nacimiento":"1990-05-12T00:00:00.000","estado_civil":"casado","grado_instruccion":"secundaria","telefono":"999000444","email":"carlos.huaman@email.com","tipo_negocio":"taxi","nombre_negocio":"Taxi Huamán","direccion_negocio":"Av. Arequipa 321, Lince","antiguedad_anios":3,"antiguedad_meses":6,"ingresos_mensuales":3000,"gastos_mensuales":1200,"patrimonio":15000,"destino_credito":"renovación de vehículo","actividad_economica":"transporte","monto_solicitado":1500,"plazo_meses":12,"moneda":"PEN","tipo_cuota":"mensual","garantia":"sinGarantia","cuota_estimada":152.50,"tea_referencial":32.0,"firma_cliente_base64":"","datos_veraces":false,"pendiente_sync":0,"fecha_creacion":"' || (NOW() - INTERVAL '2 days')::text || '","fecha_actualizacion":"' || NOW()::text || '"}')::jsonb,
             1500, '123456', NOW()),
            ('sol_br_002', 'c_006', 'Pedro Castillo Sánchez', 4,
             ('{"id":"sol_br_002","numero_expediente":"","asesor_id":"123456","cliente_id":"c_006","nombre_cliente":"Pedro Castillo Sánchez","estado":"borrador","paso_actual":4,"nombres":"Pedro","apellidos":"Castillo Sánchez","documento":"67890123","fecha_nacimiento":"1985-11-03T00:00:00.000","estado_civil":"soltero","grado_instruccion":"técnica","telefono":"999000666","email":"pedro.castillo@email.com","tipo_negocio":"carpintería","nombre_negocio":"Carpintería Castillo","direccion_negocio":"Av. Grau 987, Barranco","antiguedad_anios":7,"antiguedad_meses":2,"ingresos_mensuales":5000,"gastos_mensuales":2000,"patrimonio":35000,"destino_credito":"compra de maquinaria","actividad_economica":"manufactura","monto_solicitado":4000,"plazo_meses":18,"moneda":"PEN","tipo_cuota":"mensual","garantia":"aval","cuota_estimada":298.40,"tea_referencial":33.0,"firma_cliente_base64":"","datos_veraces":true,"pendiente_sync":0,"fecha_creacion":"' || (NOW() - INTERVAL '5 days')::text || '","fecha_actualizacion":"' || (NOW() - INTERVAL '1 day')::text || '"}')::jsonb,
             4000, '123456', NOW() - INTERVAL '1 day');
    END IF;

    -- ─────────── SOLICITUDES_ENVIADAS ───────────
    IF NOT EXISTS (SELECT 1 FROM solicitudes_enviadas LIMIT 1) THEN
        INSERT INTO solicitudes_enviadas (id, asesor_id, datos_json, estado, pendiente_sync, created_at, updated_at) VALUES
            ('sol_env_001', '123456', 
             ('{"id":"sol_env_001","numero_expediente":"EXP-2026-001","cliente_id":"c_001","nombre_cliente":"María López Torres","estado":"aprobado","paso_actual":8,"nombres":"María","apellidos":"López Torres","documento":"12345678","fecha_nacimiento":"1988-03-20T00:00:00.000","estado_civil":"casada","grado_instruccion":"secundaria","telefono":"999000111","email":"maria.lopez@email.com","tipo_negocio":"bodega","nombre_negocio":"Bodega Doña María","direccion_negocio":"Av. Los Olivos 123, San Martín","antiguedad_anios":8,"antiguedad_meses":0,"ingresos_mensuales":4000,"gastos_mensuales":1500,"patrimonio":50000,"destino_credito":"capital de trabajo","actividad_economica":"comercio","monto_solicitado":2500,"plazo_meses":18,"moneda":"PEN","tipo_cuota":"mensual","garantia":"sinGarantia","cuota_estimada":195.30,"tea_referencial":30.0,"firma_cliente_base64":"","datos_veraces":true,"pendiente_sync":0,"fecha_creacion":"' || (NOW() - INTERVAL '30 days')::text || '","fecha_actualizacion":"' || (NOW() - INTERVAL '5 days')::text || '"}')::jsonb,
             'aprobado', FALSE, NOW() - INTERVAL '30 days', NOW() - INTERVAL '5 days'),
            ('sol_env_002', '123456',
             ('{"id":"sol_env_002","numero_expediente":"EXP-2026-002","cliente_id":"c_008","nombre_cliente":"José Ramos Huerta","estado":"enEvaluacion","paso_actual":7,"nombres":"José","apellidos":"Ramos Huerta","documento":"89012345","fecha_nacimiento":"1982-07-15T00:00:00.000","estado_civil":"casado","grado_instruccion":"universitaria","telefono":"999000888","email":"jose.ramos@email.com","tipo_negocio":"farmacia","nombre_negocio":"Farmacia Ramos","direccion_negocio":"Av. Primavera 258, Surco","antiguedad_anios":10,"antiguedad_meses":0,"ingresos_mensuales":8000,"gastos_mensuales":3500,"patrimonio":80000,"destino_credito":"ampliación de local","actividad_economica":"salud","monto_solicitado":6000,"plazo_meses":24,"moneda":"PEN","tipo_cuota":"mensual","garantia":"hipotecaria","cuota_estimada":342.80,"tea_referencial":29.0,"firma_cliente_base64":"","datos_veraces":true,"pendiente_sync":0,"fecha_creacion":"' || (NOW() - INTERVAL '15 days')::text || '","fecha_actualizacion":"' || (NOW() - INTERVAL '3 days')::text || '"}')::jsonb,
             'enEvaluacion', FALSE, NOW() - INTERVAL '15 days', NOW() - INTERVAL '3 days'),
            ('sol_env_003', '123456',
             ('{"id":"sol_env_003","numero_expediente":"EXP-2026-003","cliente_id":"c_010","nombre_cliente":"Miguel Pizarro Díaz","estado":"rechazado","paso_actual":8,"nombres":"Miguel Ángel","apellidos":"Pizarro Díaz","documento":"10123456","fecha_nacimiento":"1992-01-08T00:00:00.000","estado_civil":"soltero","grado_instruccion":"técnica","telefono":"999000000","email":"miguel.pizarro@email.com","tipo_negocio":"transporte","nombre_negocio":"Transportes Pizarro","direccion_negocio":"Av. Central 741, SJL","antiguedad_anios":5,"antiguedad_meses":0,"ingresos_mensuales":3500,"gastos_mensuales":1500,"patrimonio":25000,"destino_credito":"compra de unidad","actividad_economica":"transporte","monto_solicitado":3000,"plazo_meses":12,"moneda":"PEN","tipo_cuota":"mensual","garantia":"aval","cuota_estimada":298.40,"tea_referencial":32.0,"firma_cliente_base64":"","datos_veraces":true,"pendiente_sync":0,"fecha_creacion":"' || (NOW() - INTERVAL '60 days')::text || '","fecha_actualizacion":"' || (NOW() - INTERVAL '25 days')::text || '"}')::jsonb,
             'rechazado', FALSE, NOW() - INTERVAL '60 days', NOW() - INTERVAL '25 days');
    END IF;

    -- ─────────── SOLICITUDES_DOCUMENTOS ───────────
    IF NOT EXISTS (SELECT 1 FROM solicitudes_documentos LIMIT 1) THEN
        INSERT INTO solicitudes_documentos (id, solicitud_id, tipo_documento, estado, storage_url, tamanio_kb, nitidez_score, local_path, created_at) VALUES
            ('doc_001', 'sol_env_001', 'DNI', 'completo', NULL, 245, 0.95, NULL, NOW() - INTERVAL '10 days'),
            ('doc_002', 'sol_env_001', 'RECIBO_SERVICIO', 'completo', NULL, 180, 0.88, NULL, NOW() - INTERVAL '10 days'),
            ('doc_003', 'sol_env_001', 'DECLARACION_IMPuestos', 'pendiente', NULL, NULL, NULL, NULL, NOW() - INTERVAL '10 days'),
            ('doc_004', 'sol_env_002', 'DNI', 'completo', NULL, 260, 0.92, NULL, NOW() - INTERVAL '10 days'),
            ('doc_005', 'sol_env_002', 'RECIBO_SERVICIO', 'completo', NULL, 195, 0.90, NULL, NOW() - INTERVAL '10 days'),
            ('doc_006', 'sol_env_002', 'TITULO_PROPIEDAD', 'completo', NULL, 520, 0.85, NULL, NOW() - INTERVAL '10 days'),
            ('doc_007', 'sol_env_003', 'DNI', 'completo', NULL, 230, 0.91, NULL, NOW() - INTERVAL '10 days'),
            ('doc_008', 'sol_env_003', 'RECIBO_SERVICIO', 'pendiente', NULL, NULL, NULL, NULL, NOW() - INTERVAL '10 days');
    END IF;

    -- ─────────── TRANSMISION_ESTADO ───────────
    IF NOT EXISTS (SELECT 1 FROM transmision_estado LIMIT 1) THEN
        INSERT INTO transmision_estado (solicitud_id, paso_completado, documentos_subidos, expediente_generado, updated_at) VALUES
            ('sol_env_001', 5, '["DNI","RECIBO_SERVICIO","DECLARACION_IMPuestos"]', 'EXP-2026-001.pdf', NOW() - INTERVAL '1 day'),
            ('sol_env_002', 3, '["DNI","RECIBO_SERVICIO","TITULO_PROPIEDAD"]', NULL, NOW() - INTERVAL '2 days');
    END IF;

    -- ─────────── CARTERA_VENCIDA_CACHE ───────────
    IF NOT EXISTS (SELECT 1 FROM cartera_vencida_cache LIMIT 1) THEN
        INSERT INTO cartera_vencida_cache (id, cliente_id, credito_id, nombre_cliente, documento_cliente, telefono, direccion, dias_mora, monto_vencido, saldo_actual, ultimo_contacto, cuotas_pagadas, total_cuotas, updated_at) VALUES
            ('mor_001', 'c_003', 'CR004', 'Rosa Mamani Condori', '34567890', '999000333', 'Calle Real 789, Huancayo', 85, 3200, 5000, NOW() - INTERVAL '90 days', 4, 24, NOW()),
            ('mor_002', 'c_007', 'CR009', 'Ana Gutiérrez Paredes', '78901234', '999000777', 'Calle Los Pinos 147, Miraflores', 45, 1500, 2800, NOW() - INTERVAL '50 days', 6, 12, NOW()),
            ('mor_003', 'c_009', 'CR013', 'Elena Vargas Ruiz', '90123456', '999000999', 'Jr. Amazonas 369, Magdalena', 60, 2500, 4200, NOW() - INTERVAL '65 days', 8, 18, NOW()),
            ('mor_004', 'c_002', 'CR003', 'Juan Pérez García', '23456789', '999000222', 'Jr. Las Flores 456, Breña', 20, 800, 3000, NOW() - INTERVAL '25 days', 10, 12, NOW());
    END IF;

    -- ─────────── ACCIONES_COBRANZA_PENDIENTES ───────────
    IF NOT EXISTS (SELECT 1 FROM acciones_cobranza_pendientes LIMIT 1) THEN
        INSERT INTO acciones_cobranza_pendientes (id, asesor_id, cliente_id, credito_id, tipo_gestion, resultado, monto_pagado, fecha_compromiso, monto_compromiso, observaciones, lat, lng, timestamp_gestion, pendiente_sync) VALUES
            ('ac_001', '123456', 'c_003', 'CR004', 'visita_domiciliaria', 'sin_contacto', NULL, NULL, NULL, 'Cliente no se encontraba en domicilio. Vecinos indican que viajó.', -12.0654, -77.0289, NOW() - INTERVAL '3 days', TRUE),
            ('ac_002', '123456', 'c_007', 'CR009', 'llamada_telefonica', 'compromiso_pago', NULL, NOW() + INTERVAL '5 days', 800, 'Cliente se comprometió a pagar S/800 el día viernes.', -12.0912, -77.0489, NOW() - INTERVAL '1 day', TRUE);
    END IF;

    -- ─────────── CONSULTAS_BURO ───────────
    IF NOT EXISTS (SELECT 1 FROM consultas_buro LIMIT 1) THEN
        INSERT INTO consultas_buro (id, asesor_id, cliente_id, dni_consultado, calificacion_sbs, entidades_con_deuda, deuda_total_pen, mayor_deuda, dias_mayor_mora, resultado_json, en_lista_negra, motivo_bloqueo, firma_consentimiento_base64, solicitud_id, created_at) VALUES
            ('buro_001', '123456', 'c_001', '12345678', 'normal', 2, 3500, 2000, 0, '{"calificacion":"normal","entidades":2,"deuda_total":3500,"dias_mora":0}'::jsonb, FALSE, NULL, NULL, NULL, NOW() - INTERVAL '7 days'),
            ('buro_002', '123456', 'c_002', '23456789', 'cpp', 3, 5000, 3000, 20, '{"calificacion":"cpp","entidades":3,"deuda_total":5000,"dias_mora":20}'::jsonb, FALSE, NULL, NULL, NULL, NOW() - INTERVAL '7 days'),
            ('buro_003', '123456', 'c_003', '34567890', 'deficiente', 5, 12000, 5000, 85, '{"calificacion":"deficiente","entidades":5,"deuda_total":12000,"dias_mora":85}'::jsonb, FALSE, NULL, NULL, NULL, NOW() - INTERVAL '7 days'),
            ('buro_004', '123456', 'c_004', '45678901', 'normal', 1, 1500, 1500, 0, '{"calificacion":"normal","entidades":1,"deuda_total":1500,"dias_mora":0}'::jsonb, FALSE, NULL, NULL, NULL, NOW() - INTERVAL '7 days'),
            ('buro_005', '123456', 'c_005', '56789012', 'normal', 0, 0, 0, 0, '{"calificacion":"normal","entidades":0,"deuda_total":0,"dias_mora":0}'::jsonb, FALSE, NULL, NULL, NULL, NOW() - INTERVAL '7 days');
    END IF;

    -- ─────────── SOLICITUDES (general sync table) ───────────
    IF NOT EXISTS (SELECT 1 FROM solicitudes LIMIT 1) THEN
        INSERT INTO solicitudes (id, cliente_id, tipo_credito, monto_solicitado, plazo_meses, estado, datos_json, pendiente_sync, created_at, updated_at) VALUES
            ('sol_env_001', 'c_001', 'libre_disponibilidad', 3000, 12, 'aprobado', NULL, FALSE, NOW() - INTERVAL '30 days', NOW()),
            ('sol_env_002', 'c_008', 'libre_disponibilidad', 3000, 12, 'enEvaluacion', NULL, FALSE, NOW() - INTERVAL '15 days', NOW()),
            ('sol_env_003', 'c_010', 'libre_disponibilidad', 3000, 12, 'rechazado', NULL, FALSE, NOW() - INTERVAL '60 days', NOW()),
            ('sol_br_001', 'c_004', 'libre_disponibilidad', 3000, 12, 'borrador', NULL, TRUE, NOW() - INTERVAL '2 days', NOW()),
            ('sol_br_002', 'c_006', 'libre_disponibilidad', 3000, 12, 'borrador', NULL, TRUE, NOW() - INTERVAL '5 days', NOW());
    END IF;

END $$;