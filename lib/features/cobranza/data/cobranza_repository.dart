import 'dart:async';
import '../../../core/network/network_monitor.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/local_cache.dart';
import '../domain/cliente_mora.dart';
import '../domain/accion_cobranza.dart';

class CobranzaRepository {
  final NetworkMonitor _networkMonitor;
  final ApiClient _api;
  final LocalCache _cache;
  StreamSubscription<bool>? _connectivitySub;
  bool _online = true;
  String? _asesorId;

  CobranzaRepository(this._networkMonitor, this._api, this._cache) {
    _init();
  }

  set asesorId(String id) => _asesorId = id;

  Future<void> _init() async {
    _online = await _networkMonitor.isConnected;
    _connectivitySub = _networkMonitor.connectivityStream.listen((online) {
      _online = online;
    });
  }

  Future<List<ClienteMora>> getMorosos() async {
    if (_online) {
      try {
        final data = await _api.get<List>('/cobranza/mora');
        final morosos = data
            .map((m) => ClienteMora.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        await _cache.cacheList('mora_cache', _asesorId ?? '', data, 'id');
        return morosos;
      } catch (_) {}
    }
    final cached = await _cache.getCachedList('mora_cache', _asesorId ?? '');
    if (cached.isEmpty) return [];
    return cached
        .map((m) => ClienteMora.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> registrarAccion(AccionCobranza accion) async {
    if (_online) {
      try {
        await _api.post('/cobranza/accion', data: accion.toMap());
        return;
      } catch (_) {}
    }
    await _cache.enqueueSync('accion_cobranza', accion.id, 'INSERT',
        accion.toMap());
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
