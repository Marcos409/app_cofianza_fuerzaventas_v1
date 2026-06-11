import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/storage/local_db.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../domain/prospeccion_models.dart';

class ProspeccionRepository {
  final SupabaseService _supabase;
  final LocalDb _localDb;
  final NetworkMonitor _networkMonitor;

  ProspeccionRepository(this._supabase, this._localDb, this._networkMonitor);

  Future<Database> get _database => _localDb.database;

  Future<ResultadoPreEvaluacion> preEvaluar(ProspectoModel prospecto) async {
    final isOnline = await _networkMonitor.isConnected;

    if (!isOnline) {
      await _guardarPendiente(prospecto);
      return const ResultadoPreEvaluacion(
        calificacion: ResultadoCalificacion.revisar,
        motivo: 'Sin conexión. Se procesará al reconectar.',
        pendienteSync: true,
      );
    }

    try {
      final response = await _supabase.client.functions
          .invoke('pre-evaluar', body: prospecto.toMap());
      final data = response.data;
      if (data is Map) {
        return ResultadoPreEvaluacion.fromJson(Map<String, dynamic>.from(data));
      }
      return const ResultadoPreEvaluacion(
        calificacion: ResultadoCalificacion.revisar,
        motivo: 'Error al procesar la pre-evaluación',
      );
    } catch (_) {
      await _guardarPendiente(prospecto);
      return const ResultadoPreEvaluacion(
        calificacion: ResultadoCalificacion.revisar,
        motivo: 'Error de conexión. Se procesará al reconectar.',
        pendienteSync: true,
      );
    }
  }

  Future<List<CampanaActivaModel>> getCampanasActivas() async {
    final isOnline = await _networkMonitor.isConnected;

    if (isOnline) {
      try {
        final asesorId = _supabase.auth.currentUser?.id;
        if (asesorId == null) return [];

        final hoy = DateTime.now().toIso8601String().split('T').first;
        final response = await _supabase.client
            .from('campanas_activas')
            .select()
            .eq('asesor_id', asesorId)
            .eq('activa', true)
            .gte('fecha_vencimiento', hoy)
            .order('fecha_vencimiento', ascending: true);

        final campanas = (response as List)
            .map((j) =>
                CampanaActivaModel.fromJson(Map<String, dynamic>.from(j)))
            .toList();

        await _cacheCampanas(campanas);
        return campanas;
      } catch (_) {
        return _getCampanasLocal();
      }
    }

    return _getCampanasLocal();
  }

  Future<void> _guardarPendiente(ProspectoModel prospecto) async {
    final db = await _database;
    await db.insert('pre_evaluaciones_pendientes', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'asesor_id': prospecto.asesorId,
      'datos_json': jsonEncode(prospecto.toMap()),
      'pendiente_sync': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _cacheCampanas(List<CampanaActivaModel> campanas) async {
    final db = await _database;
    await db.delete('campanas_cache');

    final batch = db.batch();
    for (final c in campanas) {
      batch.insert('campanas_cache', {
        'id': c.id,
        'cliente_id': c.clienteId,
        'nombre_cliente': c.nombreCliente,
        'tipo': c.tipo.name,
        'monto_ofertado': c.montoOfertado,
        'fecha_vencimiento': c.fechaVencimiento.toIso8601String(),
        'activa': c.activa ? 1 : 0,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<CampanaActivaModel>> _getCampanasLocal() async {
    final db = await _database;
    final maps = await db.query(
      'campanas_cache',
      orderBy: 'fecha_vencimiento ASC',
    );

    return maps.map((m) => CampanaActivaModel(
      id: m['id']?.toString() ?? '',
      clienteId: m['cliente_id']?.toString() ?? '',
      nombreCliente: m['nombre_cliente']?.toString() ?? '',
      tipo: TipoCampana.values.firstWhere(
        (t) => t.name == m['tipo'],
        orElse: () => TipoCampana.renovacion,
      ),
      montoOfertado: (m['monto_ofertado'] as num?)?.toDouble() ?? 0,
      fechaVencimiento:
          DateTime.tryParse(m['fecha_vencimiento']?.toString() ?? '') ??
              DateTime.now(),
      activa: (m['activa'] as num?)?.toInt() == 1,
    )).toList();
  }

  Future<List<Map<String, dynamic>>> getPendientesSync() async {
    final db = await _database;
    return db.query(
      'pre_evaluaciones_pendientes',
      where: 'pendiente_sync = 1',
    );
  }

  Future<void> registrarDesercion({
    required String asesorId,
    required MotivoDesercion motivo,
    String? institucionMigro,
    ProbabilidadRetorno? probabilidadRetorno,
    String? observaciones,
  }) async {
    final isOnline = await _networkMonitor.isConnected;

    final data = {
      'asesor_id': asesorId,
      'motivo': motivo.name,
      'institucion_migro': institucionMigro,
      'probabilidad_retorno': probabilidadRetorno?.name,
      'observaciones': observaciones,
    };

    if (isOnline) {
      try {
        await _supabase.client.from('deserciones').insert(data);
        return;
      } catch (_) {}
    }

    final db = await _database;
    await db.insert('deserciones_pendientes', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'datos_json': jsonEncode(data),
      'pendiente_sync': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> marcarSincronizadas(List<String> ids) async {
    final db = await _database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(
        'pre_evaluaciones_pendientes',
        {'pendiente_sync': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }
}
