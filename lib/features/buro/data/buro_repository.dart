import 'package:uuid/uuid.dart';
import '../../../core/network/network_monitor.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/local_cache.dart';
import '../domain/consulta_buro_model.dart';

class BuroRepository {
  final NetworkMonitor _network;
  final ApiClient _api;
  final LocalCache _cache;
  String? _asesorId;

  BuroRepository(this._network, this._api, this._cache);

  set asesorId(String id) => _asesorId = id;

  Future<ConsultaBuroModel?> consultarReciente(String clienteId) async {
    try {
      final data = await _api.get<Map<String, dynamic>?>(
        '/buro/consultas/reciente',
        params: {'cliente_id': clienteId},
      );
      if (data == null) return null;
      return ConsultaBuroModel.fromMap(data);
    } catch (_) {
      final cached =
          await _cache.getCached('buro_cache', _asesorId ?? clienteId);
      if (cached is Map<String, dynamic>) {
        return ConsultaBuroModel.fromMap(cached);
      }
      return null;
    }
  }

  Future<ConsultaBuroModel> consultar({
    required String asesorId,
    required String clienteId,
    required String dniCliente,
    required String firmaBase64,
    String? solicitudId,
  }) async {
    final connected = await _network.isConnected;

    if (connected) {
      try {
        final data = await _api.post<Map<String, dynamic>>(
          '/buro/consultar',
          data: {
            'asesor_id': asesorId,
            'cliente_id': clienteId,
            'dni': dniCliente,
            'firma_consentimiento': firmaBase64,
            'solicitud_id': solicitudId,
          },
        );
        final consulta = ConsultaBuroModel.fromMap(data);
        await _cache.cacheJson('buro_cache', clienteId, asesorId, data);
        return consulta;
      } catch (_) {}
    }

    final id = const Uuid().v4();
    final consulta = ConsultaBuroModel(
      id: id,
      asesorId: asesorId,
      clienteId: clienteId,
      dniConsultado: dniCliente,
      resultado: const ResultadoBuro(
        calificacionSbs: CalificacionSbs.normal,
        numEntidadesDeuda: 0,
        deudaTotal: 0,
        mayorDeuda: 0,
        diasMayorMora: 0,
      ),
      firmaConsentimientoBase64: firmaBase64,
      solicitudId: solicitudId,
      createdAt: DateTime.now(),
    );

    if (!connected) {
      await _cache.enqueueSync('buro', clienteId, 'INSERT', consulta.toMap());
    }
    return consulta;
  }

  Future<void> guardarReutilizacion(
      ConsultaBuroModel consultaOriginal) async {
    try {
      await _api.post('/buro/reutilizar', data: {
        'consulta_original_id': consultaOriginal.id,
        'asesor_id': consultaOriginal.asesorId,
        'cliente_id': consultaOriginal.clienteId,
      });
    } catch (_) {
      await _cache.enqueueSync('buro_reutilizar', consultaOriginal.id,
          'INSERT', consultaOriginal.toMap());
    }
  }
}
