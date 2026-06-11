import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class SeedData {
  static final _uuid = const Uuid();

  static const _asesorId = '123456';
  static const _agenciaId = 'AG001';

  static String _ts({int daysAgo = 0}) {
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    return d.toIso8601String();
  }

  static String _future({int daysAhead = 30}) {
    final d = DateTime.now().add(Duration(days: daysAhead));
    return d.toIso8601String();
  }

  static Future<void> seed(Database db) async {
    await _seedTableIfEmpty(db, 'cartera', () => _seedCartera(db));
    await _seedTableIfEmpty(db, 'ficha_cache', () => _seedFichaCache(db));
    await _seedTableIfEmpty(db, 'creditos_cache', () => _seedCreditosCache(db));
    await _seedTableIfEmpty(db, 'pagos_cache', () => _seedPagosCache(db));
    await _seedTableIfEmpty(db, 'ofertas_cache', () => _seedOfertasCache(db));
    await _seedTableIfEmpty(db, 'posicion_cache', () => _seedPosicionCache(db));
    await _seedTableIfEmpty(db, 'campanas_cache', () => _seedCampanas(db));
    await _seedTableIfEmpty(db, 'solicitudes_borrador', () => _seedSolicitudesBorrador(db));
    await _seedTableIfEmpty(db, 'solicitudes_enviadas', () => _seedSolicitudesEnviadas(db));
    await _seedTableIfEmpty(db, 'solicitudes_documentos', () => _seedSolicitudesDocumentos(db));
    await _seedTableIfEmpty(db, 'transmision_estado', () => _seedTransmisionEstado(db));
    await _seedTableIfEmpty(db, 'cartera_vencida_cache', () => _seedCarteraVencida(db));
    await _seedTableIfEmpty(db, 'acciones_cobranza_pendientes', () => _seedAccionesCobranza(db));
  }

  static Future<void> _seedTableIfEmpty(
      Database db, String tableName, Future<void> Function() seedFunction) async {
    try {
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableName'));
      if (count == null || count == 0) {
        await seedFunction();
      }
    } catch (_) {
      // Table might not exist or other database error. Skip gracefully.
    }
  }

  @pragma('vm:prefer-inline')
  static String _id() => _uuid.v4();

  // ─────── CARTERA ───────
  static Future<void> _seedCartera(Database db) async {
    final rows = [
      _car('c_001', 'María López Torres', '12345678',
          'Av. Los Olivos 123, San Martín', '999000111',
          -12.0453, -77.0324, 'RENOVACION', 5, 2000),
      _car('c_002', 'Juan Pérez García', '23456789',
          'Jr. Las Flores 456, Breña', '999000222',
          -12.0521, -77.0456, 'SEGUIMIENTO', 10, 3500),
      _car('c_003', 'Rosa Mamani Condori', '34567890',
          'Calle Real 789, Huancayo', '999000333',
          -12.0654, -77.0289, 'RECUPERACION_MORA', 85, 5000),
      _car('c_004', 'Carlos Huamán Ríos', '45678901',
          'Av. Arequipa 321, Lince', '999000444',
          -12.0756, -77.0398, 'NUEVA_SOLICITUD', 5, 1500),
      _car('c_005', 'Lucía Quispe Flores', '56789012',
          'Jr. Unión 654, Cercado', '999000555',
          -12.0389, -77.0512, 'DESERTOR', 25, 800),
      _car('c_006', 'Pedro Castillo Sánchez', '67890123',
          'Av. Grau 987, Barranco', '999000666',
          -12.0821, -77.0345, 'AMPLIACION', 20, 4000),
      _car('c_007', 'Ana Gutiérrez Paredes', '78901234',
          'Calle Los Pinos 147, Miraflores', '999000777',
          -12.0912, -77.0489, 'RECUPERACION_MORA', 65, 2800),
      _car('c_008', 'José Ramos Huerta', '89012345',
          'Av. Primavera 258, Surco', '999000888',
          -12.1034, -77.0256, 'RENOVACION', 15, 6000),
      _car('c_009', 'Elena Vargas Ruiz', '90123456',
          'Jr. Amazonas 369, Magdalena', '999000999',
          -12.0587, -77.0678, 'RECUPERACION_MORA', 75, 4200),
      _car('c_010', 'Miguel Pizarro Díaz', '10123456',
          'Av. Central 741, San Juan de Lurigancho', '999000000',
          -12.0712, -77.0123, 'SEGUIMIENTO', 30, 1800),
    ];

    final batch = db.batch();
    for (final r in rows) { batch.insert('cartera', r); }
    await batch.commit(noResult: true);
  }

  static Map<String, dynamic> _car(
    String cid, String nom, String doc, String dir, String tel,
    double lat, double lng, String tipo, int score, double monto) {
    return {
      'id': _id(),
      'asesor_id': _asesorId,
      'cliente_id': cid,
      'agencia_id': _agenciaId,
      'fecha_asignacion': _ts(daysAgo: 3),
      'tipo_gestion': tipo,
      'prioridad': score >= 70 ? 'alta' : (score >= 40 ? 'media' : 'normal'),
      'score_prioridad': score,
      'estado_visita': 'pendiente',
      'resultado_visita': null,
      'observacion_visita': null,
      'timestamp_visita': null,
      'lat_visita': null,
      'lng_visita': null,
      'orden_manual': 0,
      'pendiente_sync': 0,
      'nombre_cliente': nom,
      'documento_cliente': doc,
      'direccion_cliente': dir,
      'telefono_cliente': tel,
      'monto_credito': monto,
    };
  }

  // ─────── FICHA CACHE ───────
  static Future<void> _seedFichaCache(Database db) async {
    final rows = [
      _ficha('c_001', 'María López Torres', '12345678',
          'Av. Los Olivos 123, San Martín', '999000111',
          'maria.lopez@email.com', 'Bodega', 8,
          -12.0453, -77.0324, 'normal'),
      _ficha('c_002', 'Juan Pérez García', '23456789',
          'Jr. Las Flores 456, Breña', '999000222',
          'juan.perez@email.com', 'Ferretería', 5,
          -12.0521, -77.0456, 'cpp'),
      _ficha('c_003', 'Rosa Mamani Condori', '34567890',
          'Calle Real 789, Huancayo', '999000333',
          'rosa.mamani@email.com', 'Restaurante', 12,
          -12.0654, -77.0289, 'deficiente'),
      _ficha('c_004', 'Carlos Huamán Ríos', '45678901',
          'Av. Arequipa 321, Lince', '999000444',
          'carlos.huaman@email.com', 'Transporte', 3,
          -12.0756, -77.0398, 'normal'),
      _ficha('c_005', 'Lucía Quispe Flores', '56789012',
          'Jr. Unión 654, Cercado', '999000555',
          'lucia.quispe@email.com', 'Peluquería', 2,
          -12.0389, -77.0512, 'normal'),
      _ficha('c_006', 'Pedro Castillo Sánchez', '67890123',
          'Av. Grau 987, Barranco', '999000666',
          'pedro.castillo@email.com', 'Carpintería', 7,
          -12.0821, -77.0345, 'cpp'),
      _ficha('c_007', 'Ana Gutiérrez Paredes', '78901234',
          'Calle Los Pinos 147, Miraflores', '999000777',
          'ana.gutierrez@email.com', 'Tienda de ropa', 4,
          -12.0912, -77.0489, 'dudoso'),
      _ficha('c_008', 'José Ramos Huerta', '89012345',
          'Av. Primavera 258, Surco', '999000888',
          'jose.ramos@email.com', 'Farmacia', 10,
          -12.1034, -77.0256, 'normal'),
      _ficha('c_009', 'Elena Vargas Ruiz', '90123456',
          'Jr. Amazonas 369, Magdalena', '999000999',
          'elena.vargas@email.com', 'Hospedaje', 6,
          -12.0587, -77.0678, 'deficiente'),
      _ficha('c_010', 'Miguel Pizarro Díaz', '10123456',
          'Av. Central 741, SJL', '999000000',
          'miguel.pizarro@email.com', 'Transporte', 9,
          -12.0712, -77.0123, 'normal'),
    ];

    final batch = db.batch();
    for (final r in rows) { batch.insert('ficha_cache', r, conflictAlgorithm: ConflictAlgorithm.replace); }
    await batch.commit(noResult: true);
  }

  static Map<String, dynamic> _ficha(
    String cid, String nom, String doc, String dir, String tel,
    String email, String neg, int ant, double lat, double lng, String sbs) {
    return {
      'cliente_id': cid,
      'nombre': nom,
      'documento': doc,
      'direccion': dir,
      'telefono': tel,
      'email': email,
      'tipo_negocio': neg,
      'antiguedad_negocio': ant,
      'lat': lat,
      'lng': lng,
      'calificacion_sbs': sbs,
      'updated_at': _ts(),
    };
  }

  // ─────── CREDITOS CACHE ───────
  static Future<void> _seedCreditosCache(Database db) async {
    final rows = [
      _cred('c_001', 'CR001', 2000, 12, 32.5, 'pagado', 100, _ts(daysAgo: 400), _ts(daysAgo: 40)),
      _cred('c_001', 'CR002', 2500, 18, 30.0, 'vigente', 95, _ts(daysAgo: 100), null),
      _cred('c_002', 'CR003', 3000, 12, 35.0, 'vigente', 70, _ts(daysAgo: 180), null),
      _cred('c_003', 'CR004', 5000, 24, 38.0, 'vigente', 40, _ts(daysAgo: 300), null),
      _cred('c_003', 'CR005', 2000, 12, 36.0, 'pagado', 60, _ts(daysAgo: 600), _ts(daysAgo: 200)),
      _cred('c_004', 'CR006', 1500, 12, 28.0, 'pagado', 100, _ts(daysAgo: 500), _ts(daysAgo: 50)),
      _cred('c_005', 'CR007', 800, 6, 30.0, 'pagado', 100, _ts(daysAgo: 300), _ts(daysAgo: 90)),
      _cred('c_006', 'CR008', 4000, 18, 33.0, 'vigente', 80, _ts(daysAgo: 200), null),
      _cred('c_007', 'CR009', 2800, 12, 36.0, 'vigente', 50, _ts(daysAgo: 250), null),
      _cred('c_007', 'CR010', 1500, 12, 34.0, 'pagado', 75, _ts(daysAgo: 550), _ts(daysAgo: 150)),
      _cred('c_008', 'CR011', 6000, 24, 29.0, 'vigente', 100, _ts(daysAgo: 120), null),
      _cred('c_008', 'CR012', 3000, 12, 31.0, 'pagado', 100, _ts(daysAgo: 450), _ts(daysAgo: 30)),
      _cred('c_009', 'CR013', 4200, 18, 37.0, 'vigente', 30, _ts(daysAgo: 280), null),
      _cred('c_010', 'CR014', 1800, 12, 32.0, 'pagado', 90, _ts(daysAgo: 350), _ts(daysAgo: 60)),
    ];

    final batch = db.batch();
    for (final r in rows) { batch.insert('creditos_cache', r, conflictAlgorithm: ConflictAlgorithm.replace); }
    await batch.commit(noResult: true);
  }

  static Map<String, dynamic> _cred(
    String cid, String credId, double monto, int plazo, double tea,
    String estado, double puntual, String? fapertura, String? fcierre) {
    return {
      'cliente_id': cid,
      'credito_id': credId,
      'monto': monto,
      'plazo_meses': plazo,
      'tea': tea,
      'estado': estado,
      'porcentaje_puntual': puntual,
      'fecha_apertura': fapertura,
      'fecha_cierre': fcierre,
    };
  }

  // ─────── PAGOS CACHE ───────
  static Future<void> _seedPagosCache(Database db) async {
    final batch = db.batch();
    final now = DateTime.now();
    final anio = now.year;
    final mes = now.month;

    for (final cid in ['c_001', 'c_002', 'c_003', 'c_004', 'c_005',
                        'c_006', 'c_007', 'c_008', 'c_009', 'c_010']) {
      for (int i = 11; i >= 0; i--) {
        int m = mes - i;
        int a = anio;
        if (m <= 0) { m += 12; a -= 1; }

        String status;
        double montoPagado;
        if (cid == 'c_001' || cid == 'c_004' || cid == 'c_008' || cid == 'c_010') {
          status = 'PUNTUAL';
          montoPagado = 250.0 + (i % 3) * 10;
        } else if (cid == 'c_003' || cid == 'c_009') {
          status = i < 5 ? 'PUNTUAL' : 'MORA';
          montoPagado = i < 5 ? 350.0 : 200.0;
        } else if (cid == 'c_007') {
          status = i < 3 ? 'PUNTUAL' : 'MORA';
          montoPagado = i < 3 ? 300.0 : 150.0;
        } else if (cid == 'c_002' || cid == 'c_006') {
          status = i < 8 ? 'PUNTUAL' : 'MORA';
          montoPagado = i < 8 ? 280.0 : 180.0;
        } else {
          status = 'PUNTUAL';
          montoPagado = 150.0;
        }

        batch.insert('pagos_cache', {
          'cliente_id': cid,
          'mes': m,
          'anio': a,
          'monto_pagado': montoPagado,
          'status': status,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }

  // ─────── OFERTAS CACHE ───────
  static Future<void> _seedOfertasCache(Database db) async {
    final rows = [
      _oferta('c_001', 'OFR001', 3500, 18, 28.5, 92, _future(daysAhead: 60)),
      _oferta('c_004', 'OFR002', 2500, 12, 26.0, 88, _future(daysAhead: 45)),
      _oferta('c_008', 'OFR003', 8000, 24, 27.0, 95, _future(daysAhead: 90)),
    ];

    final batch = db.batch();
    for (final r in rows) { batch.insert('ofertas_cache', r, conflictAlgorithm: ConflictAlgorithm.replace); }
    await batch.commit(noResult: true);
  }

  static Map<String, dynamic> _oferta(
    String cid, String oid, double monto, int plazo, double tea,
    int score, String venc) {
    return {
      'cliente_id': cid,
      'oferta_id': oid,
      'monto_maximo': monto,
      'plazo_sugerido_meses': plazo,
      'tea_referencial': tea,
      'score_confianza': score,
      'vigente': 1,
      'fecha_vencimiento': venc,
    };
  }

  // ─────── POSICION CACHE ───────
  static Future<void> _seedPosicionCache(Database db) async {
    final rows = [
      _posicion('c_001', 2500, 12, 0, 0, _ts(daysAgo: 10)),
      _posicion('c_002', 3000, 8, 4, 20, _ts(daysAgo: 15)),
      _posicion('c_003', 5000, 10, 14, 85, _ts(daysAgo: 45)),
      _posicion('c_004', 1500, 12, 0, 0, _ts(daysAgo: 5)),
      _posicion('c_005', 800, 6, 0, 0, _ts(daysAgo: 12)),
      _posicion('c_006', 4000, 14, 4, 18, _ts(daysAgo: 8)),
      _posicion('c_007', 2800, 6, 6, 45, _ts(daysAgo: 22)),
      _posicion('c_008', 6000, 24, 0, 0, _ts(daysAgo: 3)),
      _posicion('c_009', 4200, 8, 10, 60, _ts(daysAgo: 28)),
      _posicion('c_010', 1800, 11, 1, 5, _ts(daysAgo: 7)),
    ];

    final batch = db.batch();
    for (final r in rows) {
      batch.insert('posicion_cache', r, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Map<String, dynamic> _posicion(
    String cid, double deuda, int vigentes, int mora, int diasMora, String? ultPago) {
    return {
      'cliente_id': cid,
      'deuda_total': deuda,
      'cuentas_vigentes': vigentes,
      'cuentas_mora': mora,
      'dias_mayor_mora': diasMora,
      'ultimo_pago': ultPago,
      'updated_at': _ts(),
    };
  }

  // ─────── CAMPANAS ───────
  static Future<void> _seedCampanas(Database db) async {
    final rows = [
      _camp('cmp_001', 'c_004', 'Carlos Huamán Ríos', 'renovacion', 2000, _future(daysAhead: 30)),
      _camp('cmp_002', 'c_008', 'José Ramos Huerta', 'ampliacion', 5000, _future(daysAhead: 45)),
      _camp('cmp_003', 'c_001', 'María López Torres', 'cruzada', 1500, _future(daysAhead: 20)),
    ];

    final batch = db.batch();
    for (final r in rows) { batch.insert('campanas_cache', r, conflictAlgorithm: ConflictAlgorithm.replace); }
    await batch.commit(noResult: true);
  }

  static Map<String, dynamic> _camp(
    String id, String cid, String nom, String tipo, double monto, String venc) {
    return {
      'id': id,
      'cliente_id': cid,
      'nombre_cliente': nom,
      'tipo': tipo,
      'monto_ofertado': monto,
      'fecha_vencimiento': venc,
      'activa': 1,
    };
  }

  // ─────── SOLICITUDES BORRADOR ───────
  static Future<void> _seedSolicitudesBorrador(Database db) async {
    final batch = db.batch();
    final now = DateTime.now();

    batch.insert('solicitudes_borrador', {
      'id': 'sol_br_001',
      'cliente_id': 'c_004',
      'cliente_nombre': 'Carlos Huamán Ríos',
      'paso_actual': 2,
      'datos_json': jsonEncode({
        'id': 'sol_br_001',
        'numero_expediente': '',
        'asesor_id': _asesorId,
        'cliente_id': 'c_004',
        'nombre_cliente': 'Carlos Huamán Ríos',
        'estado': 'borrador',
        'paso_actual': 2,
        'nombres': 'Carlos',
        'apellidos': 'Huamán Ríos',
        'documento': '45678901',
        'fecha_nacimiento': DateTime(1990, 5, 12).toIso8601String(),
        'estado_civil': 'casado',
        'grado_instruccion': 'secundaria',
        'telefono': '999000444',
        'email': 'carlos.huaman@email.com',
        'tipo_negocio': 'taxi',
        'nombre_negocio': 'Taxi Huamán',
        'direccion_negocio': 'Av. Arequipa 321, Lince',
        'antiguedad_anios': 3,
        'antiguedad_meses': 6,
        'ingresos_mensuales': 3000,
        'gastos_mensuales': 1200,
        'patrimonio': 15000,
        'destino_credito': 'renovación de vehículo',
        'actividad_economica': 'transporte',
        'monto_solicitado': 1500,
        'plazo_meses': 12,
        'moneda': 'PEN',
        'tipo_cuota': 'mensual',
        'garantia': 'sinGarantia',
        'cuota_estimada': 152.50,
        'tea_referencial': 32.0,
        'firma_cliente_base64': '',
        'datos_veraces': false,
        'pendiente_sync': 0,
        'fecha_creacion': now.subtract(const Duration(days: 2)).toIso8601String(),
        'fecha_actualizacion': now.toIso8601String(),
      }),
      'monto_solicitado': 1500,
      'asesor_id': _asesorId,
      'updated_at': now.toIso8601String(),
    });

    batch.insert('solicitudes_borrador', {
      'id': 'sol_br_002',
      'cliente_id': 'c_006',
      'cliente_nombre': 'Pedro Castillo Sánchez',
      'paso_actual': 4,
      'datos_json': jsonEncode({
        'id': 'sol_br_002',
        'numero_expediente': '',
        'asesor_id': _asesorId,
        'cliente_id': 'c_006',
        'nombre_cliente': 'Pedro Castillo Sánchez',
        'estado': 'borrador',
        'paso_actual': 4,
        'nombres': 'Pedro',
        'apellidos': 'Castillo Sánchez',
        'documento': '67890123',
        'fecha_nacimiento': DateTime(1985, 11, 3).toIso8601String(),
        'estado_civil': 'soltero',
        'grado_instruccion': 'técnica',
        'telefono': '999000666',
        'email': 'pedro.castillo@email.com',
        'tipo_negocio': 'carpintería',
        'nombre_negocio': 'Carpintería Castillo',
        'direccion_negocio': 'Av. Grau 987, Barranco',
        'antiguedad_anios': 7,
        'antiguedad_meses': 2,
        'ingresos_mensuales': 5000,
        'gastos_mensuales': 2000,
        'patrimonio': 35000,
        'destino_credito': 'compra de maquinaria',
        'actividad_economica': 'manufactura',
        'monto_solicitado': 4000,
        'plazo_meses': 18,
        'moneda': 'PEN',
        'tipo_cuota': 'mensual',
        'garantia': 'aval',
        'cuota_estimada': 298.40,
        'tea_referencial': 33.0,
        'firma_cliente_base64': '',
        'datos_veraces': true,
        'pendiente_sync': 0,
        'fecha_creacion': now.subtract(const Duration(days: 5)).toIso8601String(),
        'fecha_actualizacion': now.subtract(const Duration(days: 1)).toIso8601String(),
      }),
      'monto_solicitado': 4000,
      'asesor_id': _asesorId,
      'updated_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    });

    await batch.commit(noResult: true);
  }

  // ─────── SOLICITUDES ENVIADAS ───────
  static Future<void> _seedSolicitudesEnviadas(Database db) async {
    final batch = db.batch();
    final now = DateTime.now();

    final enviadas = [
      {
        'id': 'sol_env_001',
        'numero_expediente': 'EXP-2026-001',
        'cliente_id': 'c_001',
        'nombre_cliente': 'María López Torres',
        'estado': 'aprobado',
        'paso_actual': 8,
        'nombres': 'María',
        'apellidos': 'López Torres',
        'documento': '12345678',
        'fecha_nacimiento': DateTime(1988, 3, 20).toIso8601String(),
        'estado_civil': 'casada',
        'grado_instruccion': 'secundaria',
        'telefono': '999000111',
        'email': 'maria.lopez@email.com',
        'tipo_negocio': 'bodega',
        'nombre_negocio': 'Bodega Doña María',
        'direccion_negocio': 'Av. Los Olivos 123, San Martín',
        'antiguedad_anios': 8,
        'antiguedad_meses': 0,
        'ingresos_mensuales': 4000,
        'gastos_mensuales': 1500,
        'patrimonio': 50000,
        'destino_credito': 'capital de trabajo',
        'actividad_economica': 'comercio',
        'monto_solicitado': 2500,
        'plazo_meses': 18,
        'moneda': 'PEN',
        'tipo_cuota': 'mensual',
        'garantia': 'sinGarantia',
        'cuota_estimada': 195.30,
        'tea_referencial': 30.0,
        'firma_cliente_base64': '',
        'datos_veraces': true,
        'pendiente_sync': 0,
        'fecha_creacion': now.subtract(const Duration(days: 30)).toIso8601String(),
        'fecha_actualizacion': now.subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': 'sol_env_002',
        'numero_expediente': 'EXP-2026-002',
        'cliente_id': 'c_008',
        'nombre_cliente': 'José Ramos Huerta',
        'estado': 'enEvaluacion',
        'paso_actual': 7,
        'nombres': 'José',
        'apellidos': 'Ramos Huerta',
        'documento': '89012345',
        'fecha_nacimiento': DateTime(1982, 7, 15).toIso8601String(),
        'estado_civil': 'casado',
        'grado_instruccion': 'universitaria',
        'telefono': '999000888',
        'email': 'jose.ramos@email.com',
        'tipo_negocio': 'farmacia',
        'nombre_negocio': 'Farmacia Ramos',
        'direccion_negocio': 'Av. Primavera 258, Surco',
        'antiguedad_anios': 10,
        'antiguedad_meses': 0,
        'ingresos_mensuales': 8000,
        'gastos_mensuales': 3500,
        'patrimonio': 80000,
        'destino_credito': 'ampliación de local',
        'actividad_economica': 'salud',
        'monto_solicitado': 6000,
        'plazo_meses': 24,
        'moneda': 'PEN',
        'tipo_cuota': 'mensual',
        'garantia': 'hipotecaria',
        'cuota_estimada': 342.80,
        'tea_referencial': 29.0,
        'firma_cliente_base64': '',
        'datos_veraces': true,
        'pendiente_sync': 0,
        'fecha_creacion': now.subtract(const Duration(days: 15)).toIso8601String(),
        'fecha_actualizacion': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': 'sol_env_003',
        'numero_expediente': 'EXP-2026-003',
        'cliente_id': 'c_010',
        'nombre_cliente': 'Miguel Pizarro Díaz',
        'estado': 'rechazado',
        'paso_actual': 8,
        'nombres': 'Miguel Ángel',
        'apellidos': 'Pizarro Díaz',
        'documento': '10123456',
        'fecha_nacimiento': DateTime(1992, 1, 8).toIso8601String(),
        'estado_civil': 'soltero',
        'grado_instruccion': 'técnica',
        'telefono': '999000000',
        'email': 'miguel.pizarro@email.com',
        'tipo_negocio': 'transporte',
        'nombre_negocio': 'Transportes Pizarro',
        'direccion_negocio': 'Av. Central 741, SJL',
        'antiguedad_anios': 5,
        'antiguedad_meses': 0,
        'ingresos_mensuales': 3500,
        'gastos_mensuales': 1500,
        'patrimonio': 25000,
        'destino_credito': 'compra de unidad',
        'actividad_economica': 'transporte',
        'monto_solicitado': 3000,
        'plazo_meses': 12,
        'moneda': 'PEN',
        'tipo_cuota': 'mensual',
        'garantia': 'aval',
        'cuota_estimada': 298.40,
        'tea_referencial': 32.0,
        'firma_cliente_base64': '',
        'datos_veraces': true,
        'pendiente_sync': 0,
        'fecha_creacion': now.subtract(const Duration(days: 60)).toIso8601String(),
        'fecha_actualizacion': now.subtract(const Duration(days: 25)).toIso8601String(),
      },
    ];

    for (final j in enviadas) {
      batch.insert('solicitudes_enviadas', {
        'id': j['id'],
        'asesor_id': _asesorId,
        'datos_json': jsonEncode(j),
        'estado': j['estado'],
        'pendiente_sync': 0,
        'created_at': j['fecha_creacion'],
        'updated_at': j['fecha_actualizacion'],
      });
    }

    await batch.commit(noResult: true);
  }

  // ─────── SOLICITUDES DOCUMENTOS ───────
  static Future<void> _seedSolicitudesDocumentos(Database db) async {
    final rows = [
      _doc('doc_001', 'sol_env_001', 'DNI', 'completo', null, 245, 0.95, null),
      _doc('doc_002', 'sol_env_001', 'RECIBO_SERVICIO', 'completo', null, 180, 0.88, null),
      _doc('doc_003', 'sol_env_001', 'DECLARACION_IMPuestos', 'pendiente', null, null, null, null),
      _doc('doc_004', 'sol_env_002', 'DNI', 'completo', null, 260, 0.92, null),
      _doc('doc_005', 'sol_env_002', 'RECIBO_SERVICIO', 'completo', null, 195, 0.90, null),
      _doc('doc_006', 'sol_env_002', 'TITULO_PROPIEDAD', 'completo', null, 520, 0.85, null),
      _doc('doc_007', 'sol_env_003', 'DNI', 'completo', null, 230, 0.91, null),
      _doc('doc_008', 'sol_env_003', 'RECIBO_SERVICIO', 'pendiente', null, null, null, null),
    ];

    final batch = db.batch();
    for (final r in rows) { batch.insert('solicitudes_documentos', r, conflictAlgorithm: ConflictAlgorithm.replace); }
    await batch.commit(noResult: true);
  }

  static Map<String, dynamic> _doc(
    String id, String solId, String tipo, String estado,
    String? url, int? kb, double? nitidez, String? localPath) {
    return {
      'id': id,
      'solicitud_id': solId,
      'tipo_documento': tipo,
      'estado': estado,
      'storage_url': url,
      'tamanio_kb': kb,
      'nitidez_score': nitidez,
      'local_path': localPath,
      'created_at': _ts(daysAgo: 10),
    };
  }

  // ─────── TRANSMISION ESTADO ───────
  static Future<void> _seedTransmisionEstado(Database db) async {
    final rows = [
      {
        'solicitud_id': 'sol_env_001',
        'paso_completado': 5,
        'documentos_subidos': '["DNI","RECIBO_SERVICIO","DECLARACION_IMPuestos"]',
        'expediente_generado': 'EXP-2026-001.pdf',
        'updated_at': _ts(daysAgo: 1),
      },
      {
        'solicitud_id': 'sol_env_002',
        'paso_completado': 3,
        'documentos_subidos': '["DNI","RECIBO_SERVICIO","TITULO_PROPIEDAD"]',
        'expediente_generado': null,
        'updated_at': _ts(daysAgo: 2),
      },
    ];

    final batch = db.batch();
    for (final r in rows) { batch.insert('transmision_estado', r, conflictAlgorithm: ConflictAlgorithm.replace); }
    await batch.commit(noResult: true);
  }

  // ─────── CARTERA VENCIDA ───────
  static Future<void> _seedCarteraVencida(Database db) async {
    final rows = [
      _moroso('mor_001', 'c_003', 'CR004', 'Rosa Mamani Condori', '34567890',
          '999000333', 'Calle Real 789, Huancayo', 85, 3200.0, 5000.0, _ts(daysAgo: 90), 4, 24),
      _moroso('mor_002', 'c_007', 'CR009', 'Ana Gutiérrez Paredes', '78901234',
          '999000777', 'Calle Los Pinos 147, Miraflores', 45, 1500.0, 2800.0, _ts(daysAgo: 50), 6, 12),
      _moroso('mor_003', 'c_009', 'CR013', 'Elena Vargas Ruiz', '90123456',
          '999000999', 'Jr. Amazonas 369, Magdalena', 60, 2500.0, 4200.0, _ts(daysAgo: 65), 8, 18),
      _moroso('mor_004', 'c_002', 'CR003', 'Juan Pérez García', '23456789',
          '999000222', 'Jr. Las Flores 456, Breña', 20, 800.0, 3000.0, _ts(daysAgo: 25), 10, 12),
    ];

    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final r in rows) {
      r['updated_at'] = now;
      batch.insert('cartera_vencida_cache', r, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Map<String, dynamic> _moroso(
    String id, String cid, String credId, String nom, String doc,
    String tel, String dir, int dias, double vencido, double saldo,
    String? ultContacto, int pagadas, int total) {
    return {
      'id': id,
      'cliente_id': cid,
      'credito_id': credId,
      'nombre_cliente': nom,
      'documento_cliente': doc,
      'telefono': tel,
      'direccion': dir,
      'dias_mora': dias,
      'monto_vencido': vencido,
      'saldo_actual': saldo,
      'ultimo_contacto': ultContacto,
      'cuotas_pagadas': pagadas,
      'total_cuotas': total,
    };
  }

  // ─────── ACCIONES COBRANZA ───────
  static Future<void> _seedAccionesCobranza(Database db) async {
    final rows = [
      _accion('ac_001', _asesorId, 'c_003', 'CR004',
          'visita_domiciliaria', 'sin_contacto', null, null, null,
          'Cliente no se encontraba en domicilio. Vecinos indican que viajó.',
          -12.0654, -77.0289, _ts(daysAgo: 3)),
      _accion('ac_002', _asesorId, 'c_007', 'CR009',
          'llamada_telefonica', 'compromiso_pago', null,
          _future(daysAhead: 5), 800.0,
          'Cliente se comprometió a pagar S/800 el día viernes.',
          -12.0912, -77.0489, _ts(daysAgo: 1)),
    ];

    final batch = db.batch();
    for (final r in rows) { batch.insert('acciones_cobranza_pendientes', r, conflictAlgorithm: ConflictAlgorithm.replace); }
    await batch.commit(noResult: true);
  }

  static Map<String, dynamic> _accion(
    String id, String aseId, String cid, String credId,
    String tipo, String res, double? montoPagado,
    String? fechaComp, double? montoComp, String? obs,
    double lat, double lng, String ts) {
    return {
      'id': id,
      'asesor_id': aseId,
      'cliente_id': cid,
      'credito_id': credId,
      'tipo_gestion': tipo,
      'resultado': res,
      'monto_pagado': montoPagado,
      'fecha_compromiso': fechaComp,
      'monto_compromiso': montoComp,
      'observaciones': obs,
      'lat': lat,
      'lng': lng,
      'timestamp_gestion': ts,
      'pendiente_sync': 1,
    };
  }
}
