import '../../../../core/network/network_monitor.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/cache/local_cache.dart';
import '../domain/ficha_models.dart';

class FichaRepository {
  final NetworkMonitor _networkMonitor;
  final ApiClient _api;
  final LocalCache _cache;
  String? _asesorId;

  FichaRepository(this._networkMonitor, this._api, this._cache);

  set asesorId(String id) => _asesorId = id;

  Future<FichaClienteModel> getCliente(String clienteId) async {
    final isOnline = await _networkMonitor.isConnected;
    if (isOnline) {
      try {
        final data = await _api.get<Map<String, dynamic>>(
          '/clientes/$clienteId/ficha',
        );
        final cliente = FichaClienteModel.fromJson(data);
        await _cache.cacheJson('ficha_cache', clienteId, _asesorId ?? '', data);
        return cliente;
      } catch (_) {}
    }
    final cached = await _cache.getCached('ficha_cache', clienteId);
    if (cached == null) throw Exception('Cliente no encontrado en caché');
    return FichaClienteModel.fromJson(Map<String, dynamic>.from(cached));
  }

  Future<PosicionCliente> getPosicionCliente(String clienteId) async {
    final cached = await _cache.getCached('ficha_cache', clienteId);
    if (cached is Map<String, dynamic> && cached.containsKey('posicion')) {
      return PosicionCliente.fromJson(
          Map<String, dynamic>.from(cached['posicion']));
    }
    return const PosicionCliente();
  }

  Future<List<CreditoHistorico>> getHistorialCrediticio(
      String clienteId) async {
    final isOnline = await _networkMonitor.isConnected;
    if (isOnline) {
      try {
        final data = await _api.get<List>('/clientes/$clienteId/pagos');
        final creditos = data
            .map((j) =>
                CreditoHistorico.fromJson(Map<String, dynamic>.from(j)))
            .toList();
        await _cache.cacheList('creditos_cache', _asesorId ?? '', data, 'id');
        return creditos;
      } catch (_) {}
    }
    final cached =
        await _cache.getCachedList('creditos_cache', _asesorId ?? '');
    if (cached.isEmpty) return [];
    return cached
        .map((j) => CreditoHistorico.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<List<PagoMensual>> getComportamientoPagos(String clienteId) async {
    final isOnline = await _networkMonitor.isConnected;
    if (isOnline) {
      try {
        final data = await _api.get<List>('/clientes/$clienteId/pagos');
        final pagos = data
            .map((j) => _parsePagoMensual(Map<String, dynamic>.from(j)))
            .toList();
        await _cache.cacheList('pagos_cache', _asesorId ?? '', data, 'id');
        return pagos;
      } catch (_) {}
    }
    final cached = await _cache.getCachedList('pagos_cache', _asesorId ?? '');
    if (cached.isEmpty) return [];
    return cached
        .map((j) => _parsePagoMensual(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<OfertaPreaprobada?> getOfertaPreaprobada(String clienteId) async {
    final cached = await _cache.getCached('ficha_cache', clienteId);
    if (cached is Map<String, dynamic> && cached.containsKey('oferta')) {
      return OfertaPreaprobada.fromJson(
          Map<String, dynamic>.from(cached['oferta']));
    }
    return null;
  }

  Future<void> actualizarUbicacion(
    String clienteId,
    double lat,
    double lng,
    String direccion,
  ) async {
    final isOnline = await _networkMonitor.isConnected;
    if (isOnline) {
      try {
        await _api.post('/clientes/$clienteId/ubicacion', data: {
          'lat': lat,
          'lng': lng,
          'direccion': direccion,
        });
        return;
      } catch (_) {}
    }
    await _cache.enqueueSync('ubicacion', clienteId, 'UPDATE', {
      'lat': lat,
      'lng': lng,
      'direccion': direccion,
    });
  }

  Future<String> getEstadoVisitaLocal(String clienteId) async {
    final cached = await _cache.getCached('cartera_cache', clienteId);
    if (cached is Map<String, dynamic>) {
      return cached['estado_visita']?.toString() ?? 'pendiente';
    }
    return 'pendiente';
  }

  Future<void> registrarVisita({
    required String clienteId,
    required String estado,
    String? observacion,
    double? lat,
    double? lng,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final data = {
      'cliente_id': clienteId,
      'estado': estado,
      'resultado': estado.toUpperCase(),
      'observacion': observacion,
      'timestamp_visita': timestamp,
      'lat': lat,
      'lng': lng,
    };

    final isOnline = await _networkMonitor.isConnected;
    if (isOnline) {
      try {
        await _api.post('/visitas', data: data);
        return;
      } catch (_) {}
    }
    await _cache.enqueueSync('visita', clienteId, 'INSERT', data);
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
}
