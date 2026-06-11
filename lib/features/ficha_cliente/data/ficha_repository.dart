import 'package:sqflite/sqflite.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/storage/local_db.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../domain/ficha_models.dart';

class FichaRepository {
  final SupabaseService _supabase;
  final LocalDb _localDb;
  final NetworkMonitor _networkMonitor;

  FichaRepository(this._supabase, this._localDb, this._networkMonitor);

  Future<Database> get _database => _localDb.database;

  Future<FichaClienteModel> getCliente(String clienteId) async {
    final isOnline = await _networkMonitor.isConnected;

    if (isOnline) {
      try {
        final response = await _supabase.client
            .from('clientes')
            .select()
            .eq('id', clienteId)
            .single();

        final cliente = FichaClienteModel.fromJson(response);
        await _cacheCliente(cliente);
        return cliente;
      } catch (_) {
        return _getClienteLocal(clienteId);
      }
    }

    return _getClienteLocal(clienteId);
  }

  Future<PosicionCliente> getPosicionCliente(String clienteId) async {
    final isOnline = await _networkMonitor.isConnected;

    if (isOnline) {
      try {
        final response = await _supabase.client.functions
            .invoke('consulta-posicion', body: {'cliente_id': clienteId});
        final data = response.data;
        if (data is Map) {
          final posicion =
              PosicionCliente.fromJson(Map<String, dynamic>.from(data));
          await _cachePosicion(clienteId, posicion);
          return posicion;
        }
        return _getPosicionLocal(clienteId);
      } catch (_) {
        return _getPosicionLocal(clienteId);
      }
    }

    return _getPosicionLocal(clienteId);
  }

  Future<List<CreditoHistorico>> getHistorialCrediticio(
      String clienteId) async {
    final isOnline = await _networkMonitor.isConnected;

    if (isOnline) {
      try {
        final response = await _supabase.client
            .from('creditos')
            .select()
            .eq('cliente_id', clienteId)
            .order('fecha_apertura', ascending: false)
            .limit(5);

        final creditos = (response as List)
            .map((j) => CreditoHistorico.fromJson(Map<String, dynamic>.from(j)))
            .toList();

        await _cacheCreditos(clienteId, creditos);
        return creditos;
      } catch (_) {
        return _getCreditosLocal(clienteId);
      }
    }

    return _getCreditosLocal(clienteId);
  }

  Future<List<PagoMensual>> getComportamientoPagos(String clienteId) async {
    final isOnline = await _networkMonitor.isConnected;

    if (isOnline) {
      try {
        final hoy = DateTime.now();
        final doceMeses = DateTime(hoy.year - 1, hoy.month, 1);
        final response = await _supabase.client
            .from('pagos_mensuales')
            .select()
            .eq('cliente_id', clienteId)
            .gte('fecha_cuota', doceMeses.toIso8601String())
            .order('fecha_cuota', ascending: true);

        final pagos = (response as List)
            .map((j) => _parsePagoMensual(Map<String, dynamic>.from(j)))
            .toList();

        await _cachePagos(clienteId, pagos);
        return pagos;
      } catch (_) {
        return _getPagosLocal(clienteId);
      }
    }

    return _getPagosLocal(clienteId);
  }

  Future<OfertaPreaprobada?> getOfertaPreaprobada(String clienteId) async {
    final isOnline = await _networkMonitor.isConnected;

    if (isOnline) {
      try {
        final hoy = DateTime.now().toIso8601String().split('T').first;
        final response = await _supabase.client
            .from('creditos_preaprobados')
            .select()
            .eq('cliente_id', clienteId)
            .eq('vigente', true)
            .gte('fecha_vencimiento', hoy)
            .order('score_confianza', ascending: false)
            .limit(1);

        if (response.isNotEmpty) {
          final oferta = OfertaPreaprobada.fromJson(
              Map<String, dynamic>.from(response.first));
          await _cacheOferta(oferta);
          return oferta;
        }

        return null;
      } catch (_) {
        return _getOfertaLocal(clienteId);
      }
    }

    return _getOfertaLocal(clienteId);
  }

