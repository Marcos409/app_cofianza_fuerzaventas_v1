import 'dart:convert';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/cache/local_cache.dart';
import '../domain/prospeccion_models.dart';

class ProspeccionRepository {
  final NetworkMonitor _networkMonitor;
  final ApiClient _api;
  final LocalCache _cache;
  String? _asesorId;

  ProspeccionRepository(this._networkMonitor, this._api, this._cache);

  set asesorId(String id) => _asesorId = id;

  Future<ResultadoPreEvaluacion> preEvaluar(ProspectoModel prospecto) async {
    final isOnline = await _networkMonitor.isConnected;

    if (isOnline) {
      try {
        final data = await _api.post<Map<String, dynamic>>(
          '/pre-evaluar',
          data: prospecto.toMap(),
        );
        return ResultadoPreEvaluacion.fromJson(data);
      } catch (_) {}
    }

    await _guardarPendiente(prospecto);
    return const ResultadoPreEvaluacion(
      calificacion: ResultadoCalificacion.revisar,
      motivo: 'Sin conexión. Se procesará al reconectar.',
      pendienteSync: true,
    );
  }

  Future<List<CampanaActivaModel>> getCampanasActivas() async {
    final isOnline = await _networkMonitor.isConnected;

    if (isOnline) {
      try {
        final data = await _api.get<List>('/campanas');
        final campanas = data
            .map((j) =>
                CampanaActivaModel.fromJson(Map<String, dynamic>.from(j)))
            .toList();
        await _cache.cacheList('campanas_cache', _asesorId ?? '', data, 'id');
        return campanas;
      } catch (_) {}
    }

    final cached =
        await _cache.getCachedList('campanas_cache', _asesorId ?? '');
    if (cached.isEmpty) return [];
    return cached
        .map((j) => CampanaActivaModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<void> _guardarPendiente(ProspectoModel prospecto) async {
    await _cache.enqueueSync('pre_evaluacion', prospecto.documento, 'INSERT',
        prospecto.toMap());
  }

  Future<List<Map<String, dynamic>>> getPendientesSync() async {
    final pending = await _cache.getPendingSync();
    return pending
        .where((p) => p['entidad'] == 'pre_evaluacion')
        .map((p) => {
              'id': p['id']?.toString() ?? '',
              'datos_json': p['payload'],
              'pendiente_sync': 1,
              'created_at': p['created_at']?.toString() ?? '',
            })
        .toList();
  }

  Future<void> registrarDesercion({
    required String asesorId,
    required MotivoDesercion motivo,
    String? institucionMigro,
    ProbabilidadRetorno? probabilidadRetorno,
    String? observaciones,
  }) async {
    final data = {
      'asesor_id': asesorId,
      'motivo': motivo.name,
      'institucion_migro': institucionMigro,
      'probabilidad_retorno': probabilidadRetorno?.name,
      'observaciones': observaciones,
    };

    final isOnline = await _networkMonitor.isConnected;
    if (isOnline) {
      try {
        await _api.post('/deserciones', data: data);
        return;
      } catch (_) {}
    }
    await _cache.enqueueSync('desercion', asesorId, 'INSERT', data);
  }

  Future<void> marcarSincronizadas(List<String> ids) async {
    for (final id in ids) {
      final syncId = int.tryParse(id);
      if (syncId != null) {
        await _cache.markSynced(syncId);
      }
    }
  }
}