  Future<void> _cacheCliente(FichaClienteModel cliente) async {
    final db = await _database;
    await db.insert(
      'ficha_cache',
      {
        'cliente_id': cliente.id,
        'nombre': cliente.nombre,
        'documento': cliente.documento,
        'direccion': cliente.direccion,
        'telefono': cliente.telefono,
        'email': cliente.email,
        'tipo_negocio': cliente.tipoNegocio,
        'antiguedad_negocio': cliente.antiguedadNegocio,
        'lat': cliente.lat,
        'lng': cliente.lng,
        'calificacion_sbs': cliente.calificacionSbs.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<FichaClienteModel> _getClienteLocal(String clienteId) async {
    final db = await _database;
    final maps = await db.query(
      'ficha_cache',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      limit: 1,
    );

    if (maps.isEmpty) throw Exception('Cliente no encontrado en caché');

    final m = maps.first;
    return FichaClienteModel(
      id: m['cliente_id']?.toString() ?? '',
      nombre: m['nombre']?.toString() ?? '',
      documento: m['documento']?.toString() ?? '',
      direccion: m['direccion']?.toString() ?? '',
      telefono: m['telefono']?.toString(),
      email: m['email']?.toString(),
      tipoNegocio: m['tipo_negocio']?.toString(),
      antiguedadNegocio: (m['antiguedad_negocio'] as num?)?.toInt(),
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      calificacionSbs: CalificacionSbs.fromString(
          m['calificacion_sbs']?.toString() ?? ''),
    );
  }

  Future<void> _cacheCreditos(
      String clienteId, List<CreditoHistorico> creditos) async {
    final db = await _database;
    await db.delete('creditos_cache',
        where: 'cliente_id = ?', whereArgs: [clienteId]);

    final batch = db.batch();
    for (final c in creditos) {
      batch.insert('creditos_cache', {
        'cliente_id': clienteId,
        'credito_id': c.id,
        'monto': c.monto,
        'plazo_meses': c.plazoMeses,
        'tea': c.tea,
        'estado': c.estado,
        'porcentaje_puntual': c.porcentajePuntual,
        'fecha_apertura': c.fechaApertura?.toIso8601String(),
        'fecha_cierre': c.fechaCierre?.toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<CreditoHistorico>> _getCreditosLocal(String clienteId) async {
    final db = await _database;
    final maps = await db.query(
      'creditos_cache',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'fecha_apertura DESC',
      limit: 5,
    );

    return maps.map((m) => CreditoHistorico(
          id: m['credito_id']?.toString() ?? '',
          monto: (m['monto'] as num?)?.toDouble() ?? 0,
          plazoMeses: (m['plazo_meses'] as num?)?.toInt() ?? 0,
          tea: (m['tea'] as num?)?.toDouble() ?? 0,
          estado: m['estado']?.toString() ?? '',
          porcentajePuntual: (m['porcentaje_puntual'] as num?)?.toDouble() ?? 100,
          fechaApertura: m['fecha_apertura'] != null
              ? DateTime.tryParse(m['fecha_apertura'].toString())
              : null,
          fechaCierre: m['fecha_cierre'] != null
              ? DateTime.tryParse(m['fecha_cierre'].toString())
              : null,
        )).toList();
  }

  Future<void> _cachePagos(
      String clienteId, List<PagoMensual> pagos) async {
    final db = await _database;
    await db.delete('pagos_cache',
        where: 'cliente_id = ?', whereArgs: [clienteId]);

    final batch = db.batch();
    for (final p in pagos) {
      batch.insert('pagos_cache', {
        'cliente_id': clienteId,
        'mes': p.mes,
        'anio': p.anio,
        'monto_pagado': p.montoPagado,
        'status': p.status.name,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<PagoMensual>> _getPagosLocal(String clienteId) async {
    final db = await _database;
    final maps = await db.query(
      'pagos_cache',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'anio ASC, mes ASC',
    );

    return maps.map((m) => PagoMensual(
          mes: (m['mes'] as num?)?.toInt() ?? 1,
          anio: (m['anio'] as num?)?.toInt() ?? DateTime.now().year,
          montoPagado: (m['monto_pagado'] as num?)?.toDouble() ?? 0,
          status: StatusPago.values.firstWhere(
            (s) => s.name == m['status'],
            orElse: () => StatusPago.sinCuota,
          ),
        )).toList();
  }

  Future<void> _cacheOferta(OfertaPreaprobada oferta) async {
    final db = await _database;
    await db.insert(
      'ofertas_cache',
      {
        'cliente_id': oferta.clienteId,
        'oferta_id': oferta.id,
        'monto_maximo': oferta.montoMaximo,
        'plazo_sugerido_meses': oferta.plazoSugeridoMeses,
        'tea_referencial': oferta.teaReferencial,
        'score_confianza': oferta.scoreConfianza,
        'vigente': oferta.vigente ? 1 : 0,
        'fecha_vencimiento': oferta.fechaVencimiento.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<OfertaPreaprobada?> _getOfertaLocal(String clienteId) async {
    final db = await _database;
    final maps = await db.query(
      'ofertas_cache',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final m = maps.first;
    return OfertaPreaprobada(
      id: m['oferta_id']?.toString() ?? '',
      clienteId: m['cliente_id']?.toString() ?? '',
      montoMaximo: (m['monto_maximo'] as num?)?.toDouble() ?? 0,
      plazoSugeridoMeses:
          (m['plazo_sugerido_meses'] as num?)?.toInt() ?? 0,
      teaReferencial: (m['tea_referencial'] as num?)?.toDouble() ?? 0,
      scoreConfianza: (m['score_confianza'] as num?)?.toInt() ?? 0,
      vigente: (m['vigente'] as num?)?.toInt() == 1,
      fechaVencimiento: DateTime.tryParse(
              m['fecha_vencimiento']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Future<void> actualizarUbicacion(
      String clienteId, double lat, double lng) async {
    final isOnline = await _networkMonitor.isConnected;
    if (isOnline) {
      try {
        await _supabase.client
            .from('clientes')
            .update({'lat': lat, 'lng': lng}).eq('id', clienteId);
      } catch (_) {}
    }
    final db = await _database;
    await db.update(
      'ficha_cache',
      {'lat': lat, 'lng': lng, 'updated_at': DateTime.now().toIso8601String()},
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
    );
  }

  PagoMensual _parsePagoMensual(Map<String, dynamic> json) {
    return PagoMensual(
      mes: (json['mes'] as num?)?.toInt() ?? 1,
      anio: (json['anio'] as num?)?.toInt() ?? DateTime.now().year,
      montoPagado: (json['monto_pagado'] as num?)?.toDouble() ?? 0,
      status: _parseStatus(json['status']?.toString() ?? ''),
    );
  }

  StatusPago _parseStatus(String value) {
    switch (value.toUpperCase()) {
      case 'PUNTUAL':
        return StatusPago.puntual;
      case 'MORA':
        return StatusPago.mora;
      default:
        return StatusPago.sinCuota;
    }
  }

  Future<void> _cachePosicion(String clienteId, PosicionCliente posicion) async {
    final db = await _database;
    await db.insert(
      'posicion_cache',
      {
        'cliente_id': clienteId,
        'deuda_total': posicion.deudaTotal,
        'cuentas_vigentes': posicion.cuentasVigentes,
        'cuentas_mora': posicion.cuentasMora,
        'dias_mayor_mora': posicion.diasMayorMora,
        'ultimo_pago': posicion.ultimoPago?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PosicionCliente> _getPosicionLocal(String clienteId) async {
    final db = await _database;
    final maps = await db.query(
      'posicion_cache',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      limit: 1,
    );

    if (maps.isEmpty) return const PosicionCliente();

    final m = maps.first;
    return PosicionCliente(
      deudaTotal: (m['deuda_total'] as num?)?.toDouble() ?? 0,
      cuentasVigentes: (m['cuentas_vigentes'] as num?)?.toInt() ?? 0,
      cuentasMora: (m['cuentas_mora'] as num?)?.toInt() ?? 0,
      diasMayorMora: (m['dias_mayor_mora'] as num?)?.toInt() ?? 0,
      ultimoPago: m['ultimo_pago'] != null
          ? DateTime.tryParse(m['ultimo_pago'].toString())
          : null,
    );
  }

  Future<String> getEstadoVisitaLocal(String clienteId) async {
    final db = await _database;
    final maps = await db.query(
      'cartera',
      columns: ['estado_visita'],
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      limit: 1,
    );
    if (maps.isEmpty) return 'pendiente';
    return maps.first['estado_visita']?.toString() ?? 'pendiente';
  }

  Future<void> registrarVisita({
    required String clienteId,
    required String estado,
    String? observacion,
    double? lat,
    double? lng,
  }) async {
    final db = await _database;
    final timestamp = DateTime.now().toIso8601String();

    await db.update(
      'cartera',
      {
        'estado_visita': estado,
        'resultado_visita': estado.toUpperCase(),
        'observacion_visita': observacion,
        'timestamp_visita': timestamp,
        'lat_visita': lat,
        'lng_visita': lng,
        'pendiente_sync': 1,
      },
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
    );

    final maps = await db.query(
      'cartera',
      columns: ['id'],
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      limit: 1,
    );
    final carteroId = maps.isNotEmpty ? maps.first['id'] as String : clienteId;

    await db.insert('visitas_pendientes', {
      'id': '${carteroId}_${DateTime.now().millisecondsSinceEpoch}',
      'cartero_id': carteroId,
      'resultado': estado,
      'observacion': observacion,
      'timestamp_visita': timestamp,
      'lat': lat,
      'lng': lng,
      'pendiente_sync': 1,
    });

    final isOnline = await _networkMonitor.isConnected;
    if (isOnline) {
      try {
        await _supabase.client
            .from('cartera_diaria')
            .update({
              'estado_visita': estado,
              'resultado_visita': estado.toUpperCase(),
              'observacion_visita': observacion,
              'timestamp_visita': timestamp,
              'lat_visita': lat,
              'lng_visita': lng,
            })
            .eq('id', carteroId);

        await db.update(
          'visitas_pendientes',
          {'pendiente_sync': 0},
          where: 'cartero_id = ?',
          whereArgs: [carteroId],
        );
        await db.update(
          'cartera',
          {'pendiente_sync': 0},
          where: 'id = ?',
          whereArgs: [carteroId],
        );
      } catch (_) {}
    }
  }
}
